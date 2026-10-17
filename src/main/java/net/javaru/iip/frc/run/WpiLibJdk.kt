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

package net.javaru.iip.frc.run

import com.intellij.openapi.project.Project
import com.intellij.openapi.util.SystemInfo
import net.javaru.iip.frc.wpilib.extractProjectYear
import net.javaru.iip.frc.wpilib.getConfiguredProjectYear
import net.javaru.iip.frc.wpilib.getDefaultWpiLibRootPath
import java.nio.file.Files
import java.nio.file.Path
import java.time.Year

// Kept apart from the (Java plugin dependent) simulation code, as the WPILib JDK is also used in IDEs without the Java plugin, such as CLion

// region JDK

/**
 * Finds the JDK installed by the WPILib installer for the project's year. The WPILib install directory is named for the
 * project's `projectYear` (e.g. `C:\Users\Public\wpilib\2027_alpha7`, or `~/.local/share/wpilib/2027_alpha7` on Linux), with the
 * plain year (e.g. `2026`) as a fallback.
 * **Must not be called on the EDT** as determining the project year is a slow operation.
 */
fun Project.findWpiLibJdkHome(): Path? = wpiLibJdkHomeCandidates(getConfiguredProjectYear()).firstOrNull { it.hasJavaExecutable() }

/** The possible WPILib JDK locations for the project year, in order of preference. */
fun wpiLibJdkHomeCandidates(projectYear: String?): List<Path>
{
    val year = extractProjectYear(projectYear) ?: Year.now().value
    // e.g. C:\Users\Public\wpilib (Windows), ~/wpilib (Mac, and Linux before 2027) or ~/.local/share/wpilib (Linux, 2027 and later)
    val wpiLibBaseDir = getDefaultWpiLibRootPath(year).parent
    return listOfNotNull(projectYear?.trim()?.ifBlank { null }, year.toString())
        .distinct()
        .map { wpiLibBaseDir.resolve(it).resolve("jdk") }
}

internal fun Path.hasJavaExecutable(): Boolean = Files.isRegularFile(resolve("bin").resolve(if (SystemInfo.isWindows) "java.exe" else "java"))

// endregion
