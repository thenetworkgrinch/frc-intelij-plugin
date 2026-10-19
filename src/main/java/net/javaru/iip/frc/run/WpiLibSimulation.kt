/*
 * Copyright 2015-2026 the original author or authors.
 *
 *     Licensed under the Apache License, Version 2.0 (the "License");
 *     you may not use this file except in compliance with the License.
 *     You may obtain a copy of the License at
 *
 *       https://www.apache.org/licenses/LICENSE-2.0
 *
 *     Unless required by applicable law or agreed to in writing, software
 *     distributed under the License is distributed on an "AS IS" BASIS,
 *     WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *     See the License for the specific language governing permissions and
 *     limitations under the License.
 */

package net.javaru.iip.frc.run

import com.beust.klaxon.JsonArray
import com.beust.klaxon.JsonObject
import com.beust.klaxon.Parser
import com.intellij.application.options.ModulesComboBox
import com.intellij.compiler.options.CompileStepBeforeRun
import com.intellij.execution.BeforeRunTask
import com.intellij.execution.BeforeRunTaskProvider
import com.intellij.execution.CommonJavaRunConfigurationParameters
import com.intellij.execution.ExecutionException
import com.intellij.execution.Executor
import com.intellij.execution.JavaRunConfigurationExtensionManager
import com.intellij.execution.RunManager
import com.intellij.execution.application.ApplicationConfiguration
import com.intellij.execution.configurations.ConfigurationFactory
import com.intellij.execution.configurations.ConfigurationTypeBase
import com.intellij.execution.configurations.GeneralCommandLine
import com.intellij.execution.configurations.JavaCommandLineState
import com.intellij.execution.configurations.JavaParameters
import com.intellij.execution.configurations.JavaRunConfigurationModule
import com.intellij.execution.configurations.ModuleBasedConfiguration
import com.intellij.execution.configurations.ModuleBasedConfigurationOptions
import com.intellij.execution.configurations.RunConfiguration
import com.intellij.execution.configurations.RunProfileState
import com.intellij.execution.configurations.RuntimeConfigurationError
import com.intellij.execution.executors.DefaultDebugExecutor
import com.intellij.execution.executors.DefaultRunExecutor
import com.intellij.execution.process.CapturingProcessHandler
import com.intellij.execution.process.OSProcessHandler
import com.intellij.execution.process.ProcessEvent
import com.intellij.execution.process.ProcessListener
import com.intellij.execution.runners.ExecutionEnvironment
import com.intellij.openapi.actionSystem.DataContext
import com.intellij.openapi.application.ApplicationManager
import com.intellij.openapi.application.ModalityState
import com.intellij.openapi.diagnostic.logger
import com.intellij.openapi.externalSystem.model.execution.ExternalSystemTaskExecutionSettings
import com.intellij.openapi.externalSystem.service.execution.ProgressExecutionMode
import com.intellij.openapi.externalSystem.util.ExternalSystemUtil
import com.intellij.openapi.fileEditor.FileEditorManager
import com.intellij.openapi.fileTypes.PlainTextFileType
import com.intellij.openapi.module.Module
import com.intellij.openapi.module.ModuleManager
import com.intellij.openapi.options.SettingsEditor
import com.intellij.openapi.options.SettingsEditorGroup
import com.intellij.openapi.progress.ProgressIndicator
import com.intellij.openapi.progress.ProgressManager
import com.intellij.openapi.project.Project
import com.intellij.openapi.project.guessProjectDir
import com.intellij.openapi.projectRoots.JavaSdk
import com.intellij.openapi.util.Key
import com.intellij.openapi.util.NotNullLazyValue
import com.intellij.openapi.util.SystemInfo
import com.intellij.openapi.util.io.FileUtil
import com.intellij.testFramework.LightVirtualFile
import com.intellij.ui.RawCommandLineEditor
import com.intellij.util.execution.ParametersListUtil
import com.intellij.util.ui.FormBuilder
import icons.FrcIcons
import net.javaru.iip.frc.notify.FrcNotifyType
import net.javaru.iip.frc.util.getMainModule
import net.javaru.iip.frc.wpilib.extractProjectYear
import net.javaru.iip.frc.wpilib.findWpiLibProjectRootDirs
import net.javaru.iip.frc.wpilib.getConfiguredProjectYear
import net.javaru.iip.frc.wpilib.getDefaultWpiLibRootPath
import org.jdom.Element
import org.jetbrains.plugins.gradle.settings.GradleSettings
import org.jetbrains.plugins.gradle.util.GradleConstants
import java.io.File
import java.nio.file.Files
import java.nio.file.Path
import java.time.Year
import javax.swing.Icon
import javax.swing.JCheckBox
import javax.swing.JComponent

private object WpiLibSimulation
private val logger = logger<WpiLibSimulation>()

// Simulation always builds the robot code first (the simulateExternalJava Gradle task compiles it), which the names make clear
const val simulateRobotCodeRunConfigName = "Build & Simulate Robot Code"
const val simulateRobotCodeHwSimRunConfigName = "Build & Simulate Robot Code (Hardware Sim)"
const val cleanBuildAndSimulateRobotCodeRunConfigName = "Clean Build & Simulate Robot Code"

/** Names used by earlier versions of the plugin, mapped to the current names, so existing configurations are renamed. */
private val legacySimulationRunConfigNames = mapOf(
    "Simulate Robot Code" to simulateRobotCodeRunConfigName,
    "Simulate Robot Code (Hardware Sim)" to simulateRobotCodeHwSimRunConfigName,
                                                  )

private const val simulateExternalJavaGradleTask = "simulateExternalJava"
private const val hwSimArgument = "-PhwSim"
private const val halSimExtensionsEnvVar = "HALSIM_EXTENSIONS"

// region Simulation Gradle task

/** The first WPILib year whose simulation is launched by the plugin, using the details generated by GradleRIO's `simulateExternalJava` task. */
private const val simulateExternalJavaFirstYear = 2027

/** The file (in `build`), generated by the `simulateExternalJava` task, with the simulation launch details. */
private const val simConfigFileName = "sim/java.json"

/**
 * Whether the simulation, for the project year, is run by GradleRIO's `simulateJava` (or `simulateJavaDebug`) Gradle task, which
 * is the case for 2026 and earlier. For 2027+, the plugin launches the simulation using the details generated by the
 * `simulateExternalJava` task, so it can also be run with coverage or profiled.
 */
fun isSimulatedByGradleTask(projectYear: String?): Boolean = (extractProjectYear(projectYear) ?: Year.now().value) < simulateExternalJavaFirstYear

/** The GradleRIO task (2026 and earlier) that builds and runs the simulation: `simulateJavaDebug` when debugging, otherwise `simulateJava`. */
fun simulateJavaGradleTask(debug: Boolean): String = if (debug) "simulateJavaDebug" else "simulateJava"

// endregion

// region VM options

private const val libraryPathVmOption = "-Djava.library.path="
private const val addOpensVmOption = "--add-opens"

/**
 * The JVM options GradleRIO uses when running a Java simulation (see its `WPIJavaExtension`). They are required, for
 * example, by Commands v3, which fails to start without access to `jdk.internal.vm`.
 */
private val gradleRioSimulationVmOptions: List<String> = listOf(
    addOpensVmOption, "java.base/jdk.internal.vm=ALL-UNNAMED",
    addOpensVmOption, "java.base/java.lang=ALL-UNNAMED",
    "--enable-native-access=ALL-UNNAMED",
                                                               ) + if (SystemInfo.isMac) listOf("-XstartOnFirstThread") else emptyList()

/**
 * Returns the VM options for the simulation: the user's options, with the simulation options appended. Any simulation
 * options already in the user's options are removed so they are not duplicated.
 */
fun simulationVmOptions(existingOptions: List<String>, libraryDir: String?): List<String>
{
    val managedAddOpensValues = gradleRioSimulationVmOptions.zipWithNext().filter { it.first == addOpensVmOption }.map { it.second }.toSet()
    val userOptions = mutableListOf<String>()
    var index = 0
    while (index < existingOptions.size)
    {
        val option = existingOptions[index]
        when
        {
            option == addOpensVmOption && existingOptions.getOrNull(index + 1) in managedAddOpensValues -> index++ // also skip its value
            // (a user's own '--add-opens' flag, for a value not managed by the plugin, is kept)
            option.startsWith(libraryPathVmOption) || (option != addOpensVmOption && option in gradleRioSimulationVmOptions) -> {}
            else -> userOptions.add(option)
        }
        index++
    }
    return userOptions + gradleRioSimulationVmOptions + listOfNotNull(libraryDir?.let { "$libraryPathVmOption$it" })
}

// endregion

// region Run configuration creation

/**
 * Creates the simulation run configurations (simulate, simulate with hardware simulation, and clean build & simulate) if they
 * do not already exist. They are only created once the project's main module exists (i.e. after the Gradle import).
 *
 * They are Gradle run configurations, like the plugin's other run configurations, each with its own fixed tasks and arguments:
 * GradleRIO's `run` task (2027+) or `simulateJava` task (2026 and earlier), with `-PhwSim` only for the hardware simulation one.
 * Earlier versions of the plugin created [WpiLibSimulationRunConfiguration]s, which are replaced.
 */
fun ensureWpiLibSimulationRunConfigurations(project: Project)
{
    if (project.isDisposed || project.getMainModule() == null) return
    renameLegacySimulationRunConfigurations(project)
    val simulateTask = simulationGradleTask(project.getConfiguredProjectYear())
    createSimulationRunConfiguration(project, simulateRobotCodeRunConfigName, listOf(simulateTask), hwSim = false)
    createSimulationRunConfiguration(project, simulateRobotCodeHwSimRunConfigName, listOf(simulateTask), hwSim = true)
    createSimulationRunConfiguration(project, cleanBuildAndSimulateRobotCodeRunConfigName, listOf("clean", simulateTask), hwSim = false)
    repairSimulationRunConfigurationModules(project)
    removeBuildBeforeLaunchTasks(project)
}

/**
 * The GradleRIO task that builds and runs the simulation: `run` for 2027+ (the task GradleRIO's `simulateExternalJava` names in
 * `build/sim/java.json`), `simulateJava` for 2026 and earlier.
 */
fun simulationGradleTask(projectYear: String?): String = if (isSimulatedByGradleTask(projectYear)) simulateJavaGradleTask(debug = false) else "run"

/**
 * Removes the IDE's 'Build' before launch task, which earlier versions of the plugin added (by default) to the simulation run
 * configurations. See [WpiLibSimulationRunConfiguration.isBuildBeforeLaunchAddedByDefault].
 */
private fun removeBuildBeforeLaunchTasks(project: Project)
{
    RunManager.getInstance(project).getConfigurationsList(WpiLibSimulationConfigurationType.getInstance())
        .filterIsInstance<WpiLibSimulationRunConfiguration>()
        .filter { configuration -> configuration.beforeRunTasks.any { it.providerId == CompileStepBeforeRun.ID } }
        .forEach { configuration ->
            configuration.beforeRunTasks = configuration.beforeRunTasks.filterNot { it.providerId == CompileStepBeforeRun.ID }
            logger.info("[FRC] Removed the 'Build' before launch task from the '${configuration.name}' run configuration for project '${project.name}'")
        }
}

/**
 * Sets the main module on any simulation run configuration whose module is not set or no longer exists. This happens when the
 * project was copied or renamed, or the Gradle root project name changed, since the configuration stores the old module name.
 * It is also set when the module is the main module of the `buildSrc` or a subproject (e.g. `projectName.buildSrc.main`),
 * which earlier versions of the plugin could select, as the simulation is of the root project's robot code.
 */
private fun repairSimulationRunConfigurationModules(project: Project)
{
    val mainModule = project.getMainModule() ?: return
    RunManager.getInstance(project).getConfigurationsList(WpiLibSimulationConfigurationType.getInstance())
        .filterIsInstance<WpiLibSimulationRunConfiguration>()
        .filter { it.configurationModule.module.let { module -> module == null || (module != mainModule && module.name.endsWith(".main")) } }
        .forEach {
            it.setModule(mainModule)
            logger.info("[FRC] Set the module of the '${it.name}' run configuration to '${mainModule.name}' for project '${project.name}'")
        }
}

private fun renameLegacySimulationRunConfigurations(project: Project)
{
    val runManager = RunManager.getInstance(project)
    legacySimulationRunConfigNames.forEach { (legacyName, currentName) ->
        val legacy = runManager.findConfigurationByName(legacyName) ?: return@forEach
        if (legacy.configuration is WpiLibSimulationRunConfiguration && runManager.findConfigurationByName(currentName) == null)
        {
            legacy.name = currentName
            logger.info("[FRC] Renamed the '$legacyName' run configuration to '$currentName' for project '${project.name}'")
        }
    }
}

private fun createSimulationRunConfiguration(project: Project, name: String, gradleTasks: List<String>, hwSim: Boolean)
{
    try
    {
        val runManager = RunManager.getInstance(project)
        val existing = runManager.findConfigurationByName(name)
        var wasSelected = false
        if (existing != null)
        {
            // Earlier versions of the plugin created these as Application configurations, which do not work since IDEA delegates
            // running them to Gradle, and then as WPILib Simulation configurations. Both are replaced; any other configuration
            // with the name, such as the Gradle configuration created here, is left alone.
            if (existing.configuration !is WpiLibSimulationRunConfiguration && existing.configuration !is ApplicationConfiguration) return
            wasSelected = runManager.selectedConfiguration == existing
            runManager.removeConfiguration(existing)
            logger.info("[FRC] Replacing the '$name' ${existing.type.displayName} run configuration with a Gradle configuration for project '${project.name}'")
        }
        createGradleRunConfiguration(project, name, gradleTasks, setAsSelected = wasSelected, setAsShared = false,
                                     arguments = if (hwSim) hwSimArgument else null)
        logger.info("[FRC] Created '$name' run configuration (Gradle: ${gradleTasks.joinToString(" ")}${if (hwSim) " $hwSimArgument" else ""}) for project '${project.name}'")
    }
    catch (e: Exception)
    {
        logger.warn("[FRC] Could not create '$name' Run Configuration for project '${project.name}' due to an exception: $e", e)
    }
}

internal fun Project.wpiLibProjectRoot(): Path? = (findWpiLibProjectRootDirs().firstOrNull() ?: guessProjectDir())?.toNioPath()

// endregion

// region Run configuration type

class WpiLibSimulationConfigurationType : ConfigurationTypeBase(
    ID, "WPILib Simulation", "Runs the robot program in the WPILib simulator",
    NotNullLazyValue.createValue { FrcIcons.FRC.FIRST_ICON_MEDIUM_16 })
{
    init
    {
        addFactory(object : ConfigurationFactory(this)
                   {
                       override fun getId(): String = ID
                       override fun createTemplateConfiguration(project: Project): RunConfiguration = WpiLibSimulationRunConfiguration(project, this, "WPILib Simulation")
                       override fun getOptionsClass(): Class<WpiLibSimulationOptions> = WpiLibSimulationOptions::class.java
                   })
    }

    companion object
    {
        const val ID = "FRC.WpiLibSimulation"

        @JvmStatic
        fun getInstance(): WpiLibSimulationConfigurationType = com.intellij.execution.configurations.ConfigurationTypeUtil.findConfigurationType(WpiLibSimulationConfigurationType::class.java)
    }
}

class WpiLibSimulationOptions : ModuleBasedConfigurationOptions()
{
    var hwSim by property(false)
    var clean by property(false)
    var vmOptions by string()
}

/** The simulation launch details, determined by the before run task from the file generated by the `simulateExternalJava` task (`build/sim/java.json`). */
data class WpiLibSimulationLaunchInfo(
    val jdkHome: Path,
    val projectRoot: Path,
    val mainClass: String,
    val libraryDir: String?,
    val extensionLibraries: List<String>,
    val environment: Map<String, String>,
                                     )

/**
 * Runs the robot program in the WPILib simulator, as the WPILib VS Code extension does: the [WpiLibSimulateExternalBeforeRunTask]
 * runs the `simulateExternalJava` Gradle task, which generates the simulation launch details, and then the robot program is run
 * with the WPILib JDK, the simulation extensions (e.g. the Sim GUI), and the simulation's native libraries.
 *
 * For 2026 and earlier projects, the before run task instead runs the simulation with GradleRIO's `simulateJava` (or, when
 * debugging, `simulateJavaDebug`) Gradle task. See [isSimulatedByGradleTask].
 *
 * Run, Debug, Run with Coverage, and Profile are supported. Coverage and the profilers only support run configurations that are
 * [CommonJavaRunConfigurationParameters], and are applied, via the [JavaRunConfigurationExtensionManager], as they are for an
 * Application run configuration. The main class, working directory, and environment are determined by the WPILib build, so
 * those parameters are read-only.
 */
class WpiLibSimulationRunConfiguration(project: Project, factory: ConfigurationFactory, name: String) :
    ModuleBasedConfiguration<JavaRunConfigurationModule, Element>(name, JavaRunConfigurationModule(project, false), factory),
    CommonJavaRunConfigurationParameters
{
    /** Set by the before run task for the run being launched. */
    @Transient
    var launchInfo: WpiLibSimulationLaunchInfo? = null

    override fun getOptions(): WpiLibSimulationOptions = super.getOptions() as WpiLibSimulationOptions

    var hwSim: Boolean
        get() = options.hwSim
        set(value) { options.hwSim = value }

    var clean: Boolean
        get() = options.clean
        set(value) { options.clean = value }

    var vmOptions: String?
        get() = options.vmOptions
        set(value) { options.vmOptions = value }

    override fun getValidModules(): Collection<Module> = ModuleManager.getInstance(project).modules.toList()

    /**
     * The [WpiLibSimulateExternalBeforeRunTask] builds the robot code, with the WPILib JDK, so the IDE's 'Build' before launch
     * task is not needed. It would also build with the project's Gradle JVM, which fails if it is older than the Java version
     * the robot code requires (e.g. Java 25 for 2027).
     */
    override fun isBuildBeforeLaunchAddedByDefault(): Boolean = false

    // region CommonJavaRunConfigurationParameters

    override fun getVMParameters(): String? = vmOptions
    override fun setVMParameters(value: String?) { vmOptions = value?.ifBlank { null } }
    // The simulation is always run with the WPILib JDK, which is determined when it is launched
    override fun isAlternativeJrePathEnabled(): Boolean = false
    override fun setAlternativeJrePathEnabled(enabled: Boolean) {}
    override fun getAlternativeJrePath(): String? = null
    override fun setAlternativeJrePath(path: String?) {}
    override fun getRunClass(): String? = null
    override fun getPackage(): String? = null
    override fun getProgramParameters(): String? = null
    override fun setProgramParameters(value: String?) {}
    override fun getWorkingDirectory(): String? = project.basePath
    override fun setWorkingDirectory(value: String?) {}
    override fun getEnvs(): Map<String, String> = emptyMap()
    override fun setEnvs(envs: Map<String, String>) {}
    override fun isPassParentEnvs(): Boolean = true
    override fun setPassParentEnvs(passParentEnvs: Boolean) {}

    // endregion

    // The settings of the run configuration extensions (e.g. the coverage settings) are not part of the options
    override fun readExternal(element: Element)
    {
        super.readExternal(element)
        JavaRunConfigurationExtensionManager.instance.readExternal(this, element)
    }

    override fun writeExternal(element: Element)
    {
        super.writeExternal(element)
        JavaRunConfigurationExtensionManager.instance.writeExternal(this, element)
    }

    /** Defaults the module of a configuration the user adds (e.g. via the Run/Debug Configurations dialog) to the main module. */
    override fun onNewConfigurationCreated()
    {
        super.onNewConfigurationCreated()
        if (configurationModule.module == null) project.getMainModule()?.let { setModule(it) }
    }

    override fun checkConfiguration()
    {
        if (configurationModule.module == null) throw RuntimeConfigurationError("The module is not specified. Select the robot project's 'main' module.")
        // The simulation must always be of freshly built code, so the build (simulateExternalJava) step cannot be removed
        if (beforeRunTasks.none { it is WpiLibSimulateExternalBeforeRunTask && it.isEnabled })
        {
            throw RuntimeConfigurationError("The '${WpiLibSimulateExternalBeforeRunTaskProvider.NAME}' before launch step is required, as it builds the robot code for the simulation.",
                                            Runnable { beforeRunTasks = beforeRunTasks + WpiLibSimulateExternalBeforeRunTask() })
        }
        JavaRunConfigurationExtensionManager.checkConfigurationIsValid(this)
    }

    // Includes the editors of the run configuration extensions, such as the Code Coverage settings (e.g. which classes to include)
    override fun getConfigurationEditor(): SettingsEditor<out RunConfiguration> = SettingsEditorGroup<WpiLibSimulationRunConfiguration>().apply {
        addEditor("Configuration", WpiLibSimulationSettingsEditor(project))
        JavaRunConfigurationExtensionManager.instance.appendEditors(this@WpiLibSimulationRunConfiguration, this)
    }

    override fun getState(executor: Executor, environment: ExecutionEnvironment): RunProfileState
    {
        val module = configurationModule.module ?: throw ExecutionException("The module is not specified for '$name'.")
        return object : JavaCommandLineState(environment)
        {
            override fun createJavaParameters(): JavaParameters
            {
                // The launch info is only used for the launch it was prepared (i.e. built) for, so a simulation is never of stale code
                val info = launchInfo ?: throw ExecutionException(
                    "The robot code has not been built for the simulation. The '${WpiLibSimulateExternalBeforeRunTaskProvider.NAME}' before launch step is required.")
                launchInfo = null
                val parameters = JavaParameters()
                parameters.configureByModule(module, JavaParameters.JDK_AND_CLASSES)
                parameters.jdk = JavaSdk.getInstance().createJdk("WPILib JDK", info.jdkHome.toString(), false)
                parameters.mainClass = info.mainClass
                parameters.workingDirectory = info.projectRoot.toString()
                parameters.vmParametersList.addAll(simulationVmOptions(ParametersListUtil.parse(vmOptions ?: ""), info.libraryDir))

                val env = LinkedHashMap(info.environment)
                if (info.extensionLibraries.isNotEmpty()) env[halSimExtensionsEnvVar] = info.extensionLibraries.joinToString(File.pathSeparator)
                // The simulation's native libraries must be on the OS library path, as done by WPILib
                if (info.libraryDir != null)
                {
                    val libraryPathEnvVar = when
                    {
                        SystemInfo.isWindows -> System.getenv().keys.firstOrNull { it.equals("PATH", ignoreCase = true) } ?: "PATH"
                        SystemInfo.isMac     -> "DYLD_LIBRARY_PATH"
                        else                 -> "LD_LIBRARY_PATH"
                    }
                    env[libraryPathEnvVar] = listOfNotNull(info.libraryDir, System.getenv(libraryPathEnvVar)?.ifBlank { null }).joinToString(File.pathSeparator)
                }
                parameters.env = env
                parameters.isPassParentEnvs = true
                // Adds, for example, the coverage or profiler agent when run with coverage or profiled
                JavaRunConfigurationExtensionManager.instance.updateJavaParameters(this@WpiLibSimulationRunConfiguration, parameters, runnerSettings, executor)
                return parameters
            }

            override fun startProcess(): OSProcessHandler
            {
                val handler = super.startProcess()
                // Collects, for example, the coverage data or profiler snapshot when the simulation ends
                JavaRunConfigurationExtensionManager.instance.attachExtensionsToProcess(this@WpiLibSimulationRunConfiguration, handler, runnerSettings)
                return handler
            }
        }
    }
}

private class WpiLibSimulationSettingsEditor(project: Project) : SettingsEditor<WpiLibSimulationRunConfiguration>()
{
    private val modulesComboBox = ModulesComboBox().apply { fillModules(project) }
    private val hwSimCheckBox = JCheckBox("Hardware simulation ($hwSimArgument)")
    private val cleanCheckBox = JCheckBox("Clean before building")
    private val vmOptionsEditor = RawCommandLineEditor()
    private val panel = FormBuilder.createFormBuilder()
        .addLabeledComponent("Module:", modulesComboBox)
        .addComponent(hwSimCheckBox)
        .addComponent(cleanCheckBox)
        .addLabeledComponent("Additional VM options:", vmOptionsEditor)
        .addComponentFillVertically(javax.swing.JPanel(), 0)
        .panel

    override fun resetEditorFrom(configuration: WpiLibSimulationRunConfiguration)
    {
        modulesComboBox.selectedModule = configuration.configurationModule.module
        hwSimCheckBox.isSelected = configuration.hwSim
        cleanCheckBox.isSelected = configuration.clean
        vmOptionsEditor.text = configuration.vmOptions ?: ""
    }

    override fun applyEditorTo(configuration: WpiLibSimulationRunConfiguration)
    {
        configuration.setModule(modulesComboBox.selectedModule)
        configuration.hwSim = hwSimCheckBox.isSelected
        configuration.clean = cleanCheckBox.isSelected
        configuration.vmOptions = vmOptionsEditor.text.ifBlank { null }
    }

    override fun createEditor(): JComponent = panel
}

// endregion

// region Before run task

/**
 * A before run task, for [WpiLibSimulationRunConfiguration]s, that runs WPILib's `simulateExternalJava` Gradle task (or, before 2027,
 * runs the simulation with the `simulateJava` Gradle task).
 */
class WpiLibSimulateExternalBeforeRunTask : BeforeRunTask<WpiLibSimulateExternalBeforeRunTask>(WpiLibSimulateExternalBeforeRunTaskProvider.ID)
{
    init
    {
        isEnabled = true
    }
}

/**
 * Runs `gradlew [clean] <simulateExternalJava task> [-PhwSim] -Dorg.gradle.java.home=<WPILib JDK>`, as the WPILib VS Code extension
 * does, then reads the launch details it generates (`build/sim/java.json`) to determine how to launch the simulation.
 *
 * For 2026 and earlier projects (see [isSimulatedByGradleTask]), it instead runs `gradlew [clean] simulateJava[Debug] [-PhwSim]`
 * as a Gradle run, with the same executor (i.e. Run or Debug), and the launch of the run configuration itself is not continued.
 */
class WpiLibSimulateExternalBeforeRunTaskProvider : BeforeRunTaskProvider<WpiLibSimulateExternalBeforeRunTask>()
{
    companion object
    {
        @JvmField
        val ID: Key<WpiLibSimulateExternalBeforeRunTask> = Key.create("FRC.WpiLibSimulateExternal")
        const val NAME = "WPILib: Build Robot Code for Simulation"
    }

    override fun getId(): Key<WpiLibSimulateExternalBeforeRunTask> = ID

    override fun getName(): String = NAME

    override fun getIcon(): Icon = FrcIcons.FRC.FIRST_ICON_MEDIUM_16

    // Added (enabled) to every WPILib Simulation run configuration
    override fun createTask(runConfiguration: RunConfiguration): WpiLibSimulateExternalBeforeRunTask? =
        if (runConfiguration is WpiLibSimulationRunConfiguration) WpiLibSimulateExternalBeforeRunTask() else null

    override fun executeTask(context: DataContext, configuration: RunConfiguration, environment: ExecutionEnvironment, task: WpiLibSimulateExternalBeforeRunTask): Boolean
    {
        val project = environment.project
        val simConfiguration = configuration as? WpiLibSimulationRunConfiguration
            ?: return failed(project, "The '$NAME' before launch task can only be used with WPILib Simulation run configurations.")
        simConfiguration.launchInfo = null
        val projectRoot = project.wpiLibProjectRoot()
            ?: return failed(project, "Could not determine the project's root directory.")

        val projectYear = project.getConfiguredProjectYear()
        if (isSimulatedByGradleTask(projectYear))
        {
            runSimulateJavaGradleTask(project, projectRoot, simConfiguration, environment.executor)
            // The Gradle task runs the simulation, so this run configuration's own launch is not continued
            return false
        }
        val jdkHome = wpiLibJdkHomeCandidates(projectYear).firstOrNull { it.hasJavaExecutable() }
            ?: return failed(project, wpiLibJdkNotFoundMessage(projectYear))

        val parameters = listOfNotNull(if (simConfiguration.clean) "clean" else null, simulateExternalJavaGradleTask, if (simConfiguration.hwSim) hwSimArgument else null)
        val progressText = "Running $simulateExternalJavaGradleTask" + if (simConfiguration.hwSim) " (hardware simulation)" else ""
        when (val result = runGradleWrapperWithWpiLibJdk(projectRoot, jdkHome, parameters, progressText))
        {
            WpiLibGradleResult.Succeeded -> {}
            WpiLibGradleResult.Cancelled -> return false
            is WpiLibGradleResult.Failed -> return failed(project, result.message, result.output)
        }

        val simConfigFile = projectRoot.resolve("build").resolve(simConfigFileName)
        val simConfig = try
        {
            (Files.newBufferedReader(simConfigFile).use { Parser.default().parse(it) } as JsonArray<*>)
                .filterIsInstance<JsonObject>()
                .firstOrNull { it.string("type") == "java" }
                ?: throw IllegalStateException("No Java simulation configuration found in $simConfigFile")
        }
        catch (e: Exception)
        {
            return failed(project, "Could not read the simulation configuration '$simConfigFile': ${e.message}")
        }
        val mainClass = simConfig.string("mainClassName")
            ?: return failed(project, "The simulation configuration '$simConfigFile' does not specify a main class.")

        simConfiguration.launchInfo = WpiLibSimulationLaunchInfo(
            jdkHome = jdkHome,
            projectRoot = projectRoot,
            mainClass = mainClass,
            libraryDir = simConfig.string("libraryDir"),
            // The extensions (e.g. the Sim GUI) that are enabled by default in the project's build.gradle
            extensionLibraries = simConfig.array<JsonObject>("extensions")
                ?.filter { it.boolean("defaultEnabled") == true }
                ?.mapNotNull { it.string("libName") }
                ?: emptyList(),
            environment = (simConfig.obj("environment")?.map ?: emptyMap<String, Any?>())
                .mapNotNull { (key, value) -> value?.let { key to it.toString() } }
                .toMap(),
                                                               )
        return true
    }

    /**
     * Runs the simulation (2026 and earlier) with the `simulateJava` Gradle task, or `simulateJavaDebug` when debugging. It is run
     * as a Gradle run so that, when debugging, the IDE's Gradle support attaches the debugger to the simulation (a `JavaExec` task).
     */
    private fun runSimulateJavaGradleTask(project: Project, projectRoot: Path, configuration: WpiLibSimulationRunConfiguration, executor: Executor)
    {
        val debug = when (executor.id)
        {
            DefaultRunExecutor.EXECUTOR_ID   -> false
            DefaultDebugExecutor.EXECUTOR_ID -> true
            else                             ->
            {
                failed(project, "'${executor.actionName}' is not supported for the simulation of 2026 and earlier projects, which is run by the " +
                                "'${simulateJavaGradleTask(debug = false)}' Gradle task. Use Run or Debug.")
                return
            }
        }
        val settings = ExternalSystemTaskExecutionSettings().apply {
            externalSystemIdString = GradleConstants.SYSTEM_ID.id
            // Must match the linked Gradle project's path (e.g. forward slashes on Windows), or its settings, such as the Gradle JVM, are not used
            externalProjectPath = linkedGradleProjectPath(project, projectRoot)
            taskNames = listOfNotNull(if (configuration.clean) "clean" else null, simulateJavaGradleTask(debug))
            scriptParameters = if (configuration.hwSim) hwSimArgument else ""
        }
        logger.info("[FRC] Running the simulation with the Gradle tasks ${settings.taskNames} ${settings.scriptParameters} (${executor.id})")
        ApplicationManager.getApplication().invokeLater({
            if (!project.isDisposed)
            {
                ExternalSystemUtil.runTask(settings, executor.id, project, GradleConstants.SYSTEM_ID, null, ProgressExecutionMode.IN_BACKGROUND_ASYNC, true)
            }
        }, ModalityState.nonModal())
    }

    /** The path of the linked Gradle project for the project root, as it is in the Gradle settings. */
    private fun linkedGradleProjectPath(project: Project, projectRoot: Path): String
    {
        val projectRootPath = FileUtil.toSystemIndependentName(projectRoot.toString())
        return GradleSettings.getInstance(project).linkedProjectsSettings.mapNotNull { it.externalProjectPath }.firstOrNull { FileUtil.pathsEqual(it, projectRootPath) }
               ?: projectRootPath
    }

    private fun failed(project: Project, message: String, output: String? = null): Boolean
    {
        logger.warn("[FRC] WPILib simulation could not be started: $message")
        notifyWpiLibGradleTaskFailure(project, "Robot Simulation Failed", message, output, "simulateExternalJava-output.log")
        return false
    }
}

// endregion

// region Gradle wrapper

internal fun wpiLibJdkNotFoundMessage(projectYear: String?): String =
    "The WPILib JDK for '${projectYear ?: "the project year"}' was not found. Looked in: " +
    wpiLibJdkHomeCandidates(projectYear).joinToString(", ") + ". Install WPILib for the project's year, or update the project's year."

internal sealed interface WpiLibGradleResult
{
    object Succeeded : WpiLibGradleResult
    object Cancelled : WpiLibGradleResult
    class Failed(val message: String, val output: String? = null) : WpiLibGradleResult
}

/**
 * Runs `gradlew <parameters> -Dorg.gradle.java.home=<WPILib JDK>` in the project root, as the WPILib VS Code extension does,
 * showing the progress in the [indicator] (by default, the current one, if any). Using the WPILib JDK, rather than the project's
 * Gradle JVM, ensures the robot code is built with the Java version it requires. The [outputListener], if provided, receives
 * the Gradle output as it is produced.
 */
internal fun runGradleWrapperWithWpiLibJdk(projectRoot: Path,
                                           jdkHome: Path,
                                           parameters: List<String>,
                                           progressText: String,
                                           indicator: ProgressIndicator? = ProgressManager.getInstance().progressIndicator,
                                           outputListener: ((text: String, outputType: Key<*>) -> Unit)? = null): WpiLibGradleResult
{
    val gradlew = projectRoot.resolve(if (SystemInfo.isWindows) "gradlew.bat" else "gradlew")
    if (!Files.isRegularFile(gradlew)) return WpiLibGradleResult.Failed("The Gradle wrapper ($gradlew) was not found.")
    if (!SystemInfo.isWindows) gradlew.toFile().setExecutable(true)

    val commandLine = GeneralCommandLine(gradlew.toString())
        .withParameters(parameters)
        .withParameters("-Dorg.gradle.java.home=$jdkHome")
        .withWorkDirectory(projectRoot.toFile())
        .withParentEnvironmentType(GeneralCommandLine.ParentEnvironmentType.CONSOLE)
        // The wrapper script launches Gradle with JAVA_HOME
        .withEnvironment("JAVA_HOME", jdkHome.toString())

    logger.info("[FRC] Running: ${commandLine.commandLineString}")
    indicator?.text = progressText
    val handler = CapturingProcessHandler(commandLine)
    handler.addProcessListener(object : ProcessListener
                               {
                                   override fun onTextAvailable(event: ProcessEvent, outputType: Key<*>)
                                   {
                                       event.text.trim().takeIf { it.isNotEmpty() }?.let { indicator?.text2 = it }
                                       outputListener?.invoke(event.text, outputType)
                                   }
                               })
    val output = if (indicator != null) handler.runProcessWithProgressIndicator(indicator) else handler.runProcess()
    if (output.isCancelled) return WpiLibGradleResult.Cancelled
    if (output.exitCode != 0)
    {
        val fullOutput = "> ${commandLine.commandLineString}\n\n${output.stdout}\n${output.stderr}"
        return WpiLibGradleResult.Failed("'${parameters.joinToString(" ")}' failed (exit code ${output.exitCode}).", fullOutput)
    }
    return WpiLibGradleResult.Succeeded
}

/** Shows an error notification, with an action to show the Gradle output, if there is any. */
internal fun notifyWpiLibGradleTaskFailure(project: Project, title: String, message: String, output: String?, outputFileName: String)
{
    val builder = FrcNotifyType.ACTIONABLE_ERROR.builder()
        .withContent(message)
        .withFrcPrefixedTitle(title)
        .withNoSubTitle()
    val withActions = if (output != null)
    {
        builder.withActionBasic("Show Gradle output") {
            ApplicationManager.getApplication().invokeLater({
                if (!project.isDisposed)
                {
                    val outputFile = LightVirtualFile(outputFileName, PlainTextFileType.INSTANCE, output)
                    outputFile.isWritable = false
                    FileEditorManager.getInstance(project).openFile(outputFile, true)
                }
            }, ModalityState.nonModal())
        }.noMoreActions()
    }
    else
    {
        builder.withNoActions()
    }
    withActions.notify(project)
}

// endregion
