/*
 * Copyright 2015-2021 the original author or authors.
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

package net.javaru.iip.frc.services

import com.intellij.facet.Facet
import com.intellij.facet.FacetManager
import com.intellij.facet.FacetManagerListener
import com.intellij.ide.util.RunOnceUtil
import com.intellij.openapi.Disposable
import com.intellij.openapi.components.service
import com.intellij.openapi.diagnostic.debug
import com.intellij.openapi.diagnostic.logger
import com.intellij.openapi.diagnostic.trace
import com.intellij.openapi.module.Module
import com.intellij.openapi.project.DumbService
import com.intellij.openapi.project.ModuleListener
import com.intellij.openapi.project.Project
import com.intellij.openapi.project.guessProjectDir
import com.intellij.openapi.roots.ModuleRootEvent
import com.intellij.openapi.roots.ModuleRootListener
import com.intellij.openapi.application.invokeLater
import com.intellij.openapi.startup.ProjectActivity
import com.intellij.openapi.vfs.VirtualFile
import com.intellij.util.messages.MessageBusConnection
import net.javaru.iip.frc.facet.isFrcFacet
import net.javaru.iip.frc.facet.isFrcFacetedModule
import net.javaru.iip.frc.facet.isFrcFacetedProject
import net.javaru.iip.frc.notify.FrcNotificationsTracker
import net.javaru.iip.frc.notify.FrcNotifyType
import net.javaru.iip.frc.notify.notifyToConfigureTeamNumIfNecessary
import net.javaru.iip.frc.riolog.RioLogProjectService
import net.javaru.iip.frc.run.ensureRunDebugConfigurationsCreated
import net.javaru.iip.frc.run.ensureWpiLibSimulationRunConfigurations
import net.javaru.iip.frc.riolog.udp.RioLogUdpSocketManagerApplicationService
import net.javaru.iip.frc.settings.FrcProjectTeamNumberService
import net.javaru.iip.frc.toolWindow.VendordepsToolWindowFactory
import net.javaru.iip.frc.wpilib.ensureGradleJvmIsWpiLibJdk
import net.javaru.iip.frc.wpilib.isWpiLibProject
import net.javaru.iip.frc.wpilib.isWpiLibProjectLayoutPath
import net.javaru.iip.frc.wpilib.syncFrcFacetWithWpiLibDetection
import com.intellij.openapi.vfs.VirtualFileManager
import com.intellij.openapi.externalSystem.service.project.manage.ProjectDataImportListener
import net.javaru.iip.frc.util.getMainModule
import net.javaru.iip.frc.util.isJavaPluginAvailable
import com.intellij.openapi.vfs.newvfs.BulkFileListener
import com.intellij.openapi.vfs.newvfs.events.VFileEvent
import javax.annotation.CheckForNull
import kotlin.io.path.isRegularFile
import kotlin.io.path.readText


// Do NOT make a StartupActivity.Background since we want indexing to be complete
class FrcProjectLifecycleService private constructor(val project: Project) : ModuleRootListener,
                                                                             ModuleListener,
                                                                             Disposable,
                                                                             FacetManagerListener
{
    private val logger = logger<FrcProjectLifecycleService>()


    companion object
    {
        @Suppress("RemoveExplicitTypeArguments")
        @JvmStatic
        fun getInstance(project: Project): FrcProjectLifecycleService = project.service<FrcProjectLifecycleService>()
    }

    internal fun registerListeners()
    {
        logger.trace {"[FRC] FrcProjectLifecycleService.registerListeners() called for project '$project'"}
        val connection: MessageBusConnection = project.messageBus.connect()
        connection.subscribe(ModuleListener.TOPIC, this)
        connection.subscribe(ModuleRootListener.TOPIC, this)
        connection.subscribe(FacetManager.FACETS_TOPIC, this)
        // A project's WPILib status is determined solely by its '.wpilib/wpilib_preferences.json' file, so react to that file being created or deleted
        // The FRC facet is added once the Gradle import completes, since the import replaces the modules
        connection.subscribe(ProjectDataImportListener.TOPIC, object : ProjectDataImportListener
        {
            override fun onImportFinished(projectPath: String?)
            {
                invokeLater { onWpiLibProjectStatusMaybeChanged() }
            }
        })
        connection.subscribe(VirtualFileManager.VFS_CHANGES, object : BulkFileListener
        {
            override fun after(events: List<VFileEvent>)
            {
                if (events.any { isWpiLibProjectLayoutPath(it.path) }) invokeLater { onWpiLibProjectStatusMaybeChanged() }
            }
        })
    }

    /**
     * Updates everything that depends on whether the project is a WPILib project: the FRC facet, the RioLog console, the
     * Vendordeps tool window, and the run configurations. Must be called on the EDT.
     */
    private fun onWpiLibProjectStatusMaybeChanged()
    {
        if (!project.isOpen || project.isDisposed) return
        project.syncFrcFacetWithWpiLibDetection()
        RioLogProjectService.getInstance(project).update()
        VendordepsToolWindowFactory.updateAvailability(project)
        if (project.isWpiLibProject())
        {
            ensureWpiLibProjectSetUp()
        }
    }



    /** Creates the run configurations, and sets the Gradle JVM, of a WPILib project. */
    private fun ensureWpiLibProjectSetUp()
    {
        // The run configurations (Java simulation, remote debugging, etc.) require the Java plugin, which is not available in CLion
        if (isJavaPluginAvailable)
        {
            ensureRunDebugConfigurationsCreated(project)
            ensureWpiLibSimulationRunConfigurations(project)
        }
        ensureGradleJvmIsWpiLibJdk(project)
    }

    internal fun runFrcProjectStartupActivities(project: Project)
    {
        // Projects should be fully initialized at this point (per JavaDoc in StartupActivity)
        // The RioLog is always shown for WPILib projects, including those detected by their file layout before the Gradle import adds the FRC facet
        // For a project that has already been imported (otherwise the facet is added when the Gradle import completes)
        invokeLater { if (project.isOpen && !project.isDisposed && project.getMainModule() != null) project.syncFrcFacetWithWpiLibDetection() }
        if (project.isOpen && !project.isDisposed && project.isWpiLibProject())
        {
            RioLogProjectService.getInstance(project).update()
            ensureWpiLibProjectSetUp()
        }

        if (project.isOpen && project.isFrcFacetedProject() && !project.isDisposed)
        {
            // FYI: The FrcPluginVersionManagerStartupActivity also does some notification work

            // initialize the registering of the VFS Change Listener so we can detect changes to the project team number
            FrcProjectTeamNumberService.getInstance(project)

            notifyToConfigureTeamNumIfNecessary(project, true)

            checkProjectFrcStatus(project, knownFacetedProject = true, checkTeamNumConfigStatus = false)

            checkForOldKotlinDslFile()
        }
    }

    override fun dispose() // This is basically our projectClosed() method
    {
        logger.trace {"[FRC] FrcProjectLifecycleService.dispose() called for project '$project'"}
        FrcNotificationsTracker.clearAllForProject(project)
        service<RioLogUdpSocketManagerApplicationService>().deregister(project)
    }

    /**
     * Once a WPILib project's modules exist (e.g. after the Gradle import), creates the simulation run configurations if needed.
     * This is not tied to the FRC facet, which may not be added for some projects (e.g. 2027 projects).
     */
    override fun rootsChanged(event: ModuleRootEvent)
    {
        invokeLater {
            if (project.isOpen && !project.isDisposed)
            {
                if (project.isWpiLibProject())
                {
                    ensureWpiLibProjectSetUp()
                }
            }
        }
    }

    override fun modulesAdded(project: Project, modules: MutableList<out Module>)
    {
        logger.trace {"[FRC] FrcProjectLifecycleService.moduleAdded() called for modules '$modules' on project '$project'"}
        // We only want to update the RioLogConsole if the project is fully opened. In other words, this is a
        // case where the user is adding a module to an open project rather than this moduleAdded() method being
        // called as part of the initial project loading when opening a project. In the latter case, the
        // RioLogProjectService.update() is called via the ProjectComponent.projectOpened() method
        // We only want to update the RioLogConsole if the project is fully opened. In other words, this is a
        // case where the user is adding a module to an open project rather than this moduleAdded() method being
        // called as part of the initial project loading when opening a project. In the latter case, the
        // RioLogProjectService.update() is called via the ProjectComponent.projectOpened() method
        modules.forEach {
            if (it.project.isOpen && it.isFrcFacetedModule() && !it.isDisposed && !it.project.isDisposed)
            {
                RioLogProjectService.getInstance(it.project).update()
            }
        }
    }

    override fun beforeModuleRemoved(project: Project, module: Module)
    {
        logger.trace {"[FRC] FrcProjectLifecycleService.beforeModuleRemoved() called for module '$module'"}
        if (module.isFrcFacetedModule() && !module.isDisposed)
        {
            RioLogProjectService.getInstance(module.project).update()
        }
    }

    override fun moduleRemoved(project: Project, module: Module)
    {
        logger.debug {"[FRC] FrcProjectLifecycleService.disposeComponent() called for module '$module'"}
        if (module.isFrcFacetedModule() && !module.isDisposed)
        {
            RioLogProjectService.getInstance(module.project).update()
        }
    }

    override fun facetAdded(facet: Facet<*>)
    {
        if (facet.isFrcFacet())
        {
            val theProject = facet.module.project
            RioLogProjectService.getInstance(theProject).update()
            VendordepsToolWindowFactory.updateAvailability(theProject)
            checkProjectFrcStatus(theProject, knownFacetedProject = true, checkTeamNumConfigStatus = true)
        }
    }


    override fun facetConfigurationChanged(facet: Facet<*>) = updateForFrcFacet(facet)


    override fun facetRemoved(facet: Facet<*>) = updateForFrcFacet(facet)


    private fun updateForFrcFacet(facet: Facet<*>)
    {
        if (facet.isFrcFacet())
        {
            RioLogProjectService.getInstance(facet.module.project).update()
        }
    }

    fun checkProjectFrcStatus(project: Project, knownFacetedProject: Boolean, checkTeamNumConfigStatus: Boolean)
    {
        DumbService.getInstance(project).runWhenSmart {
            if (checkTeamNumConfigStatus)
            {
                notifyToConfigureTeamNumIfNecessary(project, knownFacetedProject)
            }
        }
    }
    
    fun checkForOldKotlinDslFile() {
        try
        {
//            RunOnceUtil.runOnceForProject(project, "FRC-CheckForOldKotlinDslFile") {
                DumbService.getInstance(project).runWhenSmart {
                    project.guessProjectDir()?.let { projectDir ->
                        projectDir.findChild("build.gradle.kts")?.let { gradleBuild ->
                            val buildFileAsPath = gradleBuild.toNioPath()
                            if (buildFileAsPath.isRegularFile()) {
                                if (buildFileAsPath.readText().contains("artifactory")) {
                                    FrcNotifyType.ACTIONABLE_WARN.builder()
                                        .withContent("You are using a Kotlin DSL Gradle build file created via an older template. " +
                                                             "The template has since been greatly improved. It is highly recommended you create " +
                                                             "a new project and replace the Gradle Build file in this project with the one created " +
                                                             "in the new project.")
                                        .withFrcPrefixedTitle("Recommended update")
                                        .notify(project)
                                }
                            }
                        }
                    }
                }
//            }
        }
        catch (e: Exception)
        {
            logger.warn("[FRC] Could not check Kotlin DSL file for legacy template due to exception: $e", e)
        }
    }

}

class FrcProjectLifecycleServiceStartupActivity : ProjectActivity
{
    override suspend fun execute(project: Project)
    {
        val service = FrcProjectLifecycleService.getInstance(project)
        service.registerListeners()

        // Handle opening of existing FRC projects
        service.runFrcProjectStartupActivities(project)
    }
}