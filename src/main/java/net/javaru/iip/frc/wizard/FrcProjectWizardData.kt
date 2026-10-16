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

import com.intellij.openapi.application.ApplicationInfo
import net.javaru.iip.frc.settings.FrcApplicationSettings
import net.javaru.iip.frc.wpilib.determineProjectYearStringForVersion
import net.javaru.iip.frc.wpilib.gradlePluginRepo.GradleRioMavenMetadataState
import net.javaru.iip.frc.wpilib.version.WpiLibVersion
import java.nio.file.Path
import java.nio.file.Paths

const val DEFAULT_BASE_PACKAGE = "frc.robot"
const val DEFAULT_ROBOT_CLASS_NAME = "Robot"

class FrcProjectWizardData(
    var teamNumber: Int = FrcApplicationSettings.getInstance().teamNumber,
    /** The simple name of the Main class (not to be confused with the (primary) Robot class). This is the simple class that has the `main()` method.*/
    var mainClassSimpleName: String = "Main",
    /** The simple name of the primary Robot class (not to be confused with the Main class). This is the class that extends one of the WPILib `RobotBase` classes.*/
    var robotClassSimpleName: String = DEFAULT_ROBOT_CLASS_NAME,  // if/whn we make settable, we need to change the template copying to rename the file!
    var basePackage: String = DEFAULT_BASE_PACKAGE,
    var wpilibVersion: WpiLibVersion = GradleRioMavenMetadataState.getInstance().wpiLibMavenMetadata.releaseAsWpiLibVersion,
    // We just need to set some non-null value here. It does NOT need to be updated each year as it is set in net/javaru/iip/frc/wizard/FrcTemplateSelectionWizardStep#updateDataModel
    var frcWizardTemplateDefinition: FrcWizardTemplateDefinition = FrcWizard2019ProjectTemplateDefinition.CommandBased,
    var includeVsCodeConfigs: Boolean = true,
    var includeKotlinSupport: Boolean = false,
    var enableDesktopSupport: Boolean = false,
    var gitIgnoreConfiguration: GitIgnoreConfiguration = GitIgnoreConfiguration(true, generateFromSite = true),
    var includeJUnitSupport:Boolean = true,
    var junitOption: JUnitOption = JUnitOption.JUnit5,
    @Deprecated("Deprecated as of 2023 templates (such that 2022 is the last year JUnit 4 support is enabled.)")
    var junit4Version: String = "4.13.2",
    // TODO Issue #80 have these dynamically updated in the wizard
    var junit5Version: String = "5.11.4",
    var kotlinVersion: KotlinVersion = defaultKotlinVersion,
    var gradleDslOption: GradleDslOption = GradleDslOption.GroovyDSL,
    var templateLanguageOption: TemplateLanguageOption = TemplateLanguageOption.Java,
    // TODO: Add selection option to new project wizard
    var useGradleAllDistribution: Boolean = FrcApplicationSettings.getInstance().useGradleAllDistributionDefault,
    )
{

    /**
     * The `projectYear` used in the `wpilib_preferences.json` file. Typically, it is just the year such as `2020`, but it may be an alternate 
     * value during the beta releases, such as `Beta2020` or `Beta2020-2`. There doesn't appear to be any pattern to it as in the WPI repo, it 
     * is a hard coded value in [https://github.com/wpilibsuite/vscode-wpilib/blob/master/vscode-wpilib/resources/gradle/java/.wpilib/wpilib_preferences.json]
     * and the change from `Beta2020` to `Beta2020-2` did not correlate to a WpiLib version/release.
     */
    val projectYear: String
        get() = determineProjectYearStringForVersion(wpilibVersion)
                
    /** The project year, such as `2019` or `2020`, as a String. */
    val frcYearString: String
        get() = wpilibVersion.frcYear.toString()

    /** Convenience property for the `wpilibVersion.frcYear` property, indicating the project year such as `2019` or `2020`. */
    val frcYear: Int
        get() = wpilibVersion.frcYear

    /** Returns the reamNumber as a String, which can be 0 if not set. @see teamNumberOrEmptyString */
    val teamNumberAsString: String
        get() = teamNumber.toString()

    /** Returns the team number as a String, returning an empty String if the team number is zero. */
    val teamNumberAsStringOrEmptyString: String
        get() = if (teamNumber == 0 ) "" else teamNumber.toString()



    val basePackageAsDirString: String
        get() = basePackage.replace('.', '/')

    val includeDesktopSupportGradleSetting: String
        get()
        {
            // We now honor the enableDesktopSupport option as it is automatically selected when a romi template is selected.
            // We have a warning in the wizard that warns the user if the option is not selected and a Romi template is in use.
            val result = enableDesktopSupport
            return result.toString()
        }

    val isExampleTemplate
        get() = frcWizardTemplateDefinition.isExample

    val templateRequiresJUnit
        get() = frcWizardTemplateDefinition.templateRequiresJUnit

    val isRomiTemplate
        get() = frcWizardTemplateDefinition.robotType == RobotType.Romi

    val isXrpTemplate
        get() = frcWizardTemplateDefinition.robotType == RobotType.XRP

    val isRoboRioRobotTemplate
        get() = frcWizardTemplateDefinition.robotType == RobotType.roboRIO

    val robotType: RobotType
        get() = frcWizardTemplateDefinition.robotType

    val robotTypeAsString: String
        get() = frcWizardTemplateDefinition.robotType.name

    val basePackageAsDirPath: Path
        get() = Paths.get(basePackageAsDirString)
    
    /** The Fully Qualified (FQ) name of the Main class (not to be confused with the (primary) Robot class). This is the simple class that has the `main()` method.*/
    val mainClassFQ: String
        get() = if (basePackage.isEmpty()) mainClassSimpleName else "${basePackage}.${mainClassSimpleName}"
    /** The Fully Qualified (FQ) name of the primary Robot class (not to be confused with the Main class). This is the class that extends one of the WPILib `RobotBase` classes.*/
    val robotClassFQ: String
        get() = if (basePackage.isEmpty()) mainClassSimpleName else "${basePackage}.${mainClassSimpleName}"

    val gradleDistributionUrl: String
        get() {
            val retval= when (wpilibVersion.frcYear)
            {
                // To check for latest, look in vscode-wpilib project (NOT allwpilib where the templates are)
                //      vscode-wpilib/resources/gradle/shared/
                //      vscode-wpilib/resources/gradle/shared/gradle/wrapper/gradle-wrapper.properties
                // Do NOT confuse with the project's build itself.
                2019 -> """https\://services.gradle.org/distributions/gradle-5.0-bin.zip"""
                2020 -> """https\://services.gradle.org/distributions/gradle-6.0.1-bin.zip"""
                2021 -> """https\://services.gradle.org/distributions/gradle-6.0.1-bin.zip"""
                2022 -> """https\://services.gradle.org/distributions/gradle-7.3.2-bin.zip"""
                2023 -> """https\://services.gradle.org/distributions/gradle-7.5.1-bin.zip"""
                2024 -> """https\://services.gradle.org/distributions/gradle-8.5-bin.zip"""
                2025 -> """https\://services.gradle.org/distributions/gradle-8.11-bin.zip"""
                2026 -> """https\://services.gradle.org/distributions/gradle-8.11-bin.zip"""
                else -> """https\://services.gradle.org/distributions/gradle-8.11-bin.zip"""
            }
            return if (useGradleAllDistribution || FrcApplicationSettings.getInstance().isTeam3838() || teamNumber == 3838)
                retval.replace("-bin", "-all")
            else
                retval
        }

    /** 
     * The WPI Lib copyright placed at the top of source files generated by the new project wizard.
     * To check for the need to update, inspect any WPI Lib "official" template file in the `allwpilib` 
     * project. For example `<allwpilibProjectRoot>/wpilibjExamples/src/main/java/edu/wpi/first/wpilibj/templates/timed/Main.java`.
     */
    val copyright: String
        get(){
            return when (wpilibVersion.frcYear)
            {
                /* Added in 2021. Did not backport to older version as in older one the year was in the statement, and it varied from class to class */
                2021 -> copyright2021AndLater
                else -> copyright2021AndLater
            }
        }
    
    fun junitIncludeVintageSupport(): Boolean = includeJUnitSupport && (junitOption == JUnitOption.JUnit5withVintage)
    fun junitUseJUnitPlatform(): Boolean = includeJUnitSupport && (junitOption == JUnitOption.JUnit5 || junitOption == JUnitOption.JUnit5withVintage) 
    fun junitIsJUnit4Only(): Boolean = includeJUnitSupport && (junitOption == JUnitOption.JUnit4)
    
    override fun toString(): String
    {
        return "FrcProjectWizardData(" +
            "teamNumber=$teamNumber, " +
            "mainClassSimpleName='$mainClassSimpleName', " +
            "robotClassSimpleName='$robotClassSimpleName', " +
            "basePackage='$basePackage', " +
            "wpilibVersion=$wpilibVersion, " +
            "frcWizardTemplateDefinition=$frcWizardTemplateDefinition, " +
            "enableDesktopSupport=$enableDesktopSupport, " +
            "includeVsCodeConfigs=$includeVsCodeConfigs, " +
            "gitIgnoreConfiguration=$gitIgnoreConfiguration, " +
            "includeJUnitSupport=$includeJUnitSupport, " +
            "junitOption=$junitOption, " +
            "junit5Version='$junit5Version', " +
            "includeKotlinSupport='$includeKotlinSupport', " +
            "kotlinVersion='$kotlinVersion', " +
            "templateLanguageOption='$templateLanguageOption', " +
            ")"
    }

    enum class JUnitOption() {JUnit5, JUnit5withVintage, JUnit4}
    enum class GradleDslOption() {GroovyDSL, KotlinDSL}
    
    private val copyright2021AndLater = """
        |// Copyright (c) FIRST and other WPILib contributors.
        |
        |// Open Source Software; you can modify and/or share it under the terms of
        |// the WPILib BSD license file in the root directory of this project.
    """.trimMargin()

    companion object
    {
        // Lazy so that class initialization does not depend on the ApplicationInfo service
        val baselineVersion: Int by lazy { ApplicationInfo.getInstance().build.baselineVersion }
        private val defaultKotlinVersion: KotlinVersion by lazy {
            if (baselineVersion < 211)
                KotlinVersion(1, 5, 31)
            else
                when (baselineVersion)
                {
                    // https://search.maven.org/artifact/org.jetbrains.kotlin/kotlin-bom
                    // https://plugins.jetbrains.com/plugin/6954-kotlin/versions
                    //    This link is no longer a valid way to see what version of Kotlin a plugin supports for a particular version of IDEA
                    //    Need to see if I can find a replacement link.
                    211           -> KotlinVersion(1, 6, 21) // 1.6.21
                    212           -> KotlinVersion(1, 7, 10) // 1.7.10
                    213, 221      -> KotlinVersion(1, 8, 10) // 1.8.10
                    222           -> KotlinVersion(1, 8, 21) // 1.8.21
                    223           -> KotlinVersion(1, 9, 10) // 1.9.10
                    231, 232, 233 -> KotlinVersion(1, 9, 24) // 1.9.24
                    241, 242, 243 -> KotlinVersion(2, 1, 0)  // 2.1.0
                    else          -> KotlinVersion(2, 1, 0)  // 2.1.0
                }
        }
    }
}

data class GitIgnoreConfiguration(
        var includeGitIgnoreFile: Boolean = true,
        var intellij: IdeConfigOption = IdeConfigOption.Ignore,
        var vscode: IdeConfigOption = IdeConfigOption.Share,
        var eclipse: IdeConfigOption = IdeConfigOption.Ignore,
        var netbeans: IdeConfigOption = IdeConfigOption.Ignore,
        var java: Boolean = true,
        var gradle: Boolean = true,
        var linux: Boolean = true,
        var macOS: Boolean = true,
        var windows: Boolean = true,
        /** The `.gitignore` file generated by wpilib has C++ in it. But that is more a case (I believe) that they use the same file for both Java and C++ based projects. So we default to `false` for this. */
        var cpp: Boolean = false,
        var wpilib: Boolean = true,
        /** Additional templates names from the gitignore API site. See https://www.toptal.com/developers/gitignore/api/list (and/or https://www.toptal.com/developers/gitignore?templates) */
        var additionalGitignoreTemplates: MutableList<String> = mutableListOf(),
        var generateFromSite: Boolean = true
                                 )
{
    // since Java does not support named parameters, using the built-ion data class `copy()` function in Java 
    // requires us to pass in all properties, making it not very useful. So we have this function
    fun fullCopy(): GitIgnoreConfiguration = this.copy()
    
    companion object
    {
        /** Returns a `GitIgnoreConfiguration` instance with all properties set to their defaults. */
        fun defaultInstance(): GitIgnoreConfiguration = GitIgnoreConfiguration()
    }
}

enum class IdeConfigOption
{
    Share, Ignore, NoEntry;

    fun asBoolean(): Boolean = Companion.asBoolean(this)


    companion object
    {
        fun asBoolean(ideConfigOption: IdeConfigOption): Boolean
        {
            return when (ideConfigOption)
            {
                Ignore -> true
                NoEntry -> false
                Share -> false
            }
        }

        fun fromBoolean(value: Boolean): IdeConfigOption = if (value) Ignore else NoEntry
    }
}
