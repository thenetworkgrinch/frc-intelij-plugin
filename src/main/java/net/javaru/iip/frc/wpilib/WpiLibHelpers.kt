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

package net.javaru.iip.frc.wpilib

import com.intellij.ide.BrowserUtil
import com.intellij.openapi.diagnostic.logger
import com.intellij.openapi.project.Project
import com.intellij.openapi.util.SystemInfo
import com.intellij.openapi.vfs.VfsUtil
import com.intellij.psi.PsiLiteralExpression
import com.intellij.util.io.isFile
import com.intellij.util.lang.JavaVersion
import net.javaru.iip.frc.FrcPluginGlobals
import net.javaru.iip.frc.i18n.FrcMessageKey
import net.javaru.iip.frc.notify.FrcNotifyType
import net.javaru.iip.frc.util.computeInSmartReadAction
import net.javaru.iip.frc.util.findClass
import net.javaru.iip.frc.util.isJavaPluginAvailable
import net.javaru.iip.frc.util.warnWhenNotInTestMode
import net.javaru.iip.frc.wpilib.version.WpiLibVersion
import net.javaru.iip.frc.wpilib.version.WpiLibVersionImpl
import net.javaru.iip.frc.wpilib.version.firstRelease
import net.javaru.iip.frc.wpilib.version.minVersion
import org.apache.commons.lang3.SystemUtils
import java.nio.file.Files
import java.nio.file.Path
import java.nio.file.Paths
import java.util.*
import kotlin.io.path.exists
import kotlin.io.path.isRegularFile

object WpiLibHelpers
private val logger = logger<WpiLibHelpers>()
/**
 * Determines the `projectYear` String used in the `wpilib_preferences.json` file. Typically, it is just the year such as `2020`, but it may be an alternate
 * value during the pre-releases, such as `Beta2020` or `Beta2020-2`. There doesn't appear to be any pattern to it as in the WPI repo, it
 * is a hard coded value in [https://github.com/wpilibsuite/vscode-wpilib/blob/master/vscode-wpilib/resources/gradle/java/.wpilib/wpilib_preferences.json]
 * and the change from `Beta2020` to `Beta2020-2` did not correlate to a WpiLib version/release.
 */
fun determineProjectYearStringForVersion(version: WpiLibVersion): String = when
{
    version.isNewerThan(minVersion(2020)) && version.isOlderThan(firstRelease(2020)) && version.isBetaOrBetaPreview() -> "Beta2020-2"
    // From 2027 on, the project year is the WPILib installer's, such as `2027_alpha7` for `2027.0.0-alpha-7`, which settings.gradle
    // uses to find the installed WPILib, and which the vendordeps' `wpilibYear` must match.
    version.frcYear >= 2027 -> net.javaru.iip.frc.wpilib.vendordeps.vendorRepoBundleName(version.versionString) ?: version.frcYear.toString()
    else -> version.frcYear.toString()
}


//        JAVA_VERSION key in 
//            2019: C:\Users\Public\frc${frcYear}\jdk\release
//            2020+ C:\Users\Public\wpilib\${frcYear}\jdk\release 
//        From https://docs.wpilib.org/en/latest/docs/getting-started/getting-started-frc-control-system/wpilib-setup.html
//        The installation directory has changed for 2020. In 2019 the software was installed to  ~\frcYYYY where ~ is C:\Users\Public on Windows and YYYY is the FRC year. 
//        In 2020 and later it is installed to  ~\wpilib\YYYY  This lessens clutter when multiple years software are installed.
//        Regardless of whether All Users or Current User is chosen, the software is installed to C:\Users\Public\wpilib\YYYY where YYYY is the current FRC year. 
//            If you choose All Users, then shortcuts are installed to all users desktop and start menu and system environment variables are set. 
//            If Current User is chosen, then shortcuts and environment variables are set for only the current user.

/**
 * Returns the root path for the WPI Lib installation. It does check if the directory exists, and if not its
 * missing is logged and the user is notified with a warn notification, but no other action is taken and the
 * Path is still returned.
 * @param forWpiLibVersion The WpiLibVersion to get the root path for
 */
fun getWpiLibRootPath(forWpiLibVersion: WpiLibVersion, project: Project? = null): Path = getWpiLibRootPath(forWpiLibVersion.frcYear, project)

/**
 * Returns the root path for the WPI Lib installation. It does check if the directory exists, and if not its
 * missing is logged and the user is notified with a "warn" notification, but no other action is taken and the
 * Path is still returned.
 * @param year The FRC season year
 */
fun getWpiLibRootPath(year: Int, project:Project? = null): Path
{
    // TODO: let's provide for user overriding of the install location See Issue #85: https://gitlab.com/Javaru/frc-intellij-idea-plugin/-/issues/85
    val wpiLibRootPath = getDefaultWpiLibRootPath(year)

    if (!wpiLibRootPath.exists() && FrcPluginGlobals.IS_NOT_IN_FRC_UNIT_TEST_MODE)
    {
        // TODO: when we implement above ability for user to override, prompt the user for the location here and set it
        logger.warn("[FRC] The WPI Lib root was not found at its expected location of: $wpiLibRootPath")
        FrcNotifyType.ACTIONABLE_WARN.builder()
            .withContent(FrcMessageKey.of("frc.wpilib.root.path.not.found.user.notification.content", wpiLibRootPath))
            .withFrcPrefixedTitle(FrcMessageKey.of("frc.wpilib.root.path.not.found.user.notification.title", year.toString()))
            .withNoSubTitle()
            .withActionBasic(FrcMessageKey.of("frc.wpilib.root.path.not.found.user.notification.action.link")) {
                BrowserUtil.browse("https://docs.wpilib.org/en/stable/docs/zero-to-robot/step-2/wpilib-setup.html")
            }
            .noMoreActions()
            .notify(project)
    }
    return wpiLibRootPath
}

/**
 * Returns the OS specific default/standard path for the wpilib installation, **but does not check if it exists**.
 * Generally, the [getWpiLibRootPath] should be preferred over this method.
 */
fun getDefaultWpiLibRootPath(forWpiLibVersion: WpiLibVersion): Path = getDefaultWpiLibRootPath(forWpiLibVersion.frcYear)

/**
 * Returns the OS specific default/standard path for the wpilib installation, **but does not check if it exists**.
 * Generally, the [getWpiLibRootPath] should be preferred over this method.
 */
fun getDefaultWpiLibRootPath(year: Int): Path
{
    //        From https://docs.wpilib.org/en/latest/docs/getting-started/getting-started-frc-control-system/wpilib-setup.html
    //        The installation directory has changed for 2020. In 2019 the software was installed to  ~\frcYYYY where ~ is C:\Users\Public on Windows and YYYY is the FRC year.
    //        In 2020 and later it is installed to  ~\wpilib\YYYY  This lessens clutter when multiple years software are installed.
    //        Regardless of whether All Users or Current User is chosen, the software is installed to C:\Users\Public\wpilib\YYYY where YYYY is the current FRC year.
    //            If you choose All Users, then shortcuts are installed to all users desktop and start menu and system environment variables are set.
    //            If Current User is chosen, then shortcuts and environment variables are set for only the current user.
    //
    // 2019  C:\Users\Public\frc${frcYear}          Mac & Linux: ~/frc${frcYear}
    // 2020+ C:\Users\Public\wpilib\${frcYear}      Mac & Linux: ~/wpilib/${frcYear}

    val basePath = if (SystemInfo.isWindows)
    {
        Paths.get(System.getenv("PUBLIC") ?: "C:\\Users\\Public").toAbsolutePath()
    }
    else
    {
        try
        {
            VfsUtil.getUserHomeDir()?.toNioPath()?.toAbsolutePath() ?: Paths.get("/").toAbsolutePath()
        }
        catch (t1: Throwable)
        {
            logger.warnWhenNotInTestMode("[FRC] Could not determine WPI Lib path via VfUtils due to an exception. Will use Commons Lang SystemUtils.getUserHome() instead. Cause Summary: $t1")
            try
            {
                SystemUtils.getUserHome()?.toPath()?.toAbsolutePath() ?: Paths.get("/").toAbsolutePath()
            }
            catch (t2: Throwable)
            {
                logger.warnWhenNotInTestMode("[FRC] Could not determine WPI Lib path via Commons Lang SystemUtils.getUserHome() due the exception: $t2")
                Paths.get("/")
            }
        }
    }

    return if (year <= 2019)
    {
        // technically 2018 and earlier is different. But at this point we can't deal with legacy anymore
        basePath.resolve("frc${year}")

    } else
    {
        basePath.resolve("wpilib").resolve("$year")
    }
}

/**
 * Returns the standard path for the wpilib JDK installation, **but does not check if it exists**.
 */
fun getWpiLibJdkHomePath(year: Int, project: Project? = null): Path = getWpiLibRootPath(year, project).resolve("jdk")

/**
 * Returns the standard path for the wpilib 'tools' directory, **but does not check if it exists**.
 */
fun getWpiLibToolsPath(year: Int, project: Project? = null): Path = getWpiLibRootPath(year, project).resolve("tools")

/**
 * Returns the standard path for the wpilib 'tools' directory, **but does not check if it exists**.
 */
fun getWpiLibToolsPath(forWpiLibVersion: WpiLibVersion, project: Project? = null): Path = getWpiLibRootPath(forWpiLibVersion, project).resolve("tools")

/**
 * Returns the standard path for the wpilib 'tools' directory that contains the JAR files. For 2021 and earlier,
 * this is the 'tools' directory itself. For 2022 and later, it is the 'artifacts' subdir within the 'tools' directory.
 * This method **does not check if the directory exists**.
 */
fun getWpiLibToolsJarsPath(forWpiLibVersion: WpiLibVersion, project: Project? = null): Path =
    getWpiLibToolsPath(forWpiLibVersion, project).let {
        if (forWpiLibVersion.frcYear <= 2021)
            it
        else
            it.resolve("artifacts")
    }

/**
 * Returns the path to the latest JAR file in the tools JAR directory -- 'tools' directory itself for 2021 and earlier, and
 * tools/artifacts for 2022 and later -- as best as we can determine. Starting in 2022, the JAR fil names contained the
 * WPI Lib version name, and OS architecture. For example 'Shuffleboard-2023.1.1-winx64.jar`. In the event the file cannot
 * be found, a stand-in name is created, which may not be accurate.
 */
@Suppress("SpellCheckingInspection")
fun getToolsJar(baseName: String, forWpiLibVersion: WpiLibVersion, project: Project? = null): Path
{
    val dir = getWpiLibToolsJarsPath(forWpiLibVersion, project)
    return if (forWpiLibVersion.frcYear <= 2021)
    {
        // 2021 and ealier, it was "shuffleboard.jar", but 2022+ it is "Shuffleboard-2023.1.1-winx64.jar", so "Shuffleboard" should be passed in.
        val name = if(baseName.equals("shuffleboard", ignoreCase = true)) baseName.lowercase() else baseName
        dir.resolve("${name}.jar")
    }
    else
    {
        // we will just get "null" if the dir does not exist
        dir.toFile()
            .walk()
            .filter { it.name.startsWith(baseName, ignoreCase = true) }
            .sortedBy { it.name }
            .lastOrNull()?.toPath() ?: run {
                val os = when {
                    // based on info here: https://github.com/wpilibsuite/wpilib-tool-plugin/blob/main/src/main/java/edu/wpi/first/tools/NativePlatforms.java

                    SystemInfo.isMac -> if (System.getProperty("os.arch")?.contains("aarch64") == true) "macarm64"  else "macx64"
                    SystemInfo.isLinux -> "linuxx64"
                    SystemInfo.isWindows -> if (System.getProperty("os.arch")?.contains("64") == true) "winx64" else "winx32"
                    else -> "winx64" // we'll default to winx64 as the most common, especially given the low likelihood of this being called
                }
                // Example: Shuffleboard-2023.1.1-winx64.jar
                dir.resolve("${baseName}-${forWpiLibVersion}-${os}.jar") }

        }


}

/**
 * Returns the standard path for the Java `RELEASE` file for the wpilib JDK installation, **but does not check if it exists**.
 * Some example content:
 *
 * **Oracle JDK 11 AND OpenJDK 11**
 * ```
 * IMPLEMENTOR="Oracle Corporation"
 * IMPLEMENTOR_VERSION="18.9"
 * JAVA_VERSION="11.0.1"
 * JAVA_VERSION_DATE="2018-10-16"
 * MODULES="java.base java.compiler . . ."
 * OS_ARCH="x86_64"
 * OS_NAME="Windows"
 * SOURCE=".:8513ac27b651"
 * ```
 *
 * **Amazon Corretto 8**
 * ```
 * JAVA_VERSION="1.8.0_222"
 * OS_NAME="Windows"
 * OS_VERSION="5.2"
 * OS_ARCH="amd64"
 * SOURCE=""
 * ```
 *
 * **Amazon Corretto 11**
 * ```
 * IMPLEMENTOR="Amazon.com Inc."
 * IMPLEMENTOR_VERSION="Corretto-11.0.5.10.1"
 * JAVA_VERSION="11.0.5"
 * JAVA_VERSION_DATE="2019-10-15"
 * MODULES="java.base java.compiler . . ."
 * OS_ARCH="x86_64"
 * OS_NAME="Windows"
 * SOURCE=""
 * ```
 */
fun getWpiLibJdkReleaseFile(year: Int, project: Project? = null): Path = getWpiLibJdkHomePath(year, project).resolve("RELEASE")

/**
 * Returns the value of the `JAVA_VERSION` property of the JDK `RELEASE` file, or null if the file
 * does not exist, or does nto contain the `JAVA_VERSION property.
 * Example values:
 *  - 11.0.2
 *  - 11.0.5
 *  - 1.8.0_222
 *  - `null`
 */
fun getWpiLibJdkReleaseJavaVersionString(year: Int, project: Project? = null): String?
{
    val releaseFile = getWpiLibJdkReleaseFile(year, project)
    return if (releaseFile.isRegularFile())
    {
        val properties = Properties()
        properties.load(Files.newBufferedReader(releaseFile))
        val value = properties.getProperty("JAVA_VERSION", null)
        // We need to strip off surrounding quotes
        value?.removeSurrounding("\"")
    }
    else
    {
        null
    }
}

fun getWpiLibJdkReleaseJavaVersion(year: Int, project: Project? = null): JavaVersion? = JavaVersion.tryParse(getWpiLibJdkReleaseJavaVersionString(year, project))
fun getWpiLibJdkReleaseJavaFeatureVersion(year: Int, project: Project? = null): Int? = JavaVersion.tryParse(getWpiLibJdkReleaseJavaVersionString(year, project))?.feature


/**
 * Gets the WPI Lib Version for the attached WPI Lib JAR **within a smart read action**, returning null if it cannot be determined (for example if the
 * WpiLib is not attached as a dependency/library).
 */
fun Project.getAttachedWpiLibVersionInSmartReadAction(): WpiLibVersion?
{
    var version: WpiLibVersion? = null
    computeInSmartReadAction {
        version = getAttachedWpiLibVersion()
    }
    return version
}

/**
 * Gets the WPI Lib Version for the attached WPI Lib JAR, returning null if it cannot be determined (for example if the
 * WpiLib is not attached as a dependency/library). **This action should be run in a `runReadActionInSmartMode` wrapping.**
 * @see [getAttachedWpiLibVersionInSmartReadAction]
 */
fun Project.getAttachedWpiLibVersion(): WpiLibVersion?
{
    val versionString = this.getAttachedWpiLibVersionString()
    return WpiLibVersionImpl.parseSafely(versionString)
}

/**
 * Gets the WPI Lib Version String for the attached WPI Lib JAR **within a smart read action**, returning null if it cannot be determined (for example if the
 * WpiLib is not attached as a dependency/library).
 * @see [getAttachedWpiLibVersionInSmartReadAction]
 */
fun Project.getAttachedWpiLibVersionStringInSmartReadAction(): String?
{
    var version: String? = null
    computeInSmartReadAction {
        version = this.getAttachedWpiLibVersionString()
    }
    return version
}

/**
 * Gets the WPI Lib Version String for the attached WPI Lib JAR returning null if it cannot be determined (for example if the
 * WpiLib is not attached as a dependency/library). **This action should be run in a `runReadActionInSmartMode` wrapping.**
 * @see [getAttachedWpiLibVersionStringInSmartReadAction]
 */
fun Project.getAttachedWpiLibVersionString(): String?
{
    // The version is read from the attached WPILib Java library, so it cannot be determined without the Java plugin (e.g. in CLion)
    if (!isJavaPluginAvailable) return null
    val verClasses = findClass(this, WpiLibConstants.VERSION_CLASS_FQN)
    for (psiClass in verClasses)
    {
        val initializer = psiClass?.findFieldByName(WpiLibConstants.VERSION_FIELD_NAME, false)?.initializer
        if (initializer is PsiLiteralExpression)
        {
            val value = initializer.value
            if (value is String)
            {
                return value
            }
        }
    }
    return null
}