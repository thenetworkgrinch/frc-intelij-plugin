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

package net.javaru.iip.frc.wizard

import com.intellij.codeInsight.actions.DirectoryFormattingOptions
import com.intellij.codeInsight.actions.OptimizeImportsProcessor
import com.intellij.codeInsight.actions.ReformatCodeAction
import com.intellij.codeInsight.actions.TextRangeType
import com.intellij.ide.actions.ImportModuleAction
import com.intellij.ide.util.projectWizard.JavaModuleBuilder
import com.intellij.ide.util.projectWizard.ModuleBuilderListener
import com.intellij.ide.util.projectWizard.ModuleWizardStep
import com.intellij.ide.util.projectWizard.SdkSettingsStep
import com.intellij.ide.util.projectWizard.SettingsStep
import com.intellij.ide.util.projectWizard.WizardContext
import com.intellij.openapi.Disposable
import com.intellij.openapi.application.ReadConstraint
import com.intellij.openapi.components.Service
import com.intellij.openapi.components.service
import com.intellij.openapi.diagnostic.debug
import com.intellij.openapi.diagnostic.logger
import com.intellij.openapi.diagnostic.trace
import com.intellij.openapi.externalSystem.model.project.ProjectData
import com.intellij.openapi.externalSystem.model.project.ProjectId
import com.intellij.openapi.module.JavaModuleType
import com.intellij.openapi.module.ModifiableModuleModel
import com.intellij.openapi.module.Module
import com.intellij.openapi.module.ModuleType
import com.intellij.openapi.options.ConfigurationException
import com.intellij.openapi.progress.ProcessCanceledException
import com.intellij.openapi.project.DumbService
import com.intellij.openapi.project.Project
import com.intellij.openapi.projectRoots.Sdk
import com.intellij.openapi.projectRoots.SdkTypeId
import com.intellij.openapi.projectRoots.impl.JavaSdkImpl
import com.intellij.openapi.projectRoots.impl.ProjectJdkImpl
import com.intellij.openapi.roots.ModifiableRootModel
import com.intellij.openapi.roots.ui.configuration.ModulesProvider
import com.intellij.openapi.startup.StartupManager
import com.intellij.openapi.util.Condition
import com.intellij.openapi.util.Disposer
import com.intellij.openapi.util.io.FileUtil
import com.intellij.openapi.vfs.LocalFileSystem
import com.intellij.openapi.vfs.VfsUtil
import com.intellij.openapi.vfs.VirtualFile
import com.intellij.pom.java.LanguageLevel
import com.intellij.projectImport.ProjectImportProvider
import com.intellij.psi.PsiDirectory
import com.intellij.psi.PsiManager
import com.intellij.psi.search.SearchScope
import com.intellij.util.containers.ContainerUtil
import com.intellij.util.containers.stream
import com.intellij.util.io.HttpRequests
import com.intellij.util.lang.JavaVersion
import freemarker.template.Template
import icons.FrcIcons.FRC
import kotlinx.coroutines.CoroutineScope
import net.javaru.iip.frc.FrcPluginGlobals.DEFAULT_MIN_REQUIRED_JAVA_VERSION
import net.javaru.iip.frc.freemarker.FM_TEMPLATE_EXT_WITH_DOT
import net.javaru.iip.frc.freemarker.KOTLIN_FM_TEMPLATE_FILE_EXT
import net.javaru.iip.frc.freemarker.KOTLIN_SCRIPT_FM_TEMPLATE_FILE_EXT
import net.javaru.iip.frc.freemarker.freemarkerConfiguration
import net.javaru.iip.frc.freemarker.freemarkerConfigurationForKotlinTemplates
import net.javaru.iip.frc.run.RunDebugConfigsCreationData
import net.javaru.iip.frc.run.createAllRunDebugConfigurations
import net.javaru.iip.frc.settings.FrcApplicationSettings
import net.javaru.iip.frc.util.asPluginResourceUrl
import net.javaru.iip.frc.util.asPluginResourceVF
import net.javaru.iip.frc.util.findVirtualFile
import net.javaru.iip.frc.util.get
import net.javaru.iip.frc.util.getPluginResourceAsStream
import net.javaru.iip.frc.util.invokeLaterWait
import net.javaru.iip.frc.util.isValidJavaVersion
import net.javaru.iip.frc.util.isValidJdk
import net.javaru.iip.frc.util.letSafely
import net.javaru.iip.frc.util.reader
import net.javaru.iip.frc.util.reimportGradleProject
import net.javaru.iip.frc.util.removeBasePath
import net.javaru.iip.frc.util.runBackgroundTask
import net.javaru.iip.frc.util.toCommaDelimitedString
import net.javaru.iip.frc.wpilib.version.WpiLibVersion
import org.apache.commons.io.FileUtils
import org.apache.commons.io.FilenameUtils
import java.io.BufferedReader
import java.io.File
import java.io.InputStreamReader
import java.nio.file.Files
import java.nio.file.Path
import java.nio.file.Paths
import java.time.LocalDateTime
import java.time.ZoneId
import java.time.ZonedDateTime
import java.util.*
import java.util.concurrent.TimeUnit
import javax.swing.Icon

private const val gitignoreIoUrl = "https://www.toptal.com/developers/gitignore"
private const val frcWizardGitignoreDirName = "frc-wizard-gitignore"
private const val additionalCustomSuffix = "additionalCustom"

@Service(Service.Level.PROJECT)
@Suppress("NonDefaultConstructor")
class FrcModuleBuilderLightweightService(val project: Project, val coroutineScope: CoroutineScope)
{

}

class FrcModuleBuilder : JavaModuleBuilder(), ModuleBuilderListener
{
    private val mySdkChangedListeners: MutableList<Runnable> = ContainerUtil.createLockFreeCopyOnWriteList()
    private val fmStdConfiguration = freemarkerConfiguration(this, "/")
    private val fmKotConfiguration = freemarkerConfigurationForKotlinTemplates(this, "/")
    /**
     * Tracks the configured SDK since the `myJdk` property (in the super class `ModuleBuilder`) and the value in `WizardContext.getProjectJdk()` 
     * is not set until we pass the initial step. 
     * We need to be certain to keep this updated based on activities. A null value indicates not only that an SDK has not been selected,
     * but more likely a valid one (Type * Version) is not available in the listing.
     */
    var selectedSdk: Sdk? = null
        set(sdk) 
        {
            ourLogger.trace {"[FRC] selectedSdk setter called with value of '$sdk'  Previous value was '$field'"}
            if (field != sdk)
            {
                field = sdk
                for (runnable in mySdkChangedListeners)
                {
                    runnable.run()
                }
            }
        }
    
    private var myWizardContext: WizardContext? = null
    private var myParentProject: ProjectData? = null
//    private val myInheritGroupId = false
//    private val myInheritVersion = false
    private var myProjectId: ProjectId? = null
    private var rootProjectPath: Path? = null

    val dataModel = FrcProjectWizardData()

    // TODO: Can we make this an interface and an ExtensionPoint?
    @Suppress("MemberVisibilityCanBePrivate")
    class TemplatePaths(val version: WpiLibVersion)
    {
        /** The base 'templates' directory. For example `frc-wizard-templates/2020` for FRC year 2020.
         * In the event the directory of a year is not present, it will fall back to the latest year available. */
        val frcWizardTemplatesBaseDirPath: Path

        /** The `frc-wizard-templates` base templates directory as identified as  by the constant [frcWizardTemplatesDirName]. */
        val frcWizardTemplatesBaseDirVf: VirtualFile

        init
        {
            val frcWizardTemplatesDirPath = Paths.get(frcWizardTemplatesDirName)
            val frcWizardTemplatesDirVf = frcWizardTemplatesDirPath.asPluginResourceVF()

            if (frcWizardTemplatesDirVf == null)
            {
                val msg = "Cannot find FRC Wizard Templates Base Dir '$frcWizardTemplatesDirName' as plugin resource."
                ourLogger.warn("[FRC] $msg")
                throw ConfigurationException(msg)
            }


            var baseDirForWpiLibVersionPath = frcWizardTemplatesDirPath.resolve(version.frcYear.toString())
            var baseDirForWpiLibVersionVf = baseDirForWpiLibVersionPath.asPluginResourceVF()

            @Suppress("ThrowableNotThrown")
            if (baseDirForWpiLibVersionVf == null)
            {
                ourLogger.warn("[FRC] Cannot find FRC Wizard Templates Base Dir as resource for year ${version.frcYear}. Will use templates from latest available year.")
                val lastAvailableYear =
                    frcWizardTemplatesDirVf
                        .children
                        .stream()
                        .filter { it.isDirectory }
                        .map { it.name.toIntOrNull() }
                        .filter { it != null }
                        .mapToInt { it!! }
                        .max()
                        .orElseThrow { NoSuchElementException("No FRC child FRC year directories found in the FRC Wizard Templates directory '$frcWizardTemplatesDirName'") }

                baseDirForWpiLibVersionPath = frcWizardTemplatesDirPath.resolve(lastAvailableYear.toString())
                baseDirForWpiLibVersionVf = baseDirForWpiLibVersionPath.asPluginResourceVF()
            }

            if (baseDirForWpiLibVersionVf == null)
            {
                val msg = "Cannot find FRC Wizard Templates Base Dir (as plugin resource) for WPI Lib version '$version', nor can a template directory for any previous versions be found."
                ourLogger.warn("[FRC] $msg")
                throw ConfigurationException(msg)
            }

            frcWizardTemplatesBaseDirPath = baseDirForWpiLibVersionPath
            frcWizardTemplatesBaseDirVf = baseDirForWpiLibVersionVf
        }

        val defaultFilesResourceBasePath: Path = frcWizardTemplatesBaseDirPath.resolve(defaultFilesDirName)
        val gradleGroovyDslResourceBasePath: Path = defaultFilesResourceBasePath.resolve(gradleGroovyDslSubPath)
        val gradleKotlinDslResourceBasePath: Path = defaultFilesResourceBasePath.resolve(gradleKotlinDslSubPath)
        val gradleWrapperResourceBasePath: Path = defaultFilesResourceBasePath.resolve(gradleWrapperSubPath)
        val configsResourceBasePath: Path = defaultFilesResourceBasePath.resolve(configsSubPath)
        val extrasResourceBasePath: Path = defaultFilesResourceBasePath.resolve(extrasSubPath)
        val vsCodeConfigsResourceBasePath: Path = extrasResourceBasePath.resolve(vsCodeConfigsSubPath)
        val projectAutoGenReadMeResourceBasePath: Path = extrasResourceBasePath.resolve(projectAutoGenReadMeSubPath)
        val commonCodeResourceBasePath: Path = defaultFilesResourceBasePath.resolve(commonCodeSubPath)
        val javaCodeResourceBasePath: Path = defaultFilesResourceBasePath.resolve(javaCodeSubPath)
        val kotlinCodeResourceBasePath: Path = defaultFilesResourceBasePath.resolve(kotlinCodeSubPath)

        companion object
        {
            const val frcWizardTemplatesDirName = "frc-wizard-templates"
            /** Directory containing the shared/default files/templates. It's named in a way to stand out, and to be sorted to the top. */
            const val defaultFilesDirName = "-DEFAULT-FILES-"

            val gradleGroovyDslSubPath: Path = Paths.get("gradle/groovy-dsl")
            val gradleKotlinDslSubPath: Path = Paths.get("gradle/kotlin-dsl")
            val gradleWrapperSubPath: Path = Paths.get("gradle/gradle-wrapper")
            val configsSubPath: Path = Paths.get("configs")
            val extrasSubPath: Path = Paths.get("extras")
            val vsCodeConfigsSubPath: Path = Paths.get("vs-code-configs")
            val projectAutoGenReadMeSubPath: Path = Paths.get("project-auto-gen-readme")
            val commonCodeSubPath: Path = Paths.get("code/common-code")
            val javaCodeSubPath: Path = Paths.get("code/java-code")
            val kotlinCodeSubPath: Path = Paths.get("code/kotlin-code")
        }
    }


    override fun isAvailable(): Boolean = true

    override fun getGroupName(): String = MODULE_BUILDER_GROUP_NAME
    override fun getParentGroup(): String = JavaModuleType.JAVA_GROUP // This is the top group in the New Project Wizard, and for now it makes sense to be part of it

    /**
     * This is the name that appears (on the left) in the initial new project dialog where all the possible project/module types/options are shown.
     * The default in super is: `return getModuleTypeName()`.
     */
    override fun getPresentableName(): String = "FRC Robot Project"

    // The icon used (on the left) in the initial new project dialog where all the possible project types/options are shown
    override fun getNodeIcon(): Icon = FRC.FIRST_ICON_MEDIUM_16
    
    /**
     * Value that determines where in the list (within the Group) the module shows.
     * Higher numbers appear at the top, lower numbers at the bottom.
     * The items in IntelliJ IDEA Community are from top to bottom `Java`, `JavaFX`, `Android`, `IntelliJ Platform Plugin` 
     * The items in IntelliJ IDEA Ultimate are from top to bottom: (Dependent upon plugins installed) `Java`, `flexmark-java extension`, `Java Enterprise`, `JBoss`, `Spring`, JavaFX`, `Android`, `IntelliJ Platform Plugin`
     * We'll use 0 and get placed at the bottom, which I think is more consistent in the long run.
     */
    override fun getWeight(): Int = 0
    override fun getModuleType(): ModuleType<*>? = JavaModuleType.getModuleType()
    override fun getBuilderId(): String? = javaClass.name // This is critical since the default is to return the ModuleType's ID, which then results in the Java Wizard steps being used as our createWizardSteps() is never called.

    override fun createProject(name: String, path: String): Project?
    {
        ourLogger.trace {"[FRC] FrcModuleBuilder.createProject() called with name: $name and path: $path"}
        val project = super.createProject(name, path)
        ourLogger.trace {"[FRC] FrcModuleBuilder.createProject() completed. project: $project"}
        return project
    }


    override fun moduleCreated(module: Module)
    {
        // This method is from the ModuleBuilderListener
        ourLogger.trace {"[FRC] FrcModuleBuilder.moduleCreated() called and completed for module: ${module.name}"}
        // Module Configuration work could be done here
    }

    override fun setupModule(module: Module?)
    {
        // This implementation is heavily based on the impl in GradleModelBuilder, along with a bit from  the KtorModuleBuilder impl in the JetBrains ktor plugin
        ourLogger.trace {"[FRC] FrcModuleBuilder.setupModule() called for module: ${module?.name}"}
        super.setupModule(module) // this will call (our overridden) setupRootModel method
        callCreateRunConfigurations(module)
        ourLogger.trace {"[FRC] FrcModuleBuilder.setupModule() completed for module: ${module?.name}"}
    }


    private fun callCreateRunConfigurations(module: Module?)
    {
        val project = module?.project
        if (project != null)
        {
            callCreateRunConfigurations(project)
        }
        else
        {
            ourLogger.warn("[FRC] Could not create run debug configurations due to null module or project.")
        }
    }

    @Suppress("GrazieInspection")
    private fun callCreateRunConfigurations(project: Project)
    {
        ourLogger.trace {"[FRC] scheduling run configuration creation to runWhenProjectOpened."}
        /*
          To prevent the below logged warning from RCInArbitraryFileManager.loadChangedRunConfigsFromFile() (~line 97)
                "It's unexpected that the file doesn't exist at this point ($filePath)"
          We need wait until the project is opened, AND is not indexing
          Unfortunately it does still seem to happen intermittently on rare occasion
          I _think_ it might be a case of indexing finishes, our task starts, and then some more indexing starts?
          
          
          From some debugging, the issue happens when the project is initially importing
          A race condition occurs (if we do not wait)
          So we need to wait until the initial import is complete. But there does not
          appear to be a way to register a callback with the ImportModuleAction.createFromWizard()
          So we use the below coded construct, which seems to work fine.
          High level call stack (some intermediary methods not listed)
               RCInArbitraryFileManager.loadChangedRunConfigsFromFile()
               RunManagerImpl.deleteRunConfigsFromArbitraryFilesNotWithinProjectContent()
               RCInArbitraryFileManager.findRunConfigsThatAreNotWithinProjectContent()
               RunManagerImpl.findRunConfigsThatAreNotWithinProjectContent()
               ExternalSystemUtil.refreshProject()
               GradleOpenProjectProvider.attachGradleProjectAndRefresh()
               ImportModuleAction.createFromWizard()
               FrcModuleBuilder.importGradleProject()
         */

        StartupManager.getInstance(project).runAfterOpened {
            DumbService.getInstance(project).smartInvokeLater {
                // I've tried 'runWriteAction' and 'invokeLater' here, both outside and inside 'runWhenSmart'.
                // But the issue persisted. The smartInvokeLater has reduced its occurrence, but it still occurs occasionally.
                    createAllRunDebugConfigurations(RunDebugConfigsCreationData.create(dataModel, project))
                    project.reimportGradleProject()
            }
        }

        // This a messy hack to resolve the issue of the run/debug configs not always getting created. I *suspect* the proper solution is that we have
        // to implement code to handle the case of the above creation getting interrupted by indexing starting back up. Need to investigate this.
        class CreateTimeTask(private val id: Int, private val doReimport: Boolean): TimerTask() {
            override fun run()
            {
                try
                {
                    DumbService.getInstance(project).smartInvokeLater {
                        try
                        {
                            ourLogger.info("[FRC] 'Verify run/debug config creation' TimerTask $id firing")
                            createAllRunDebugConfigurations(RunDebugConfigsCreationData.create(dataModel, project))
                            if (doReimport) project.reimportGradleProject()
                        }
                        catch (e: Exception)
                        {
                            ourLogger.warn("[FRC] An exception occurred when smart invoking later the 'Verify run/debug config creation' via TimerTask $id. Cause: $e")
                            if (e is ProcessCanceledException) throw e
                        }
                    }
                }
                catch (e: Exception)
                {
                    ourLogger.warn("[FRC] Could not run 'Verify run/debug config creation' TimerTask $id. Cause: $e")
                    if (e is ProcessCanceledException) throw e
                }
            }
        }
        val timer = Timer("Verify run/debug config creation timer")
        // The first 2 should almost assuredly work, but we run additional to catch any lingering issues, but do not reimport as the user may be coding by then
        timer.schedule(CreateTimeTask( 1, doReimport = false),  TimeUnit.SECONDS.toMillis(30))
        timer.schedule(CreateTimeTask( 2, doReimport = false),  TimeUnit.SECONDS.toMillis(45))
        timer.schedule(CreateTimeTask( 3, doReimport = false),  TimeUnit.MINUTES.toMillis(1))
        timer.schedule(CreateTimeTask( 4, doReimport = false),  TimeUnit.MINUTES.toMillis(1) + TimeUnit.SECONDS.toMillis(15))
        timer.schedule(CreateTimeTask( 5, doReimport = false),  TimeUnit.MINUTES.toMillis(1) + TimeUnit.SECONDS.toMillis(30))
        timer.schedule(CreateTimeTask( 6, doReimport = false),  TimeUnit.MINUTES.toMillis(1) + TimeUnit.SECONDS.toMillis(45))
        timer.schedule(CreateTimeTask( 7, doReimport = false),  TimeUnit.MINUTES.toMillis(2))
        timer.schedule(CreateTimeTask( 8, doReimport = false), TimeUnit.MINUTES.toMillis(2) + TimeUnit.SECONDS.toMillis(15))
        timer.schedule(CreateTimeTask( 9, doReimport = false), TimeUnit.MINUTES.toMillis(2) + TimeUnit.SECONDS.toMillis(30))
        timer.schedule(CreateTimeTask(10, doReimport = false), TimeUnit.MINUTES.toMillis(2) + TimeUnit.SECONDS.toMillis(45))
        timer.schedule(CreateTimeTask(11, doReimport = false), TimeUnit.MINUTES.toMillis(3))
        timer.schedule(CreateTimeTask(12, doReimport = false), TimeUnit.MINUTES.toMillis(3) + TimeUnit.SECONDS.toMillis(15))
        timer.schedule(CreateTimeTask(13, doReimport = false), TimeUnit.MINUTES.toMillis(3) + TimeUnit.SECONDS.toMillis(30))
        timer.schedule(CreateTimeTask(14, doReimport = false), TimeUnit.MINUTES.toMillis(3) + TimeUnit.SECONDS.toMillis(45))
        timer.schedule(CreateTimeTask(15, doReimport = false), TimeUnit.MINUTES.toMillis(4))
        timer.schedule(CreateTimeTask(16, doReimport = false), TimeUnit.MINUTES.toMillis(5))
    }


    @Throws(ConfigurationException::class)
    override fun setupRootModel(rootModel: ModifiableRootModel)
    {
        // This implementation is heavily based on the impl in AbstractGradleModuleBuilder (v2019.3+, was previously GradleModelBuilder), along with a bit from the KtorModuleBuilder impl in the JetBrains ktor plugin
        // This method gets called by the setupModule method
        ourLogger.debug {"[FRC] FrcModuleBuilder.setupRootModel() called with template: '${dataModel.frcWizardTemplateDefinition.displayName}' from dir '${dataModel.frcWizardTemplateDefinition.templateResourcesDirName()}'"}
        ourLogger.trace {"[FRC] Data Model: $dataModel"}

        val modelContentRootDir = createAndGetRoot() ?: return
        val project = rootModel.project
        //val module = rootModel.module
        rootModel.addContentEntry(modelContentRootDir)
        if (myJdk != null) rootModel.sdk = myJdk else rootModel.inheritSdk()

        project.runBackgroundTask("Setting Up FRC Project") { progress ->
            progress.text = "Processing templates"

            rootProjectPath = if (myParentProject != null)
                Paths.get(myParentProject!!.linkedExternalProjectPath)
            else
                Paths.get(FileUtil.toCanonicalPath(if (myWizardContext!!.isCreatingNewProject) project.basePath else modelContentRootDir.path))
            assert(rootProjectPath != null) { "rootProjectPath is null" }

            copyTemplateFilesToProject(modelContentRootDir)

            progress.text = "Configuring project model"
            modelContentRootDir.refresh(false, true)

            if (FrcApplicationSettings.getInstance().enableGradleImportUponNewProjectCreation)
            {
                importGradleProject(modelContentRootDir, project)
            }

            // For now, we will only optimize imports and not reformat code style
//            if (FrcApplicationSettings.getInstance().isTeam3838() || dataModel.teamNumber == 3838) {

            // TODO: getSrcMainJavaPsiDirectory is causing intermittent slow operation exceptions: java.lang.Throwable: Slow operations are prohibited on EDT. See SlowOperations.assertSlowOperationsAreAllowed javadoc
            //       Initial attempts to resolve were unsuccessful. Need to rework the code.
            //       See Issue #152

//                getCoroutineScope(project).launch {
//                    runImportOptimizationOnly(project)
//                }


//            }
//            else {
//                getCoroutineScope(project).launch {
//                    runReformatCode(project)
//                }
//            }
            progress.text = "Done."
        }

        ourLogger.trace {"[FRC] FrcModuleBuilder.setupRootModel() completed"}
    }

    private suspend fun runImportOptimizationOnly(project: Project) {
        com.intellij.openapi.application.constrainedReadAndWriteAction(ReadConstraint.inSmartMode(project)) {
            val psiDirectory = getSrcMainJavaPsiDirectory(project)
            writeAction {
                ourLogger.debug("[FRC] Optimizing Imports (only) for new project $project")
                try
                {
                    val optimizer = OptimizeImportsProcessor(project, psiDirectory, true, false)
                    optimizer.run()
                }
                catch (e: ProcessCanceledException)
                {
                    throw e
                }
                catch (e: Throwable)
                {
                    ourLogger.debug { "[FRC] Could not optimize imports (only) for project $project. Cause Summary: $e" }
                }
            }
        }
    }

    @Suppress("unused")
    private suspend fun runReformatCode(project: Project)
    {
        com.intellij.openapi.application.constrainedReadAndWriteAction(ReadConstraint.inSmartMode(project)) {
            val psiDirectory = getSrcMainJavaPsiDirectory(project)
            writeAction {
                ourLogger.debug("[FRC] Reformatting code for new project $project")
                try
                {
                    ReformatCodeAction.reformatDirectory(project, psiDirectory, object : DirectoryFormattingOptions
                    {
                        override fun isOptimizeImports(): Boolean = true
                        override fun isRearrangeCode(): Boolean = false
                        override fun getTextRangeType(): TextRangeType = TextRangeType.WHOLE_FILE
                        override fun getFileTypeMask(): String? = null
                        override fun getSearchScope(): SearchScope? = null
                        override fun isIncludeSubdirectories(): Boolean = true
                    })
                    ourLogger.debug("[FRC] Reformat code completed for project $project")
                }
                catch (e: ProcessCanceledException)
                {
                    throw e
                }
                catch (e: Throwable)
                {
                    ourLogger.debug { "[FRC] Could not reformat code and optimize imports for project $project. Cause Summary: $e" }
                }
            }
        }
    }

    private fun getSrcMainJavaPsiDirectory(project: Project): PsiDirectory
    {
        val dirForReformatAction = rootProjectPath?.resolve("src/main/java") ?: throw IllegalStateException("rootProjectPath is null")
        val vf = dirForReformatAction.findVirtualFile(true) ?: throw IllegalStateException("could not find Virtual File for $dirForReformatAction")
        // TODO: This is causing intermittent slow operation exceptions: java.lang.Throwable: Slow operations are prohibited on EDT. See SlowOperations.assertSlowOperationsAreAllowed javadoc
        //       See Issue #152
        return PsiManager.getInstance(project).findDirectory(vf) ?: throw IllegalStateException("could not find PsiDirectory for $vf (from $dirForReformatAction)")
    }

    private suspend fun getSrcMainJavaPsiDirectoryInReadAction(project: Project): PsiDirectory
    {
        return com.intellij.openapi.application.smartReadAction(project) {
            getSrcMainJavaPsiDirectory(project)
        }
    }

    private fun getCoroutineScope(project: Project):  CoroutineScope = project.service<FrcModuleBuilderLightweightService>().coroutineScope

    override fun commitModule(project: Project, model: ModifiableModuleModel?): Module?
    {
        ourLogger.trace {"[FRC] FrcModuleBuilder.moduleCreated() called for project: ${project.name} for moduleModel $model"}
        val module = super.commitModule(project, model)
        ourLogger.trace {"[FRC] FrcModuleBuilder.moduleCreated() completed for project: ${project.name} for moduleModel $model"}
        return module
    }


    private fun copyTemplateFilesToProject(modelContentRootDir: VirtualFile)
    {
        /*
            We need to set up the following:
            A) The following are typically identical between templates
                1) Gradle
                    - nice to have would be to add dependencies such as logging
                    - Files:
                        a) build.gradle     (or build.gradle.kts)
                            - potentially modifiable
                            - will need to replace robot main class if we allow for alternate base package
                        b) settings.gradle  (or settings.gradle.kts)
                            - need to set frcYear (i.e. 2019, 2020, etc)
                            - set public folder?
                        c) gradlew
                        d) gradlew.bat
                        e) gradle/wrapper/gradle-wrapper.jar
                        f) gradle/wrapper/gradle-wrapper.properties
                2) .vscode
                    - this is a nice to have
                    - Files
                        a) .vscode/launch.json
                        b) .vscode/settings.json
                3) .wpilib
                    - Will have replacements for team number and project year
                    - Files:
                        a) wpilib_preferences.json

            B) Template Specific files:
                1) src/main/deploy/example.txt
                    - Same across all projects
                2) Main.java
                    - typically does not change per project
                    - A future nice to have would be to allow for a different "Robot" class name
                3) Robot.java
                    - differs per template
                4) Other Java classes and packages
        */

        val wpilibVersion = dataModel.wpilibVersion
        //TODO Need to enhance the calls to the defaults check if the template has overridden any of the default files
        val paths = TemplatePaths(wpilibVersion)
        paths.frcWizardTemplatesBaseDirPath.asPluginResourceVF()?.refresh(false, true)
        when(dataModel.gradleDslOption)
        {
            FrcProjectWizardData.GradleDslOption.GroovyDSL -> copyAllResourcesToModuleRoot("gradle - groovy DSL", modelContentRootDir, paths.gradleGroovyDslResourceBasePath)
            FrcProjectWizardData.GradleDslOption.KotlinDSL -> copyAllResourcesToModuleRoot("gradle - kotlin DSL", modelContentRootDir, paths.gradleKotlinDslResourceBasePath)
        }
        copyAllResourcesToModuleRoot("gradle wrapper", modelContentRootDir, paths.gradleWrapperResourceBasePath)

        val vendorDepsConfigsKeepFilter: (VirtualFile) -> Boolean =  {
            when
            {
                it.name.contains("frc-plugin-notes-README.txt") -> false
                it.name.contains("WPILibOldCommands") -> dataModel.frcWizardTemplateDefinition.commandVersion == 1
                it.name.contains("WPILibNewCommands") -> dataModel.frcWizardTemplateDefinition.commandVersion == 2
                it.name.contains("XRPVendordep")      -> dataModel.isXrpTemplate// include only if this is an XRP robot template
                it.name.contains("RomiVendordep")     -> dataModel.isRomiTemplate // include only if this is a Romi robot template
                // default to including/keeping the file, since this also covers configs/.wpilib/wpilib_preferences.json file, and others
                else -> true
            }
        }

        copyAllResourcesToModuleRoot("configs", modelContentRootDir, paths.configsResourceBasePath, keepFilter = vendorDepsConfigsKeepFilter)
        copyAllResourcesToModuleRoot("common code", modelContentRootDir, paths.commonCodeResourceBasePath)

        val codeResourceBasePath = when(dataModel.templateLanguageOption)
        {
           TemplateLanguageOption.Java -> paths.javaCodeResourceBasePath     // e.g. frc-wizard-templates/2023/-DEFAULT-FILES-/code/java-code
           TemplateLanguageOption.Kotlin -> paths.kotlinCodeResourceBasePath // e.g. frc-wizard-templates/2023/-DEFAULT-FILES-/code/kotlin-code
        }

        val languageSubPath = when (dataModel.templateLanguageOption)
        {
            TemplateLanguageOption.Java   -> TemplatePaths.javaCodeSubPath   // e.g. code/java-code
            TemplateLanguageOption.Kotlin -> TemplatePaths.kotlinCodeSubPath // e.g. code/kotlin-code
        }
        val selectedTemplateResourceBase = paths.frcWizardTemplatesBaseDirPath.resolve(dataModel.frcWizardTemplateDefinition.templateResourcesDirName()).resolve(languageSubPath)

        val templateHasUnitTests =  selectedTemplateResourceBase.asPluginResourceUrl().letSafely {
             VfsUtil.findFileByURL(it)?.findChild("src")?.findChild("test") != null
        } ?: false

        ourLogger.trace { "[FRC] templateLanguageOption: ${dataModel.templateLanguageOption} Using codeResourceBasePath: $codeResourceBasePath  Using selectedTemplateResourceBase: $selectedTemplateResourceBase " }

        val copyDefaultUnitTestFiles = if (templateHasUnitTests || dataModel.isExampleTemplate) false else dataModel.includeJUnitSupport
        val copyTemplateUnitTestFiles = if (templateHasUnitTests && dataModel.includeJUnitSupport) true else if (dataModel.isExampleTemplate) false else dataModel.includeJUnitSupport


        // COPY THE DEFAULT CODE FILES
        copyAllResourcesToModuleRoot("code : ${codeResourceBasePath.fileName}", modelContentRootDir, codeResourceBasePath, copyDefaultUnitTestFiles)

        // COPY VS CODE FILES
        if (dataModel.includeVsCodeConfigs)
        {
            copyAllResourcesToModuleRoot("vs-code-configs", modelContentRootDir, paths.vsCodeConfigsResourceBasePath)
        }

        // COPY README
        if (dataModel.frcWizardTemplateDefinition.includeAutoGenReadMe)
        {
            copyAllResourcesToModuleRoot("auto gen readme", modelContentRootDir, paths.projectAutoGenReadMeResourceBasePath)
        }

        // CREATE .gitignore FILE
        if (dataModel.gitIgnoreConfiguration.includeGitIgnoreFile)
        {
            try
            {
                val gitIgnoreContent = generateGitIgnoreFileContent(dataModel.gitIgnoreConfiguration)
                val file = Paths.get(modelContentRootDir.path).resolve(".gitignore")
                Files.newBufferedWriter(file, Charsets.UTF_8).use { it.write(gitIgnoreContent) }
            } catch (e: Exception)
            {
                ourLogger.warn("[FRC] Unable to create .gitignore file due to an exception: $e", e)
            }
        }

        // COPY THE TEMPLATE FILES
        copyAllResourcesToModuleRoot("selected template files - $languageSubPath", modelContentRootDir, selectedTemplateResourceBase, copyTemplateUnitTestFiles)
    }


    private fun importGradleProject(modelContentRootDir: VirtualFile, project: Project)
    {
        // Primarily copied from KtorModuleBuilder in Ktor plugin
        val gradleBuildVf = modelContentRootDir["build.gradle.kts"] ?: modelContentRootDir["build.gradle"]
        if (gradleBuildVf == null)
        {
            ourLogger.info("[FRC] gradle import not executed as build.gradle/build.gradle.kts was not found ")
        }
        else
        {
            ourLogger.trace {"[FRC] preparing for gradle import"}
            invokeLaterWait {
                ourLogger.trace {"[FRC] gradle import lambda starting"}

                val provider = ProjectImportProvider.PROJECT_IMPORT_PROVIDER.extensions
                    .firstOrNull { it.canImport(gradleBuildVf, project) }
                    ?: return@invokeLaterWait

                val wizard = ImportModuleAction.createImportWizard(project, null, gradleBuildVf, provider)
                if (wizard != null && (wizard.stepCount <= 0 || wizard.showAndGet()))
                {
                    ImportModuleAction.createFromWizard(project, wizard)
                }
                ourLogger.trace {"[FRC] gradle import lambda finished"}
            }
            ourLogger.trace {"[FRC] gradle import prep completed"}
        }
    }


    /**
     * @param copyUnitTestFiles Whether files contained in any `src/test` subdirectory, if present, should be copied.
     */
    private fun copyAllResourcesToModuleRoot(
        resourceDescription: String,
        modelContentRootDir: VirtualFile,
        resourceDirBase: Path,
        copyUnitTestFiles: Boolean = dataModel.includeJUnitSupport,
        keepFilter: (VirtualFile) -> Boolean = { true }
                                            )
    {
        val pluginResourceDirUrl = resourceDirBase.asPluginResourceUrl()
        ourLogger.debug {"[FRC] copyAllResourcesToModuleRoot for: $resourceDescription\n        resourceDirBase = $resourceDirBase\n        pluginResourceDir URL = $pluginResourceDirUrl"}

        if (pluginResourceDirUrl == null)
        {
            ourLogger.warn("[FRC] Could  not find resourceDir '$resourceDirBase' for 'copy all template files' operation.")
        }
        else
        {
            val srcFqBaseDir = VfsUtil.findFileByURL(pluginResourceDirUrl)
            if (srcFqBaseDir == null)
            {
                ourLogger.warn("[FRC] Could not convert URL '$pluginResourceDirUrl' to a VirtualFile for 'copy all wizard template files' operation.")
            }
            else
            {
                ourLogger.debug("[FRC] Processing srcFqBaseDir of: ${srcFqBaseDir.path}")
                srcFqBaseDir.refresh(false, true)
                VfsUtil.collectChildrenRecursively(srcFqBaseDir)
                    .filter { !it.isDirectory }
                    // Don't copy test files if junit is not enabled
                    .filter { if (copyUnitTestFiles) true else !it.path.contains("""src[/\\]test""".toRegex()) }
                    .filter { keepFilter.invoke(it) }
                    .forEach {
                    val resourceRelativePath = Paths.get(it.toString().removePrefix("$srcFqBaseDir")).removeBasePath(Paths.get("/"))
                    // We refresh to resolve an issue where the source file is cached by IntelliJ IDEA, even after a restart, and we get the old content
                    // We probably only need to do this when testing since a new plugin release would have a new jar file name… and IntelliJ *should*
                    // see that as a new file as its full path would be different. But since this is in the new project wizard, and thus is only used
                    // occasionally, the slight performance hit is worth the complete assurance of using the most recent file
                    it.refresh(false, true)
                    if (resourceRelativePath.fileName.toString().endsWith(FM_TEMPLATE_EXT_WITH_DOT))
                        copyFreemarkerTemplate(modelContentRootDir, it, srcFqBaseDir)
                    else
                        copyNonTemplateFile(modelContentRootDir, it, srcFqBaseDir)
                }
            }
        }
    }

    
    private fun copyNonTemplateFile(modelContentRootDir: VirtualFile, srcFqVf: VirtualFile, srcFqBaseDir: VirtualFile): VirtualFile?
    {
        return try
        {
            val endPath = Paths.get(srcFqVf.toString().removePrefix("$srcFqBaseDir")).removeBasePath(Paths.get("/"))
            val target = resolveTargetPath(modelContentRootDir, endPath)
            Files.createDirectories(target.parent)
            val file = target.toFile()

            FileUtils.copyInputStreamToFile(srcFqVf.inputStream, file)
            LocalFileSystem.getInstance().refreshAndFindFileByIoFile(file)
        } catch (e: Exception)
        {
            ourLogger.warn("[FRC] Could not copy new project wizard file '$srcFqVf' to new project root '${modelContentRootDir}' exception: $e", e)
            null
        }
    }
    
    
    private fun copyFreemarkerTemplate(modelContentRootDir: VirtualFile, srcFqVf: VirtualFile, srcFqBaseDir: VirtualFile)
    {
        try
        {
            srcFqBaseDir.refresh(false, false)
            val srcEndPath = Paths.get(srcFqVf.toString().removePrefix("$srcFqBaseDir")).removeBasePath(Paths.get("/"))
            val fmTemplateName = srcEndPath.fileName.toString()
            val targetEndPath = srcEndPath.resolveSibling(fmTemplateName.removeSuffix(FM_TEMPLATE_EXT_WITH_DOT))
            val target = resolveTargetPath(modelContentRootDir, targetEndPath)
            // name ==> The path of the template file relatively to the (virtual) directory that you use to store the templates
            val name = FilenameUtils.separatorsToUnix(srcEndPath.toString())!!
            val template =
                if (fmTemplateName.isKotlinTemplate())
                    Template(name, srcFqVf.reader(), fmKotConfiguration)
                else
                    Template(name, srcFqVf.reader(), fmStdConfiguration)
            processFreemarkerTemplate(template, target)
        }
        catch (e: Exception)
        {
            ourLogger.warn("[FRC] Could not copy new project wizard template file '$srcFqVf' to new project root '${modelContentRootDir}' exception: $e", e)
        }
    }

    private fun String.isKotlinTemplate(): Boolean = this.endsWith(KOTLIN_FM_TEMPLATE_FILE_EXT) || this.endsWith(KOTLIN_SCRIPT_FM_TEMPLATE_FILE_EXT)
    
    private fun processFreemarkerTemplate(fmTemplate: Template, target: Path): VirtualFile?
    {
        try
        {
            Files.createDirectories(target.parent)
            Files.newBufferedWriter(target, Charsets.UTF_8).use {
                val environment = fmTemplate.createProcessingEnvironment(hashMapOf("data" to dataModel), it)
                environment.outputEncoding = Charsets.UTF_8.toString()
                environment.locale = Locale.ENGLISH
                environment.process()
            }
            return LocalFileSystem.getInstance().refreshAndFindFileByIoFile(target.toFile())
        }
        catch (e: Exception)
        {
            ourLogger.warn("'[FRC] Could not process new project wizard freemarker template '${fmTemplate.sourceName}' to destination '$target' due to the exception: $e", e)
            return null
        }
    }

    private fun resolveTargetPath(modelContentRootDir: VirtualFile, targetRelativePath: Path): Path
    {
        val target = VfsUtil.virtualToIoFile(modelContentRootDir).toPath().resolve(targetRelativePath)
        return normalizeTargetPathWithPackageDir(target)
    }


    private fun normalizeTargetPathWithPackageDir(target: Path): Path
    {
        val basePackage = "base-package/"
        val pathString = FilenameUtils.separatorsToUnix(target.toString())
        return if (pathString.contains(basePackage))
        {
            val normalizedPathString: String = if (dataModel.basePackage.isEmpty())
            {
                val start = pathString.indexOf(basePackage)
                val end = start + basePackage.length
                pathString.removeRange(start, end)
            }
            else
            {
                pathString.replace(basePackage, "${FilenameUtils.separatorsToUnix(dataModel.basePackageAsDirString)}/")
            }

            Paths.get(normalizedPathString)
        }
        else
        {
            target
        }
    }
    

    private fun createAndGetRoot(): VirtualFile?
    {
        val path = contentEntryPath?.let { FileUtil.toSystemIndependentName(it) } ?: return null
        return LocalFileSystem.getInstance().refreshAndFindFileByPath(File(path).apply { mkdirs() }.absolutePath)
    }


    private fun generateGitIgnoreFileContent(config: GitIgnoreConfiguration): String
    {
        val (toptalTemplates: MutableList<String>, wpilibTemplates: MutableList<String>, manualEntries: StringBuilder) = extractGitIgnoreTemplates(config)
        val content = StringBuilder()
        
        if(toptalTemplates.isNotEmpty())
        {
            var createFromCache = !config.generateFromSite
            if (!createFromCache)
            {
                try
                {
                    //val url = "https://gitignore.io/api/${templates.toCommaDelimitedString(false)}"
                    val url = "$gitignoreIoUrl/api/${toptalTemplates.toCommaDelimitedString(false)}"
                    val request1 = HttpRequests.request(url)
                    val responseBody = request1.readString()
                    content.appendLine("# Dynamically generated by IntelliJ IDEA FRC Plugin on ${java.time.format.DateTimeFormatter.ofPattern("EEEE MMMM d, yyyy h:mm:ss a zzz").format(ZonedDateTime.of(LocalDateTime.now(), ZoneId.systemDefault()))}")
                    content.appendLine("# using $gitignoreIoUrl/api (See https://docs.gitignore.io)")
                    content.appendLine(responseBody)
                }
                catch (e: Exception)
                {
                    // TODO: we need to notify the user that the gitignore was not generated from the site and therefore may be out of date: https://gitlab.com/Javaru/frc-intellij-idea-plugin/-/issues/72
                    ourLogger.warn("[FRC] An exception occurred when attempting to dynamically create .gitignore file from gitignore APT at $gitignoreIoUrl/api. Will generate from cache. Cause Summary: $e", e)
                    createFromCache = true
                }
            }

            if (createFromCache)
            {
                content.clear()
                content.appendLine(generateGitIgnoreSiteContentFromCachedFiles(toptalTemplates, config.additionalGitignoreTemplates))
            }

            // Add any additionalCustom content in bulk
            content.appendLine()
            content.appendLine("# Additional entries for previous types")
            toptalTemplates.forEach { templateName ->
                writeTemplateToContentBuilder("$frcWizardGitignoreDirName/$templateName-${additionalCustomSuffix}.txt", content, logWarnIfNotExist = false)
            }
            content.appendLine("# End of additional entries")
            content.appendLine()
        }
        
        if (manualEntries.isNotBlank())
        {
            content.appendLine("# === Entries from IntelliJ IDEA FRC Plugin New FRC Project Wizard ===")
            content.appendLine()
            content.append(manualEntries)
            content.appendLine()
            content.appendLine()
            content.appendLine("# End entries from IntelliJ IDEA FRC Plugin")
            content.appendLine()
        }

        if (config.wpilib && wpilibTemplates.isNotEmpty())
        {
            content.appendLine("# === Entries from WPI Lib team ===")
            content.appendLine("# The following gitignore entries have been specially created by the WPI Lib development team.")
            content.appendLine()
            wpilibTemplates.processTemplateList(content)
            content.appendLine("# End entries from WPI Lib team")
            content.appendLine()
        }
        
        return content.toString()
    }

   
    private fun generateGitIgnoreSiteContentFromCachedFiles(templates: MutableList<String>, additionalTemplates: List<String>): String
    {
        val filteredTemplates = templates.filterNot { additionalTemplates.contains(it) }
        val templatesString = filteredTemplates.toCommaDelimitedString(false)
        val content = StringBuilder()

        content.appendLine()
        content.appendLine("# Created by $gitignoreIoUrl/api/$templatesString")
        content.appendLine("# Edit at    $gitignoreIoUrl?templates=$templatesString")
        content.appendLine()
        filteredTemplates.sorted().processTemplateList(content)
        content.appendLine()
        content.appendLine("# End of $gitignoreIoUrl/api/$templatesString")
        content.appendLine()
        content.appendLine()
        
        return content.toString()
    }

    private fun List<String>.processTemplateList(content: StringBuilder)
    {
        forEach { templateName ->
            writeTemplateToContentBuilder("$frcWizardGitignoreDirName/$templateName.txt", content, logWarnIfNotExist = true)
        }
    }

    private fun writeTemplateToContentBuilder(templatePath: String, content: StringBuilder, logWarnIfNotExist: Boolean = true)
    {
        val inputStream = getPluginResourceAsStream(templatePath)
        if (inputStream == null)
        {
            if (logWarnIfNotExist) ourLogger.warn("[FRC] could not find gitignore cached template '${templatePath}' in plugin resources")
        }
        else
        {
            inputStream.use { innerStream ->
                val reader = BufferedReader(InputStreamReader(innerStream, Charsets.UTF_8))
                reader.lines().forEach { line: String? ->
                    content.appendLine(line)
                }
            }
            content.appendLine()
        }
    }

    private data class GitIgnoreTemplates(
        val toptalGitIgnoreTemplates: MutableList<String>,
        val wpilibGitIgnoreTemplates: MutableList<String>,
        val manualEntries: StringBuilder
    )

    private fun extractGitIgnoreTemplates(config: GitIgnoreConfiguration): GitIgnoreTemplates
    {
        val manualEntries = StringBuilder()
        val toptalTemplates = mutableListOf<String>()
        val wpilibTemplates = mutableListOf<String>()

        if (config.java) toptalTemplates.add("java") 
        if (config.gradle) toptalTemplates.add("gradle")


        when (config.intellij)
        {
            IdeConfigOption.Share   -> toptalTemplates.add("intellij+iml")
            IdeConfigOption.Ignore  -> toptalTemplates.add("intellij+all")
            IdeConfigOption.NoEntry -> { /* Do nothing */ }
        }

        @Suppress("SpellCheckingInspection")
        when (config.vscode)
        {
            IdeConfigOption.Share   -> toptalTemplates.add("visualstudiocode")
            IdeConfigOption.Ignore  -> {
                val inputStream = getPluginResourceAsStream("$frcWizardGitignoreDirName/visualstudiocode.txt")
                if (inputStream == null)
                {
                    ourLogger.warn("[FRC] could not find the '$frcWizardGitignoreDirName/visualstudiocode.txt' file in plugin resources")
                }
                else
                {
                    inputStream.use { innerStream ->
                        val reader = BufferedReader(InputStreamReader(innerStream, Charsets.UTF_8))
                        reader
                            .lines()
                            .filter{  line -> !line.startsWith("!.vscode/") }
                            .forEach{  manualEntries.appendLine(it) }
                    }
                }
            }
            IdeConfigOption.NoEntry -> {
                //if (config.wpilib) wpilibTemplates.add("wpilib-java")
            }
        }

        //For now, we are using boolean checkboxes for Eclipse and NetBeans rather than selecting as an IdeConfigOption
        if (config.eclipse.asBoolean()) toptalTemplates.add("eclipse")
        if (config.netbeans.asBoolean()) toptalTemplates.add("netbeans")
        if (config.linux) toptalTemplates.add("linux")
        if (config.macOS) toptalTemplates.add("macos")
        if (config.windows) toptalTemplates.add("windows")
        if (config.cpp) toptalTemplates.add("c++")

        if (config.wpilib) {
            wpilibTemplates.add("wpilib")
        }

        toptalTemplates.addAll(config.additionalGitignoreTemplates)

        return GitIgnoreTemplates(toptalTemplates, wpilibTemplates, manualEntries)
    }
    

    override fun createWizardSteps(wizardContext: WizardContext, modulesProvider: ModulesProvider): Array<ModuleWizardStep>
    {
        ourLogger.trace {"[FRC] FrcModuleBuilder.createWizardSteps() called"}
        myWizardContext = wizardContext
        // These are the steps that come after the initial "built-in" step. 
        // The FrcInitialCustomOptionsWizardStep shows as a pane in the initial built-in step
        ourLogger.trace {"[FRC] FrcModuleBuilder.createWizardSteps() completed"}
        return arrayOf(FrcTemplateSelectionWizardStep(this, wizardContext),
                       FrcProjectSettingsWizardStep(this, wizardContext))
    }


    fun setParentProject(parentProject: ProjectData?) { myParentProject = parentProject }


    var projectId: ProjectId?
        get() = myProjectId
        set(projectId)
        {
            myProjectId = projectId
        }

    /**
     * Custom UI to be shown on the first wizard page
     *
     * @param context
     * @param parentDisposable
     */
    override fun getCustomOptionsStep(context: WizardContext, parentDisposable: Disposable): ModuleWizardStep
    {
        // This *normally* determines the potential frameworks  that can be selected (like kotlin, groovy, Thymeleaf, Ruby, etc., etc., etc.)
        //     Notice that when setProviders is called  "java" is set for the "preselected" parameter    In IDEA project: service/project/wizard/GradleFrameworksWizardStep.java:99 as well as  service/project/wizard/GradleFrameworksWizardStep.java:91 for the Kotlin DSL
        //     Others are dynamically loaded via extension point definitions as far as I can tell.
        // Normally this is where we would put the option to select Kotlin
        //     But since we are just adding something to build.gradle.ftl template and not anything more sophisticated (i.e. having to set things),
        //     and we want to auto add Kotlin if a Kotlin template is selected, we will do this in a later step via a simple check box
        //   
        // It looks like typically  these can be defined/configured via an extension is the plugin.xml
        //     For example with Gradle, there is:
        //           <frameworkSupport implementation="org.jetbrains.plugins.gradle.frameworkSupport.GradleGroovyFrameworkSupportProvider"/>
        //     in the gradle-groovy-integration.xml file.
        //     in turn that file is defined as an optional depends on the gradle-java-integration.xml file when defining "org.intellij.groovy" as an (optional) dependency
        //     this would allow other plugins to add frameworks for a project type. Note something we need to worry about
        // So..... with all that said, we are not going to do a traditional "FrameworksWizardStep" or even an "options step",
        //     but rather a fairly simple "show some information" step
        ourLogger.trace {"[FRC] FrcModuleBuilder.getCustomOptionsStep() called"}
        val step = FrcInitialCustomOptionsWizardStep(this, context)
        Disposer.register(parentDisposable, step)
        ourLogger.trace {"[FRC] FrcModuleBuilder.getCustomOptionsStep() completed"}
        return step
    }

    override fun modifyProjectTypeStep(settingsStep: SettingsStep): ModuleWizardStep
    {
        // Implementation based on to the following forum answer:
        //     https://intellij-support.jetbrains.com/hc/en-us/community/posts/360006464099-Valdating-slected-Project-SDK-version-on-the-first-wizard-page?page=1#community_comment_360000894059
        //     Please see:                   com.jetbrains.python.module.PythonModuleBuilder#modifyProjectTypeStep 
        //     and implement your logic in:  com.intellij.ide.util.projectWizard.SdkSettingsStep#onSdkSelected

        // The parent ModuleBuilder class also has the  `boolean isSuitableSdkType(SdkTypeId sdkType)`  method, but that is limited to the type, so no version info
        
        // We apply filters so that only JDKs that meet the required version level show in the "Project SDK" drop down list
        ourLogger.trace {"[FRC] FrcModuleBuilder.modifyProjectTypeStep() Executing"}
        return object : SdkSettingsStep(settingsStep, 
                                        this, 
                                        Condition { id: SdkTypeId -> JavaSdkImpl.getInstance() === id },
                                        Condition {  sdk:Sdk -> (sdk as ProjectJdkImpl).isValidJavaVersion(DEFAULT_MIN_REQUIRED_JAVA_VERSION)})
        {
            override fun onSdkSelected(sdk: Sdk?)
            {
                // this gets called when ever the selected SDK changes, including when the new project wizard is first opened (and FRC project is selected because it was last used)
                // So we don't want to pop up a (modal) dialog. But we can set an internal "selected SDK tracking" property and then use that value in the validate method
                // If no valid JDK is available in the list (after filtering), this method is simply NOT called. (i.e. it is not called with a null value)
                @Suppress("SpellCheckingInspection")
                ourLogger.debug {"[FRC] onSdkSelected called with sdk: sdk='$sdk' [type='${sdk?.sdkType}' version='${sdk?.versionString}' name = '${sdk?.name}'  homePath = '${sdk?.homePath}' sdkModificator = '${sdk?.sdkModificator}'"}
                selectedSdk = sdk
            }
        }
    }

    fun addSdkChangedListener(runnable: Runnable?)
    {
        if (runnable != null)
        {
            mySdkChangedListeners.add(runnable)
        }
    }

    fun isSelectedSdkValid(): Boolean = selectedSdk.isValidJdk(getRequiredJdkVersionForWpiLibVersion())

    fun getRequiredJdkVersionForWpiLibVersion(): JavaVersion = when
    {
        // TODO: Issue #53 - It'd be nice to determine this dynamically. But ultimately there may not be a clean way.
        //       We could potentially look at the version in the Gradle Te,plate
        // Also update 'frc.ui.wizard.sdkRequirement.text' message key
        dataModel.frcYear <= 2023 -> LanguageLevel.JDK_11.toJavaVersion()
        else                      -> LanguageLevel.JDK_17.toJavaVersion()
    }

    companion object
    {
        private val ourLogger = logger<FrcModuleBuilder>()
    }
}