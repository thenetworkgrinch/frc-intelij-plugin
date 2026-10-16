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

import com.google.gson.JsonParser
import com.intellij.openapi.diagnostic.logger
import net.javaru.iip.frc.wpilib.wpiLibDirName
import net.javaru.iip.frc.wpilib.wpiLibPreferencesFileName
import org.jetbrains.plugins.gradle.service.project.AbstractProjectResolverExtension
import java.nio.file.Path
import kotlin.io.path.isRegularFile
import kotlin.io.path.readText

/**
 * Lets the IDE's Gradle sync of a WPILib C++ project succeed when a robot's toolchain is not installed. For C++ projects, GradleRIO
 * fails the build ("No Toolchain Found") during configuration when the roboRIO or SystemCore toolchain is missing, which fails the
 * sync, so the [toolchainOptionalArguments] are added to the sync's Gradle command line (as they are for `generateCompileCommands`).
 */
class WpiLibCppGradleSyncArgumentsResolverExtension : AbstractProjectResolverExtension()
{
    override fun getExtraCommandLineArgs(): List<String>
    {
        val projectPath = resolverCtx?.externalProjectPath ?: return emptyList()
        return if (isWpiLibCppProjectDir(Path.of(projectPath))) toolchainOptionalArguments else emptyList()
    }
}

private val logger = logger<WpiLibCppGradleSyncArgumentsResolverExtension>()

/** Whether the directory is the root of a WPILib C++ project, i.e. its `.wpilib/wpilib_preferences.json` file's `currentLanguage` is `cpp`. */
internal fun isWpiLibCppProjectDir(projectDir: Path): Boolean
{
    val preferencesFile = projectDir.resolve(wpiLibDirName).resolve(wpiLibPreferencesFileName)
    if (!preferencesFile.isRegularFile()) return false
    return try
    {
        val preferences = JsonParser.parseString(preferencesFile.readText()).asJsonObject
        preferences.get("currentLanguage")?.asString?.trim().equals("cpp", ignoreCase = true)
    }
    catch (e: Exception)
    {
        logger.info("[FRC] Could not read $preferencesFile. Cause: $e")
        false
    }
}
