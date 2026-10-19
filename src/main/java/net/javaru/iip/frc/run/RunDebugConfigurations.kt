/*
 * Copyright 2015-2022 the original author or authors.
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

import com.intellij.configurationStore.MODERN_NAME_CONVERTER
import com.intellij.execution.RunManager
import com.intellij.ide.util.PropertiesComponent
import com.intellij.execution.RunnerAndConfigurationSettings
import com.intellij.execution.configurations.ConfigurationType
import com.intellij.execution.impl.RunManagerImpl
import com.intellij.execution.jar.JarApplicationConfiguration
import com.intellij.execution.jar.JarApplicationConfigurationType
import com.intellij.execution.remote.RemoteConfiguration
import com.intellij.execution.remote.RemoteConfigurationType
import com.intellij.ide.SaveAndSyncHandler
import com.intellij.openapi.application.ApplicationManager
import com.intellij.openapi.application.WriteAction
import com.intellij.openapi.diagnostic.debug
import com.intellij.openapi.diagnostic.logger
import com.intellij.openapi.diagnostic.trace
import com.intellij.openapi.fileEditor.FileDocumentManager
import com.intellij.openapi.project.Project
import com.intellij.openapi.util.SystemInfo
import com.intellij.openapi.vfs.LocalFileSystem
import net.javaru.iip.frc.i18n.FrcBundle
import net.javaru.iip.frc.services.FrcGradleService
import net.javaru.iip.frc.settings.FrcApplicationSettings
import net.javaru.iip.frc.settings.FrcRoboRioSettings
import net.javaru.iip.frc.settings.RoboRioAddressType
import net.javaru.iip.frc.settings.getProjectTeamNumber
import net.javaru.iip.frc.util.runBackgroundTask
import net.javaru.iip.frc.util.FrcSystemConfigs
import net.javaru.iip.frc.util.asDate
import net.javaru.iip.frc.util.classIsAvailable
import net.javaru.iip.frc.util.getMainModule
import net.javaru.iip.frc.util.getModules
import net.javaru.iip.frc.wizard.FrcProjectWizardData
import net.javaru.iip.frc.wpilib.getAttachedWpiLibVersion
import net.javaru.iip.frc.wpilib.getTeamNumberConfiguredInWpiLibPreferencesFile
import net.javaru.iip.frc.wpilib.getToolsJar
import net.javaru.iip.frc.wpilib.services.WpiLibVersionService
import net.javaru.iip.frc.wpilib.version.WpiLibVersion
import net.javaru.iip.frc.wpilib.version.WpiLibVersionImpl
import org.jetbrains.plugins.gradle.service.execution.GradleExternalTaskConfigurationType
import org.jetbrains.plugins.gradle.service.execution.GradleRunConfiguration
import java.nio.file.Files
import java.nio.file.Paths
import java.time.Duration
import java.time.LocalDateTime
import java.time.Year
import java.util.*

private object RunDebugConfigurations 

private val logger = logger<RunDebugConfigurations>()

data class RunDebugConfigsCreationData (
    val project: Project,
    val teamNumber: Int,
    val wpilibVersion: WpiLibVersion?,
    val robotProjectTypeInfo: FrcGradleService.RobotProjectTypeInfo,
                                      )
{
    companion object
    {
        /**
         * Creates a `RunDebugConfigsCreationData` from the provided project. **The alternate create
         * function -- ` create(FrcProjectWizardData, Project)` -- should be favored over this one
         * when a `FrcProjectWizardData` instance is available as that variant is more performant,
         * and accurate.**
         */
        fun create(project: Project): RunDebugConfigsCreationData
        {
            return RunDebugConfigsCreationData(
                project = project,
                teamNumber = project.getTeamNumberConfiguredInWpiLibPreferencesFile(),
                wpilibVersion = WpiLibVersionService.getInstance(project).versionStatus?.attachedVersion,
                robotProjectTypeInfo = FrcGradleService.getRobotProjectTypeInfo(project),
                                              )
        }

        /**
         * Creates a `RunDebugConfigsCreationData` from the provided FrcProjectWizardData and project.
         * **This create function should be favored over the one that just takes a project as this
         * variant is more performant, and accurate.**
         */
        fun create(frcProjectWizardData: FrcProjectWizardData, project: Project): RunDebugConfigsCreationData
        {
            return RunDebugConfigsCreationData(
                project = project,
                teamNumber = frcProjectWizardData.teamNumber,
                wpilibVersion = frcProjectWizardData.wpilibVersion,
                robotProjectTypeInfo = FrcGradleService.getRobotProjectTypeInfo(frcProjectWizardData),
                                              )
        }
    }
}

private const val runDebugConfigurationsCreatedKey = "FRC.runDebugConfigurationsCreated"

/**
 * Creates all the run/debug configurations once for a WPILib project, once its modules exist (i.e. after the Gradle import).
 * Normally the configurations are created when the FRC facet is detected, but that does not happen for all projects
 * (e.g. 2027 projects). Does nothing if they have already been created, including by an earlier plugin version.
 */
fun ensureRunDebugConfigurationsCreated(project: Project)
{
    if (project.isDisposed || project.getMainModule() == null) return
    val properties = PropertiesComponent.getInstance(project)
    if (properties.getBoolean(runDebugConfigurationsCreatedKey)) return
    properties.setValue(runDebugConfigurationsCreatedKey, true)
    if (RunManager.getInstance(project).findConfigurationByName(FrcBundle.message("frc.wizard.run.configuration.buildAndDeploy.name")) != null) return
    project.runBackgroundTask("Creating FRC run configurations") { createAllRunDebugConfigurations(project) }
}

fun createAllRunDebugConfigurations(project: Project?) {
    if (project != null) {
        createAllRunDebugConfigurations(RunDebugConfigsCreationData.create(project))
    }
}

fun createAllRunDebugConfigurations(configsData: RunDebugConfigsCreationData)
{
    logger.debug("[FRC] Running createAllRunDebugConfigurations")
    val project = configsData.project
    PropertiesComponent.getInstance(project).setValue(runDebugConfigurationsCreatedKey, true)
    ApplicationManager.getApplication().invokeAndWait {
        WriteAction.run<Throwable> { FileDocumentManager.getInstance().saveAllDocuments() }
    }
    SaveAndSyncHandler.getInstance().scheduleProjectSave(project)
    val isRoboRioTemplate = configsData.robotProjectTypeInfo.isRoboRIOProject ?: true
    if (isRoboRioTemplate)
    {
        createGradleRoboRioBuildRunConfigurations(project)
        createRoboRioDebuggingRunConfigurations(project, configsData.teamNumber)
    }
    val isRomiTemplate = configsData.robotProjectTypeInfo.isRomiProject ?: false
    val isXrpTemplate = configsData.robotProjectTypeInfo.isXrpProject ?: false
    val hasDesktopSupport = configsData.robotProjectTypeInfo.hasIncludeDesktopSupport ?: false
    val isSimulated = isRomiTemplate || isXrpTemplate || hasDesktopSupport
    if (isSimulated)
    {
        createGradeSimulateJavaRunConfigurations(project, isRomiTemplate, isXrpTemplate)
        if (((configsData.wpilibVersion?.frcYear ?: Year.now().value) <= 2022) && (SystemInfo.isMac || SystemInfo.isLinux || FrcSystemConfigs.AlwaysCreateRomiTailRunConfig.value))
        {
            createTailSimulateJavaLogShellScriptRunConfiguration(project, isRomiTemplate, isXrpTemplate)
        }
        // For now, we will create both. A future enhancement can make this selectable in the wizard
        if (configsData.wpilibVersion != null)
        {
            createLaunchShuffleboardRunConfiguration(project, configsData.wpilibVersion)
            createLaunchSmartDashboardRunConfiguration(project, configsData.wpilibVersion)
        }
    }

    ensureWpiLibSimulationRunConfigurations(project)

    val runManager = RunManager.getInstance(project)
    if (runManager is RunManagerImpl)
    {
        runManager.setOrder(Comparator { config1, config2 -> 
            compareValuesBy(config1, config2) { it?.name} }, isApplyAdditionalSortByTypeAndGroup = true)
        runManager.requestSort()
    }
    
    // We need to do a Save here or the run config files are not created, which then causes all sorts of issues (to say the least)
    ApplicationManager.getApplication().invokeAndWait {
        WriteAction.run<Throwable> { FileDocumentManager.getInstance().saveAllDocuments() }
    }
    SaveAndSyncHandler.getInstance().scheduleProjectSave(project)
    logger.debug("[FRC] Completed createAllRunDebugConfigurations")
}


/**
 * @param arguments the (optional) arguments to send to Gradle when it runs. For example "-PdebugMode=true" 
 * @param vmOptions the (optional) VM Arguments to set. For example "-Dorg.gradle.java.home=C:/java/11"
 */
@JvmOverloads
fun createGradleRunConfiguration(project: Project,
                                 runConfigName: String,
                                 gradleTasks: List<String>,
                                 setAsSelected: Boolean = false,
                                 setAsShared: Boolean = true,
                                 arguments:String? = null,
                                 vmOptions: String? = null)
{
    /* For reference and examples:
           A) runCustomTask in org.jetbrains.plugins.gradle.service.task.GradleTaskManager
           B) org.jetbrains.plugins.gradle.service.execution.GradleRunConfigurationImporter
           C) CreateAndEditPolicy static class in com.intellij.execution.actions.CreateAction
                This is what is used for the "Create 'FRC [build]'.." popup in the Gradle tool window
                Found via the "create.run.configuration.for.item.action.name" bundle message from P:\ij\platform\platform-resources-en\src\messages\ExecutionBundle.properties
                It extends CreatePolicy
                While it has/uses a ConfigurationContext, the context is used to get:
                    1) RunManager
                    2) RunnerAndConfigurationSettings
                which we can get by the fact we have a handle on the project

       Based on org.jetbrains.idea.devkit.module.PluginModuleBuilder, it appears the commitModule method is the place to create the configurations.
    */

    try
    {
        if (project.basePath != null)
        {
            val runManager = RunManager.getInstance(project)
            val configurationFactory = GradleExternalTaskConfigurationType.getInstance().configurationFactories[0]
            val runnerAndConfigurationSettings = runManager.createConfiguration(runConfigName, configurationFactory)
            val gradleRunConfiguration = runnerAndConfigurationSettings.configuration as GradleRunConfiguration

            val gradleTaskSettings = gradleRunConfiguration.settings
            gradleTaskSettings.externalProjectPath = project.basePath
            gradleTaskSettings.taskNames = gradleTasks
            if (arguments != null) gradleTaskSettings.scriptParameters = arguments
            if (vmOptions != null) gradleTaskSettings.vmOptions = vmOptions

            if (setAsShared)
            {
                shareRunConfiguration(project, runnerAndConfigurationSettings)
            }

            runManager.addConfiguration(runnerAndConfigurationSettings)
            if (setAsSelected)
            {
                runManager.selectedConfiguration = runnerAndConfigurationSettings
            }
        }
        else
        {
            logger.info("[FRC] Could not create '$runConfigName' Run Configuration for project '${project.name}' because the project's basDir was null")
        }
    }
    catch (e: Exception)
    {
        logger.warn("[FRC] Could not create '$runConfigName' Run Configuration for project '${project.name}' due to an exception: $e", e)
    }
}




private fun createGradeSimulateJavaRunConfigurations(project: Project, isRomi: Boolean, isXrp: Boolean, setAsShared: Boolean = true)
{
    logger.trace {"[FRC] Creating Gradle simulateJava run configurations"}
    val nameSuffix = if (isRomi) "Romi via Simulate Java" else if(isXrp) "XRP via Simulate Java" else "Simulate Java"
    createGradleRunConfiguration(project, FrcBundle.message("frc.wizard.run.configuration.simulateJava.buildAndRun.name", nameSuffix), listOf("simulateJava"), setAsShared = setAsShared, setAsSelected = isRomi)
    createGradleRunConfiguration(project, FrcBundle.message("frc.wizard.run.configuration.simulateJava.cleanBuildAndRun.name", nameSuffix), listOf("clean", "simulateJava"), setAsShared = setAsShared)
    logger.trace {"[FRC] Completed Gradle simulateJava run configurations"}
}

@Suppress("UNUSED_PARAMETER")
@JvmOverloads
fun createTailSimulateJavaLogShellScriptRunConfiguration(project: Project, isRomi: Boolean, isXrp: Boolean, setAsShared: Boolean = true)
{
    // This is not the ideal methodology. But it works in v2020.2+
    // In v2020.3+ we can switch to running in terminal and defining the script as /user/bin/tail

    val nameSuffix = if (isRomi) "Romi via Simulate Java" else if (isXrp) "XRP via Simulate Java" else "Simulate Java"
    val runConfigName = FrcBundle.message("frc.wizard.run.configuration.simulateJava.tail.name", nameSuffix)
    try
    {
        if (project.basePath != null && classIsAvailable("com.intellij.sh.run.ShConfigurationType"))
        {
            val runManager = RunManager.getInstance(project)
            val runnerAndConfigurationSettings = runManager.createConfiguration(runConfigName, com.intellij.sh.run.ShConfigurationType::class.java)
            val shRunConfiguration = runnerAndConfigurationSettings.configuration as com.intellij.sh.run.ShRunConfiguration

            shRunConfiguration.scriptPath = "${project.basePath}/build/stdout/simulateJava.log"
            //shRunConfiguration.scriptOptions = ""
            shRunConfiguration.scriptWorkingDirectory = project.basePath
            shRunConfiguration.interpreterPath = "/usr/bin/tail"
            shRunConfiguration.interpreterOptions = "-f"

            shRunConfiguration.isAllowRunningInParallel = false
            // Note the "execute in terminal" option is only available in 2020.3+ That said, using the run ToolWindow is ultimately a better option.
            runnerAndConfigurationSettings.isActivateToolWindowBeforeRun = true

            if (setAsShared)
            {
                shareRunConfiguration(project, runnerAndConfigurationSettings)
            }

            // To prevent a "script not found" error showing in the log, we need to create a place holder file
            try
            {
                val file = Paths.get(shRunConfiguration.scriptPath)
                Files.createDirectories(file.parent)
                Files.createFile(file)
                LocalFileSystem.getInstance().refreshAndFindFileByIoFile(file.toFile())
            }
            catch(e:Exception)
            {
                logger.warn("[FRC] An exception occurred when attempting to create simulateJava.log placeholder file.")
            }

            runManager.addConfiguration(runnerAndConfigurationSettings)
        }
    }
    catch (e: NoClassDefFoundError)
    {
        // We should not get this due to the check in the if block. But just in case, we handle it.
        if (e.toString().contains("ShConfigurationType"))
        {
            logger.debug("[FRC] ShConfigurationType not found. Is 'Shell Script' plugin not enabled? Can not create '$runConfigName' Shell Script Run Configuration for project '${project.name}'.")
        }
        else
        {
            logger.warn("[FRC] Could not create '$runConfigName' Shell Script Run Configuration for project '${project.name}' due to a NoClassDefFoundError: $e", e)
        }
    }
    catch (e: Throwable)
    {
        logger.warn("[FRC] Could not create '$runConfigName' Shell Script Run Configuration for project '${project.name}' due to an exception: $e", e)
    }
}

@JvmOverloads
fun createLaunchShuffleboardRunConfiguration(project: Project,
                                             wpilibVersion: WpiLibVersion?,
                                             activateToolWindow: Boolean = false,
                                             setAsShared: Boolean = true,
                                             setAsSelected: Boolean = false)
{
    val wpiLibVer = wpilibVersion ?: project.getAttachedWpiLibVersion() ?: WpiLibVersionImpl.parseSafely("${Year.now().value}.1.1")
    if (wpiLibVer != null)
    {
        val jarPath = getToolsJar("Shuffleboard", wpiLibVer, project)
        createJarApplicationRunConfiguration(project, "Launch Shuffleboard", jarPath.toString(), activateToolWindow, setAsShared, setAsSelected)
    }

}

@JvmOverloads
fun createLaunchSmartDashboardRunConfiguration(project: Project,
                                               wpilibVersion: WpiLibVersion?,
                                               activateToolWindow:
                                               Boolean = false,
                                               setAsShared: Boolean = true,
                                               setAsSelected: Boolean = false)
{
    val wpiLibVer = wpilibVersion ?: project.getAttachedWpiLibVersion() ?: WpiLibVersionImpl.parseSafely("${Year.now().value}.1.1")
    if (wpiLibVer != null)
    {
        val jarPath = getToolsJar("SmartDashboard", wpiLibVer, project)
        createJarApplicationRunConfiguration(project, "Launch SmartDashboard", jarPath.toString(), activateToolWindow, setAsShared, setAsSelected)
    }
}

@JvmOverloads
fun createJarApplicationRunConfiguration(project: Project,
                                         runConfigName: String,
                                         jarPath: String,
                                         activateToolWindow: Boolean = false,
                                         setAsShared: Boolean = true,
                                         setAsSelected: Boolean = false)
{
    try
    {
        val runManager = RunManager.getInstance(project)
        val configurationType = JarApplicationConfigurationType.getInstance()
        val runnerAndConfigurationSettings = runManager.createConfiguration(runConfigName, configurationType)
        @Suppress("UNUSED_VARIABLE")
        val nameWasChanged = runManager.setUniqueNameIfNeeded(runnerAndConfigurationSettings)
        val runConfiguration = runnerAndConfigurationSettings.configuration as JarApplicationConfiguration

        runConfiguration.jarPath = jarPath
        var module = project.getMainModule()
        if (module == null) module = project.getModules().firstOrNull() // We really just need any module so the project JDK is used
        if (module != null)
        {
            runConfiguration.module = module
        }
        else
        {
            // This should be pretty rare. We'll just have to leave the configuration without a module defined ands the user will need to resolve
            logger.warn("[FRC] Could not discover a module to use when configuring the $runConfigName Run Configuration")
        }

        runnerAndConfigurationSettings.isActivateToolWindowBeforeRun = activateToolWindow

        if (setAsShared)
        {
            shareRunConfiguration(project, runnerAndConfigurationSettings)
        }

        runManager.addConfiguration(runnerAndConfigurationSettings)

        if (setAsSelected)
        {
            runManager.selectedConfiguration = runnerAndConfigurationSettings
        }
    }
    catch (e: Exception)
    {
        logger.warn("[FRC] Could not create '$runConfigName' Run Configuration for project '${project.name}' due to an exception: $e", e)
    }
}

private fun createGradleRoboRioBuildRunConfigurations(project: Project)
{
    logger.trace {"[FRC] Creating Gradle roboRIO run configurations"}
    @Suppress("SpellCheckingInspection") 
    val debugModeArgument = "-PdebugMode=true"
    createGradleRunConfiguration(project, FrcBundle.message("frc.wizard.run.configuration.buildAndDeploy.name"), listOf("deploy"), setAsSelected = true)
    createGradleRunConfiguration(project, FrcBundle.message("frc.wizard.run.configuration.buildAndDeployForDebug.name"), listOf("deploy"), arguments = debugModeArgument)
    createGradleRunConfiguration(project, FrcBundle.message("frc.wizard.run.configuration.build.name"), listOf("build"))
    createGradleRunConfiguration(project, FrcBundle.message("frc.wizard.run.configuration.clean.only.name"), listOf("clean"))
    createGradleRunConfiguration(project, FrcBundle.message("frc.wizard.run.configuration.cleanBuildAndDeploy.name"), listOf("clean", "deploy"))
    createGradleRunConfiguration(project, FrcBundle.message("frc.wizard.run.configuration.cleanBuildAndDeployForDebug.name"), listOf("clean", "deploy"), arguments = debugModeArgument)
    createGradleRunConfiguration(project, FrcBundle.message("frc.wizard.run.configuration.cleanBuild.name"), listOf("clean", "build"))
    logger.trace {"[FRC] Completed Gradle roboRIO run configurations"}
}

private fun createRoboRioDebuggingRunConfigurations(project: Project, teamNumber: Int = project.getProjectTeamNumber())
{
    logger.trace {"[FRC] Creating Debugging run configurations"}
    createDebuggingRunConfiguration(project, teamNumber, RoboRioAddressType.IP)
    createDebuggingRunConfiguration(project, teamNumber, RoboRioAddressType.USB)
    logger.trace {"[FRC] Completed Debugging run configurations"}
}

@JvmOverloads
fun createDebuggingRunConfiguration(project: Project, teamNumber: Int = project.getProjectTeamNumber(), addressType: RoboRioAddressType, setAsShared: Boolean = true)
{
    // Some notes: https://firstmncsa.org/2019/01/01/debugging-java-remote-debugging/#intellij
    try
    {
        if (project.basePath != null)
        {
            val runManager = RunManager.getInstance(project)

            val baseName = "Debug Robot via ${addressType.name}"
            
            val existing = runManager.getConfigurationSettingsList(RemoteConfigurationType::class.java).filter { 
                it.name == baseName
            }.toList()
            
            // TODO: we should prompt user and ask if they want to create the duplicate, or pass it in as an option
            if (existing.isNotEmpty()) {
                logger.debug("[FRC] Run/Debug configuration named '$baseName' already exists and will not be recreated.")
                return
            }
            
            val runConfigName = determineNextName(runManager, baseName, RemoteConfigurationType::class.java)
            val configurationFactory = RemoteConfigurationType.getInstance().configurationFactories[0]
            val runnerAndConfigurationSettings = runManager.createConfiguration(runConfigName, configurationFactory)

            val remoteConfiguration = runnerAndConfigurationSettings.configuration as RemoteConfiguration
            remoteConfiguration.HOST = FrcRoboRioSettings.createRoboRioAddressDefault(teamNumber, addressType)
            remoteConfiguration.PORT = FrcApplicationSettings.getInstance().debuggingPort.toString()

            try
            {
//            val mainModule = project.getMainModule()
//            if (mainModule != null)
//            {
//                logger.debug {"[FRC] For Debugging Configuration '$runConfigName', setting module directly."}
//                remoteConfiguration.setModule(mainModule)
//            }
//            else
//            {
                logger.debug {"[FRC] For Debugging Configuration '$runConfigName', setting module by name."}
                remoteConfiguration.setModuleName("${project.name}.main")
//            }
            }
            catch (e: Exception)
            {
                // We'd rather create a config missing the module then have the creation totally fail
                logger.warn("[FRC] Could not add module to the Debugging config $runConfigName due an exception: $e", e)
            }


            if (setAsShared)
            {
                shareRunConfiguration(project, runnerAndConfigurationSettings)
            }

            runManager.addConfiguration(runnerAndConfigurationSettings)
        }
        else
        {
            logger.info("[FRC] Could not create Debugging Configuration for project '${project.name}' as the baseDir was null")
        }
    }
    catch (e: Exception)
    {
        logger.warn("[FRC] Could not create Debugging Configuration for project '${project.name}' due to an exception: $e", e)
    }
}

class ModuleSettingAction(private val remoteConfiguration: RemoteConfiguration, val project: Project)
{
    private val logger = logger<ModuleSettingAction>()
    private var count = 0
    private val timer = Timer("Debugging Run Configuration Creation Pending Timer")

    fun run()
    {
        count++
        val mainModule = project.getMainModule()
        if (mainModule != null)
        {
            logger.debug {"[FRC] Main Module is available. Updating Configuration"}
            remoteConfiguration.setModule(mainModule)

        }
        else
        {
            logger.debug {"[FRC] Main module is not available yet. Run Count: $count   modules: ${project.getModules()}"}
            if (count <= 16)
            {
                logger.debug {"[FRC] Scheduling next check for 15 seconds"}
                timer.schedule(object : TimerTask()
                               {
                                   override fun run()
                                   {
                                       this@ModuleSettingAction.run()
                                   }

                               }, LocalDateTime.now().plus(Duration.ofSeconds(15)).asDate())
            } else
            {
                logger.debug {"[FRC] Max attempts reached"}
            }
        }
    }
}

@Suppress("UNUSED_PARAMETER")
private fun shareRunConfiguration(project: Project, settings: RunnerAndConfigurationSettings)
{
    // settings.isShared = true  <==  Old way, removed in b2021.3
    // Example from:  creating path:  com/intellij/execution/impl/RunConfigurationStorageUi.java:319
    //                applying it:    com/intellij/execution/impl/RunConfigurationStorageUi.java:394
    // it's the only place I could find setting/using the new .run directory
    
    // See comment in FrcModuleBuilder.callCreateRunConfigurations() about intermittent
    // "It's unexpected that the file doesn't exist at this point" issue
    
    val baseDir = project.basePath
    if (baseDir == null)
    {
        logger.warn("[FRC] Can't share run configurations because project.basePath was null")
        settings.storeInDotIdeaFolder()
    }
    else
    {
        // Switching to storing in `{baseDir}/.idea/runConfigurations`. When stored in `{baseDir}/.run`
        // they disappear form the Run/Debug drop down (and Gradle toolk window) upon a gradle reimport.
        // They are still present in the `{baseDir}/.run` directory, Burt do not show up in the menu.
        // This is an apparent bug in IDEA. Storing them in  `{baseDir}/.idea/runConfigurations` resolves this issue.
//        val dirPath = "$baseDir/.run"
//        val fileName = createRunConfigFileName(settings.name)
//        val filePath = "$dirPath/$fileName"
//        logger.debug{"[FRC] run config path set to: $filePath"}
//        settings.storeInArbitraryFileInProject(filePath)
        settings.storeInDotIdeaFolder()
    }
}

/** Creates a safe file name for a run config. This is a copy of the private `RunConfigurationStorageUi.getFileNameByRCName` method. */
private fun createRunConfigFileName(runConfigName: String): String = MODERN_NAME_CONVERTER.invoke(runConfigName) + ".run.xml"


@Suppress("unused")
fun determineNextName(project: Project, baseName:String, type: Class<out ConfigurationType>): String = determineNextName(RunManager.getInstance(project), baseName, type)

fun determineNextName(runManager: RunManager, baseName:String, type: Class<out ConfigurationType>): String = determineNextName(baseName, runManager.getConfigurationSettingsList(type))

fun determineNextName(baseName:String, configurationSettingsList: List<RunnerAndConfigurationSettings>): String
{
    val names = configurationSettingsList.map { it.name }

    return determineNextName(names, baseName)
}

fun determineNextName(names: List<String>, baseName: String): String
{
    val nameRegex = """${baseName}( \((\d*)\))?""".toRegex()
    val filteredList = names.filter { it.matches(nameRegex) }
    return if (filteredList.isEmpty())
    {
        baseName
    }
    else
    {
        val name = filteredList.maxOrNull() ?: ""
        val matchResult = nameRegex.matchEntire(name)
        if (matchResult == null)
        {
            baseName
        }
        else
        {
            val matchGroup = matchResult.groups[2]
            if (matchGroup == null)
            {
                "$baseName (1)"
            }
            else
            {
                val last = matchGroup.value.toInt()
                val next = last + 1
                "$baseName ($next)"
            }
        }
    }
}
