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

package net.javaru.iip.frc.services

import com.intellij.openapi.application.ReadAction
import com.intellij.openapi.components.service
import com.intellij.openapi.diagnostic.logger
import com.intellij.openapi.project.Project
import net.javaru.iip.frc.util.getGradleBuildPsiFile
import net.javaru.iip.frc.util.isGroovyPluginAvailable
import net.javaru.iip.frc.wizard.FrcProjectWizardData


// Keep an eye on:  com.intellij.externalSystem.DependencyModifierService
// It's experimental, but allows you to modify the build model such as adding a dependency
// It does not (yet) support modifying a Plugin version. But JetBrains seems to indicate
// that that is possibly planned:
// https://intellij-support.jetbrains.com/hc/en-us/community/posts/360010674120-Programatically-Update-Plugin-Version-in-Gradle-Build-File

/** Matches the `includeDesktopSupport` variable declaration, capturing its value, for when the Groovy plugin is not available. */
private val includeDesktopSupportRegex = Regex("""\bincludeDesktopSupport\s*=\s*(true|false)\b""")

class FrcGradleService private constructor(val project: Project)
{
    private val logger = logger<FrcGradleService>()
    companion object
    {
        fun getInstance(project: Project): FrcGradleService = project.service()

        fun getRobotProjectTypeInfo(project: Project) = getInstance(project).getRobotProjectTypeInfo()

        fun getRobotProjectTypeInfo(frcProjectWizardData: FrcProjectWizardData) = RobotProjectTypeInfo(frcProjectWizardData)
    }

    fun getRobotProjectTypeInfo(): RobotProjectTypeInfo
    {
        // To reduce the parsing work done, and improve performance, we set these intelligently
        val gradleService = FrcGradleService.getInstance(project)
        val rio = gradleService.hasRoborioDeployTarget()
        val xrp = if (rio == true) false else gradleService.isXrpProject()
        val romi = if (rio == true || xrp == true) false else gradleService.isRomiProject()
        val desk: Boolean? = gradleService.isIncludeDesktopSupport()
        return RobotProjectTypeInfo(rio, romi, xrp, desk)
    }

    /**
     * This must be run in a ReadAction:
     * ```kotlin
     * val includeDesktopSupport = ReadAction.compute<Boolean?, Throwable> {
     *    FrcGradleService.getInstance(project).isIncludeDesktopSupport()
     * }
     * 
     * // or for non-nullable result 
     * 
     * val includeDesktopSupport = ReadAction.compute<Boolean, Throwable> {
     *     FrcGradleService.getInstance(project).isIncludeDesktopSupport() ?: false
     *  }
     * ```    
     * 
     * ```java
     * // Java
     * 
     * @Nullable
     * Boolean includeDesktopSupport = ReadAction.compute( () -> FrcGradleService.Companion.getInstance(myProject).isIncludeDesktopSupport());
     * ```
     */
    fun isIncludeDesktopSupport(): Boolean? = ReadAction.computeBlocking<Boolean?, Throwable> { isIncludeDesktopSupportImpl() }

    private fun isIncludeDesktopSupportImpl(): Boolean?
    {
        var result: Boolean? = null
        try
        {
            val psiFile = project.getGradleBuildPsiFile()
            if (psiFile == null)
            {
                logger.info("[FRC] Could not find gradle project file to look up includeDesktopSupport setting.")
            }
            else
            {
                result = if (isGroovyPluginAvailable && GroovyGradleBuildPsi.isGroovyFile(psiFile))
                    GroovyGradleBuildPsi.findIncludeDesktopSupport(psiFile)
                else
                    // e.g. in CLion, where the Groovy plugin is not available
                    includeDesktopSupportRegex.find(psiFile.text)?.groupValues?.get(1)?.toBoolean()
            }
        }
        catch (e: Exception)
        {
            logger.info("[FRC] an exception occurred when checking includeDesktopSupport setting: $e")
        }
        logger.debug("[FRC] isIncludeDesktopSupport returning: $result")
        return result
    }

    fun hasRoborioDeployTarget(): Boolean? = gradleFileHasTextReferenceOf("deploy.targets.roborio", useContains = false)

    /** Indicates a project is a non-roboRIO project. That is, it is (likely) either a Romi or XRP project. */
    @Suppress("unused")
    fun isNonRoboRioProject(): Boolean? = hasRoborioDeployTarget()?.not()

    fun isXrpProject(): Boolean? = gradleFileHasTextReferenceOf("addXRPClient()", true)

    fun isRomiProject(): Boolean? = gradleFileHasTextReferenceOf("10.0.0.2", true)

    // The build file's PSI must be read in a read action. The (nested) read action makes this safe to call from any thread.
    private fun gradleFileHasTextReferenceOf(targetText: String, useContains: Boolean): Boolean? =
        ReadAction.computeBlocking<Boolean?, Throwable> { gradleFileHasTextReferenceOfImpl(targetText, useContains) }

    private fun gradleFileHasTextReferenceOfImpl(targetText: String, useContains: Boolean): Boolean?
    {
        var result: Boolean? = null
        try
        {
            val psiFile = project.getGradleBuildPsiFile()
            if (psiFile == null)
            {
                logger.info("[FRC] Could not find gradle project file to look up hasRoborioDeployTarget setting.")
            }
            else
            {
                result = if (isGroovyPluginAvailable && GroovyGradleBuildPsi.isGroovyFile(psiFile))
                    GroovyGradleBuildPsi.hasReferenceText(psiFile, targetText, useContains)
                else
                    // e.g. in CLion, where the Groovy plugin is not available
                    if (useContains) psiFile.text.contains(targetText) else Regex("""(?<![\w.])${Regex.escape(targetText)}(?![\w.])""").containsMatchIn(psiFile.text)
            }
        }
        catch (e: Exception)
        {
            logger.info("[FRC] an exception occurred when checking includeDesktopSupport setting: $e")
            result = null
        }
        return result
    }

    /**
     * To get an instance:
     *  - `FrcGradleService.getRobotProjectTypeInfo(project)`
     *  - `FrcGradleService.getInstance(project).getRobotProjectTypeInfo()`
     */
    data class RobotProjectTypeInfo  constructor(
        val isRoboRIOProject: Boolean?,
        val isRomiProject: Boolean?,
        val isXrpProject: Boolean?,
        val hasIncludeDesktopSupport: Boolean?
                                                  )
    {
        constructor(frcProjectWizardData: FrcProjectWizardData): this(frcProjectWizardData.isRoboRioRobotTemplate,
                                                                      frcProjectWizardData.isRomiTemplate,
                                                                      frcProjectWizardData.isXrpTemplate,
                                                                      frcProjectWizardData.enableDesktopSupport,
                                                                     )

        companion object
        {
            fun create(frcProjectWizardData: FrcProjectWizardData): RobotProjectTypeInfo = RobotProjectTypeInfo(frcProjectWizardData)
        }
    }
}


