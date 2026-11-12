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

package net.javaru.iip.frc.wpilib

import com.intellij.ide.util.PropertiesComponent
import com.intellij.openapi.application.ApplicationManager
import com.intellij.openapi.application.ModalityState
import com.intellij.openapi.application.WriteAction
import com.intellij.openapi.diagnostic.logger
import com.intellij.openapi.externalSystem.model.task.ExternalSystemTaskType
import com.intellij.openapi.externalSystem.service.internal.ExternalSystemProcessingManager
import com.intellij.openapi.externalSystem.util.ExternalSystemApiUtil
import com.intellij.openapi.module.ModuleManager
import com.intellij.openapi.project.Project
import com.intellij.openapi.projectRoots.JavaSdk
import com.intellij.openapi.projectRoots.ProjectJdkTable
import com.intellij.openapi.projectRoots.Sdk
import com.intellij.openapi.projectRoots.SdkTypeId
import com.intellij.openapi.projectRoots.SimpleJavaSdkType
import com.intellij.openapi.projectRoots.impl.SdkConfigurationUtil
import com.intellij.openapi.util.io.FileUtil
import net.javaru.iip.frc.run.findWpiLibJdkHome
import net.javaru.iip.frc.util.isGradleProject
import net.javaru.iip.frc.util.isJavaPluginAvailable
import net.javaru.iip.frc.util.reimportGradleProject
import org.jetbrains.plugins.gradle.settings.GradleSettings
import org.jetbrains.plugins.gradle.util.GradleConstants
import java.nio.file.Path

private object WpiLibGradleJvm
private val logger = logger<WpiLibGradleJvm>()

/** The WPILib JDK that the Gradle JVM was last set to, so it is only set once for each JDK. */
private const val gradleJvmSetToWpiLibJdkKey = "FRC.gradleJvmWpiLibJdk"

/**
 * Sets the Gradle JVM in the IDE's Gradle settings (Settings | Build, Execution, Deployment | Build Tools | Gradle) of a WPILib
 * project to the WPILib JDK for the project's year, adding the JDK to the IDE's JDKs if needed. This is done once for each WPILib
 * JDK, so a Gradle JVM the user selects afterwards is kept until the project's year (and thus its WPILib JDK) changes. Does
 * nothing if the WPILib JDK is not installed, or the Gradle project has not yet been linked (in which case it is tried again later).
 */
@JvmOverloads
fun ensureGradleJvmIsWpiLibJdk(project: Project, afterwards: (() -> Unit)? = null)
{
    if (project.isDisposed) return
    // Determining the project year, and thus the JDK, is a slow operation
    ApplicationManager.getApplication().executeOnPooledThread {
        if (project.isDisposed) return@executeOnPooledThread
        val jdkHome = project.findWpiLibJdkHome()
        val jdkHomePath = jdkHome?.let { FileUtil.toSystemIndependentName(it.toString()) }
        val setJvm = jdkHome != null && jdkHomePath != null && PropertiesComponent.getInstance(project).getValue(gradleJvmSetToWpiLibJdkKey) != jdkHomePath
        if (!setJvm && afterwards == null) return@executeOnPooledThread
        ApplicationManager.getApplication().invokeLater({
            if (setJvm) setGradleJvm(project, jdkHome!!, jdkHomePath!!)
            afterwards?.invoke()
        }, ModalityState.nonModal(), project.disposed)
    }
}

/**
 * Syncs (imports) the Gradle project of a WPILib project that is linked to Gradle, but has no modules imported from Gradle. That is,
 * the IDE does not know the project's source folders, dependencies, or JDK, so its Java files are not recognized. The IDE does not
 * sync such a project itself, as it treats a project with a linked Gradle project as already imported. This happens when the project
 * includes its '.idea' directory (e.g. one that was generated, or committed to version control), or when the IDE's cache of the
 * imported project was lost (e.g. the IDE was not shut down properly). The sync also sets the project's JDK. Must be called on the EDT.
 */
fun syncWpiLibProjectIfNotImported(project: Project)
{
    if (project.isDisposed || !project.isGradleProject()) return
    val isImported = ModuleManager.getInstance(project).modules.any { ExternalSystemApiUtil.isExternalSystemAwareModule(GradleConstants.SYSTEM_ID, it) }
    if (isImported) return
    // e.g. the IDE's own sync of a newly opened project
    if (ExternalSystemProcessingManager.getInstance().hasTaskOfTypeInProgress(ExternalSystemTaskType.RESOLVE_PROJECT, project)) return
    logger.info("[FRC] The WPILib project '${project.name}' is linked to Gradle, but has no modules imported from Gradle. Syncing the Gradle project.")
    project.reimportGradleProject()
}

private fun setGradleJvm(project: Project, jdkHome: Path, jdkHomePath: String)
{
    val linkedProjectsSettings = GradleSettings.getInstance(project).linkedProjectsSettings
    if (linkedProjectsSettings.isEmpty()) return
    val jdk = findOrAddJdk(jdkHome, jdkHomePath)
    linkedProjectsSettings.filter { it.gradleJvm != jdk.name }.forEach {
        logger.info("[FRC] Setting the Gradle JVM of '${it.externalProjectPath}' to the WPILib JDK '${jdk.name}' ($jdkHomePath), from '${it.gradleJvm}'")
        it.gradleJvm = jdk.name
    }
    PropertiesComponent.getInstance(project).setValue(gradleJvmSetToWpiLibJdkKey, jdkHomePath)
}

/**
 * Finds the IDE's JDK, named for the WPILib install (e.g. 'WPILib 2026 JDK'), for the WPILib JDK home, adding it if there is none.
 * A JDK the user added for the same home under another name (e.g. '25') is not used, so the WPILib JDK is clearly identified.
 */
private fun findOrAddJdk(jdkHome: Path, jdkHomePath: String): Sdk
{
    val jdkTable = ProjectJdkTable.getInstance()
    val baseName = "WPILib ${jdkHome.parent.fileName} JDK"
    // Without the Java plugin (e.g. in CLion), the Gradle plugin uses JDKs of the platform's SimpleJavaSdkType
    val sdkType: SdkTypeId = if (isJavaPluginAvailable) JavaSdk.getInstance() else SimpleJavaSdkType.getInstance()
    jdkTable.allJdks.firstOrNull { it.sdkType == sdkType && it.name.startsWith(baseName) && it.homePath != null && FileUtil.pathsEqual(it.homePath, jdkHomePath) }
        ?.let { return it }
    val name = SdkConfigurationUtil.createUniqueSdkName(baseName, jdkTable.allJdks.toList())
    val jdk = if (isJavaPluginAvailable) JavaSdk.getInstance().createJdk(name, jdkHomePath, false) else SimpleJavaSdkType.getInstance().createJdk(name, jdkHomePath)
    WriteAction.run<Throwable> { jdkTable.addJdk(jdk) }
    logger.info("[FRC] Added the WPILib JDK '$name' ($jdkHomePath)")
    return jdk
}
