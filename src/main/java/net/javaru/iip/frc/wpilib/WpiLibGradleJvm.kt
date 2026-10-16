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
import com.intellij.openapi.project.Project
import com.intellij.openapi.projectRoots.JavaSdk
import com.intellij.openapi.projectRoots.ProjectJdkTable
import com.intellij.openapi.projectRoots.Sdk
import com.intellij.openapi.projectRoots.SdkTypeId
import com.intellij.openapi.projectRoots.SimpleJavaSdkType
import com.intellij.openapi.projectRoots.impl.SdkConfigurationUtil
import com.intellij.openapi.util.io.FileUtil
import net.javaru.iip.frc.run.findWpiLibJdkHome
import net.javaru.iip.frc.util.isJavaPluginAvailable
import org.jetbrains.plugins.gradle.settings.GradleSettings
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
fun ensureGradleJvmIsWpiLibJdk(project: Project)
{
    if (project.isDisposed) return
    // Determining the project year, and thus the JDK, is a slow operation
    ApplicationManager.getApplication().executeOnPooledThread {
        if (project.isDisposed) return@executeOnPooledThread
        val jdkHome = project.findWpiLibJdkHome() ?: return@executeOnPooledThread
        val jdkHomePath = FileUtil.toSystemIndependentName(jdkHome.toString())
        if (PropertiesComponent.getInstance(project).getValue(gradleJvmSetToWpiLibJdkKey) == jdkHomePath) return@executeOnPooledThread
        ApplicationManager.getApplication().invokeLater({ setGradleJvm(project, jdkHome, jdkHomePath) }, ModalityState.nonModal(), project.disposed)
    }
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
