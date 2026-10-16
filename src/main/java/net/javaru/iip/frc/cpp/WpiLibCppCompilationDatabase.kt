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

package net.javaru.iip.frc.cpp

import com.google.gson.GsonBuilder
import com.google.gson.JsonArray
import com.google.gson.JsonParser
import com.intellij.execution.RunManager
import com.intellij.execution.configurations.GeneralCommandLine
import com.intellij.execution.process.CapturingProcessHandler
import com.intellij.ide.util.PropertiesComponent
import com.intellij.openapi.Disposable
import com.intellij.openapi.application.ApplicationManager
import com.intellij.openapi.application.ModalityState
import com.intellij.openapi.components.Service
import com.intellij.openapi.components.service
import com.intellij.openapi.diagnostic.logger
import com.intellij.openapi.progress.ProgressIndicator
import com.intellij.openapi.progress.Task
import com.intellij.openapi.project.Project
import com.intellij.openapi.startup.ProjectActivity
import com.intellij.openapi.util.SystemInfo
import com.intellij.openapi.util.io.FileUtil
import com.intellij.openapi.vfs.LocalFileSystem
import com.intellij.openapi.vfs.VirtualFileManager
import com.intellij.openapi.vfs.newvfs.BulkFileListener
import com.intellij.openapi.vfs.newvfs.events.VFileEvent
import com.intellij.util.Alarm
import net.javaru.iip.frc.notify.FrcNotifyType
import net.javaru.iip.frc.run.findWpiLibJdkHome
import net.javaru.iip.frc.util.isJavaPluginAvailable
import net.javaru.iip.frc.wpilib.findWpiLibProjectRootDirs
import net.javaru.iip.frc.wpilib.getConfiguredProjectYearJustYear
import net.javaru.iip.frc.wpilib.readWpiLibPreferences
import org.jetbrains.plugins.gradle.service.execution.GradleExternalTaskConfigurationType
import org.jetbrains.plugins.gradle.service.execution.GradleRunConfiguration
import java.nio.file.Files
import java.nio.file.Path
import java.time.Year
import java.util.concurrent.atomic.AtomicBoolean
import kotlin.io.path.getLastModifiedTime
import kotlin.io.path.isDirectory
import kotlin.io.path.isRegularFile
import kotlin.io.path.listDirectoryEntries
import kotlin.io.path.name
import kotlin.io.path.readText
import kotlin.io.path.writeText

/*
 * C++ code insight (in CLion) for WPILib C++ robot projects.
 *
 * GradleRIO's `generateCompileCommands` task generates a compilation database (`compile_commands.json`) for each target
 * platform and build type, in `build/TargetedCompileCommands/<platform><buildType>` (e.g. `linuxsystemcoredebug`), that has
 * the include paths of the WPILib and vendordep headers (which Gradle downloads from their Maven repos and extracts), along with
 * the compiler, defines, and flags. The selected target's compilation database is written to the project's root directory, and
 * loaded as CLion's Compilation Database project model. It is regenerated whenever the Gradle build or vendordeps change.
 */

private object WpiLibCppCompilationDatabase
private val logger = logger<WpiLibCppCompilationDatabase>()

/** GradleRIO's task that generates the compilation databases. */
const val generateCompileCommandsTask = "generateCompileCommands"
const val compileCommandsFileName = "compile_commands.json"
private const val targetedCompileCommandsDirPath = "build/TargetedCompileCommands"

/**
 * Lets the compilation databases be generated when a robot's toolchain (which is installed separately via the `installRoboRioToolchain`
 * or `installSystemCoreToolchain` task) is not installed, as GradleRIO otherwise fails. The robot's target is then not generated.
 */
internal val toolchainOptionalArguments = listOf("-Ptoolchain-optional-roboRio", "-Ptoolchain-optional-systemCore")

/** The platforms of the robot controllers (roboRIO and SystemCore), which are preferred since the robot code is compiled for them. */
private val robotPlatforms = listOf("linuxathena", "linuxsystemcore")

/** The first year whose robot controller is the SystemCore rather than the roboRIO. */
private const val systemCoreFirstYear = 2027

/** GradleRIO's task that installs the toolchain (cross compiler) of the robot controller for the project's year. */
fun robotToolchainInstallTask(projectYear: Int?): String =
    if ((projectYear ?: Year.now().value) >= systemCoreFirstYear) "installSystemCoreToolchain" else "installRoboRioToolchain"

/** Whether a compilation database was generated for the robot controller, which requires its toolchain to be installed. */
fun hasRobotTarget(targets: List<String>): Boolean = targets.any { target -> robotPlatforms.any { target.startsWith(it) } }

/** The target (e.g. `linuxsystemcoredebug`) the user selected for the C++ code insight. */
private const val selectedTargetKey = "FRC.cppCompileCommandsTarget"

/** The files that, when changed, change the compilation database (relative to the project root). */
private val compileCommandsInputFiles = listOf("build.gradle", "build.gradle.kts", "settings.gradle", "settings.gradle.kts", ".wpilib/wpilib_preferences.json")
private const val vendordepsDirName = "vendordeps"

/** Whether the project is a WPILib C++ project, i.e. its `.wpilib/wpilib_preferences.json` file's `currentLanguage` is `cpp`. */
fun Project.isWpiLibCppProject(): Boolean = readWpiLibPreferences()?.get("currentLanguage")?.toString()?.trim().equals("cpp", ignoreCase = true)

/** The targets (e.g. `linuxsystemcoredebug` and `windowsx86-64debug`) that GradleRIO generated a compilation database for. */
fun findCompileCommandsTargets(projectRoot: Path): List<String>
{
    val dir = projectRoot.resolve(targetedCompileCommandsDirPath)
    if (!dir.isDirectory()) return emptyList()
    return dir.listDirectoryEntries().filter { it.resolve(compileCommandsFileName).isRegularFile() }.map { it.name }.sorted()
}

/**
 * The target to use for the code insight: the selected target if there is one, otherwise the robot controller's debug target, so
 * the code is analyzed as it is compiled for the robot, otherwise a (desktop) debug target.
 */
fun choosePrimaryTarget(targets: List<String>, selectedTarget: String?): String? =
    selectedTarget?.takeIf { it in targets }
    ?: targets.firstOrNull { target -> robotPlatforms.any { target == "${it}debug" } }
    ?: targets.firstOrNull { it.endsWith("debug") }
    ?: targets.firstOrNull()

/**
 * Creates the compilation database for the primary target. Since tests are only built for the desktop, the files that are not
 * in the primary target's compilation database (i.e. the tests) are added from the other targets of the same build type.
 */
fun mergeCompileCommands(projectRoot: Path, primaryTarget: String, targets: List<String>): String
{
    val buildType = if (primaryTarget.endsWith("release")) "release" else "debug"
    val orderedTargets = listOf(primaryTarget) + targets.filter { it != primaryTarget && it.endsWith(buildType) }
    val files = mutableSetOf<String>()
    val merged = JsonArray()
    orderedTargets.forEach { target ->
        val text = projectRoot.resolve(targetedCompileCommandsDirPath).resolve(target).resolve(compileCommandsFileName).readText()
        JsonParser.parseString(text).asJsonArray.forEach { entry ->
            val file = entry.asJsonObject.get("file")?.asString ?: return@forEach
            if (files.add(FileUtil.toSystemIndependentName(file).lowercase())) merged.add(entry)
        }
    }
    return GsonBuilder().setPrettyPrinting().disableHtmlEscaping().create().toJson(merged)
}

/** Whether the project's compilation database is newer than the files it is generated from. */
private fun isCompileCommandsUpToDate(projectRoot: Path): Boolean
{
    val compileCommands = projectRoot.resolve(compileCommandsFileName)
    if (!compileCommands.isRegularFile()) return false
    val inputs = compileCommandsInputFiles.map { projectRoot.resolve(it) } +
                 (projectRoot.resolve(vendordepsDirName).takeIf { it.isDirectory() }?.listDirectoryEntries("*.json") ?: emptyList())
    val generated = compileCommands.getLastModifiedTime()
    return inputs.filter { it.isRegularFile() }.all { it.getLastModifiedTime() <= generated }
}

/** Whether the path is one of the files the compilation database is generated from. */
private fun isCompileCommandsInputPath(projectRootPath: String, path: String): Boolean
{
    val relativePath = FileUtil.getRelativePath(projectRootPath, FileUtil.toSystemIndependentName(path), '/') ?: return false
    return relativePath in compileCommandsInputFiles || (relativePath.startsWith("$vendordepsDirName/") && relativePath.endsWith(".json"))
}

@Service(Service.Level.PROJECT)
class WpiLibCppCompilationDatabaseService(private val project: Project) : Disposable
{
    companion object
    {
        @JvmStatic
        fun getInstance(project: Project): WpiLibCppCompilationDatabaseService = project.service()
    }

    private val running = AtomicBoolean(false)
    private val rerunRequested = AtomicBoolean(false)
    /** Whether the robot toolchain was automatically installed this session, so a failing install is not retried on each update. */
    private val toolchainInstallAttempted = AtomicBoolean(false)
    private val updateAlarm = Alarm(Alarm.ThreadToUse.POOLED_THREAD, this)

    /** The root directory of the WPILib C++ project, or `null` if the project is not a WPILib C++ project. */
    fun findCppProjectRoot(): Path? = project.findWpiLibProjectRootDirs().firstOrNull()?.takeIf { project.isWpiLibCppProject() }?.toNioPath()

    /** Sets up a WPILib C++ project when it is opened. Must not be called on the EDT. */
    internal fun onProjectOpened()
    {
        val projectRoot = findCppProjectRoot() ?: return
        logger.info("[FRC] WPILib C++ project detected: '${project.name}'")
        listenForInputChanges(projectRoot)
        ApplicationManager.getApplication().invokeLater({ ensureCppRunConfigurations(project) }, ModalityState.nonModal(), project.disposed)
        // When the robot toolchain is not installed, the compile commands are generated (to install it) even if they are up to date
        if (isCompileCommandsUpToDate(projectRoot) && hasRobotTarget(findCompileCommandsTargets(projectRoot)))
        {
            // Still (re)load it, in case it is not yet linked as the project's compilation database
            loadCompilationDatabase(projectRoot)
        }
        else
        {
            update(userInitiated = false)
        }
    }

    /** Regenerates the compilation database when the Gradle build or vendordeps change, which may change the WPILib/vendor libraries. */
    private fun listenForInputChanges(projectRoot: Path)
    {
        val projectRootPath = FileUtil.toSystemIndependentName(projectRoot.toString())
        project.messageBus.connect(this).subscribe(VirtualFileManager.VFS_CHANGES, object : BulkFileListener
        {
            override fun after(events: List<VFileEvent>)
            {
                if (events.any { isCompileCommandsInputPath(projectRootPath, it.path) })
                {
                    // Coalesces multiple changes (e.g. when several vendordeps are added at once)
                    updateAlarm.cancelAllRequests()
                    updateAlarm.addRequest({ update(userInitiated = false) }, 2_000)
                }
            }
        })
    }

    /**
     * Generates, via GradleRIO, the compilation database and loads it. If an update is already running, another update is run once it completes.
     * @param userInitiated whether the user requested the update, in which case the user is notified of the result
     */
    fun update(userInitiated: Boolean)
    {
        if (!running.compareAndSet(false, true))
        {
            rerunRequested.set(true)
            return
        }
        ApplicationManager.getApplication().invokeLater({
            object : Task.Backgroundable(project, "Generating C++ compile commands", true)
            {
                override fun run(indicator: ProgressIndicator) = generate(indicator, userInitiated)

                override fun onFinished()
                {
                    running.set(false)
                    if (rerunRequested.getAndSet(false) && !project.isDisposed) update(userInitiated = false)
                }
            }.queue()
        }, ModalityState.nonModal(), project.disposed)
    }

    private fun generate(indicator: ProgressIndicator, userInitiated: Boolean)
    {
        val projectRoot = findCppProjectRoot() ?: return
        val gradlew = projectRoot.resolve(if (SystemInfo.isWindows) "gradlew.bat" else "gradlew")
        if (!gradlew.isRegularFile())
        {
            notifyFailure("The Gradle wrapper ($gradlew) was not found, so the compile commands could not be generated.")
            return
        }
        if (runGradleTask(projectRoot, gradlew, generateCompileCommandsTask, indicator) != true) return
        // Without the robot's toolchain, only the desktop targets are generated, so it is installed (once per session, unless the user
        // requested the update) and the compile commands regenerated, so the code is analyzed as it is compiled for the robot
        if (!hasRobotTarget(findCompileCommandsTargets(projectRoot)) && (toolchainInstallAttempted.compareAndSet(false, true) || userInitiated))
        {
            val installTask = robotToolchainInstallTask(project.getConfiguredProjectYearJustYear())
            logger.info("[FRC] The robot toolchain of project '${project.name}' is not installed. Installing it with the '$installTask' Gradle task.")
            when (runGradleTask(projectRoot, gradlew, installTask, indicator))
            {
                true  -> if (runGradleTask(projectRoot, gradlew, generateCompileCommandsTask, indicator) != true) return
                false -> Unit // The failure was reported; the desktop target's compile commands are still used
                null  -> return
            }
        }
        loadCompilationDatabase(projectRoot, userInitiated)
    }

    /**
     * Runs a Gradle task of the project, with the WPILib JDK (as when building the robot code), reporting a failure to the user.
     * @return whether the task succeeded, or `null` if it was cancelled
     */
    private fun runGradleTask(projectRoot: Path, gradlew: Path, task: String, indicator: ProgressIndicator): Boolean?
    {
        indicator.text = "Running the '$task' Gradle task"
        val executable = if (SystemInfo.isWindows || Files.isExecutable(gradlew)) listOf(gradlew.toString()) else listOf("/bin/sh", gradlew.toString())
        val commandLine = GeneralCommandLine(executable + task + toolchainOptionalArguments + "--console=plain")
            .withWorkingDirectory(projectRoot)
            .withParentEnvironmentType(GeneralCommandLine.ParentEnvironmentType.CONSOLE)
        project.findWpiLibJdkHome()?.let { commandLine.withEnvironment("JAVA_HOME", it.toString()) }
        logger.info("[FRC] Running the '$task' Gradle task of project '${project.name}': ${commandLine.commandLineString}")
        val output = CapturingProcessHandler(commandLine).runProcessWithProgressIndicator(indicator)
        if (output.isCancelled) return null
        if (output.exitCode != 0)
        {
            logger.warn("[FRC] The '$task' Gradle task failed (exit code ${output.exitCode}):\n${output.stdout}\n${output.stderr}")
            val details = (output.stderr.ifBlank { output.stdout }).lines().filter { it.isNotBlank() }.takeLast(8).joinToString("<br/>")
            notifyFailure("The '$task' Gradle task failed, so the C++ code insight may be incomplete.<br/><br/><tt>$details</tt>")
            return false
        }
        return true
    }

    /** Writes the (primary target's) compilation database to the project root, if it changed, and loads it. */
    private fun loadCompilationDatabase(projectRoot: Path, userInitiated: Boolean = false)
    {
        val targets = findCompileCommandsTargets(projectRoot)
        val primaryTarget = choosePrimaryTarget(targets, PropertiesComponent.getInstance(project).getValue(selectedTargetKey))
        if (primaryTarget == null)
        {
            notifyFailure("GradleRIO did not generate any compile commands (in $targetedCompileCommandsDirPath). Is a C++ toolchain installed?")
            return
        }
        val compileCommands = projectRoot.resolve(compileCommandsFileName)
        val content = mergeCompileCommands(projectRoot, primaryTarget, targets)
        if (!compileCommands.isRegularFile() || compileCommands.readText() != content)
        {
            compileCommands.writeText(content)
        }
        logger.info("[FRC] Using the '$primaryTarget' C++ compile commands for project '${project.name}' (available: $targets)")
        val compileCommandsFile = LocalFileSystem.getInstance().refreshAndFindFileByNioFile(compileCommands) ?: return
        ApplicationManager.getApplication().invokeLater({ CLionCompilationDatabase.linkOrReload(project, compileCommandsFile) }, ModalityState.nonModal(), project.disposed)
        if (userInitiated)
        {
            FrcNotifyType.GENERAL_INFO.builder()
                .withContent("The C++ code insight now uses the '$primaryTarget' target's compile commands.")
                .withFrcPrefixedTitle("C++ compile commands updated")
                .notify(project)
        }
    }

    /** The targets that can be selected, and the one in use. */
    fun getTargets(): Pair<List<String>, String?>
    {
        val projectRoot = findCppProjectRoot() ?: return emptyList<String>() to null
        val targets = findCompileCommandsTargets(projectRoot)
        return targets to choosePrimaryTarget(targets, PropertiesComponent.getInstance(project).getValue(selectedTargetKey))
    }

    /** Selects the target to use for the code insight, and reloads the compilation database. */
    fun selectTarget(target: String)
    {
        PropertiesComponent.getInstance(project).setValue(selectedTargetKey, target)
        val projectRoot = findCppProjectRoot() ?: return
        ApplicationManager.getApplication().executeOnPooledThread { loadCompilationDatabase(projectRoot, userInitiated = true) }
    }

    private fun notifyFailure(content: String)
    {
        FrcNotifyType.ACTIONABLE_WARN.builder()
            .withContent(content)
            .withFrcPrefixedTitle("C++ compile commands")
            .withAction("Retry", true) { _, _ -> update(userInitiated = true) }
            .noMoreActions()
            .notify(project)
    }

    override fun dispose() = Unit
}

/**
 * Creates Gradle run configurations to build, deploy, and simulate the C++ robot code. (In IntelliJ IDEA, i.e. when the Java
 * plugin is available, the run configurations are created along with the other FRC run configurations.)
 */
private fun ensureCppRunConfigurations(project: Project)
{
    if (project.isDisposed || isJavaPluginAvailable) return
    val projectPath = project.basePath ?: return
    val runManager = RunManager.getInstance(project)
    listOf("Build Robot Code" to listOf("build"),
           "Deploy Robot Code" to listOf("deploy"),
           "Simulate Robot Code" to listOf("simulateNative"))
        .filter { (name, _) -> runManager.findConfigurationByName(name) == null }
        .forEach { (name, tasks) ->
            try
            {
                val settings = runManager.createConfiguration(name, GradleExternalTaskConfigurationType.getInstance().configurationFactories[0])
                (settings.configuration as GradleRunConfiguration).settings.apply {
                    externalProjectPath = projectPath
                    taskNames = tasks
                }
                runManager.addConfiguration(settings)
                if (runManager.selectedConfiguration == null) runManager.selectedConfiguration = settings
                logger.info("[FRC] Created the '$name' run configuration for project '${project.name}'")
            }
            catch (e: Exception)
            {
                logger.warn("[FRC] Could not create the '$name' run configuration for project '${project.name}': $e", e)
            }
        }
}

class WpiLibCppCompilationDatabaseStartupActivity : ProjectActivity
{
    override suspend fun execute(project: Project)
    {
        WpiLibCppCompilationDatabaseService.getInstance(project).onProjectOpened()
    }
}
