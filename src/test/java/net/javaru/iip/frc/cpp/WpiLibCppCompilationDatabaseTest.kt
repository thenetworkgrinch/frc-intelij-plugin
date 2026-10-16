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
import org.junit.jupiter.api.Test
import org.junit.jupiter.api.io.TempDir
import java.nio.file.Path
import kotlin.io.path.createDirectories
import kotlin.io.path.writeText
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNull
import kotlin.test.assertTrue

internal class WpiLibCppCompilationDatabaseTest
{
    private val targets = listOf("linuxsystemcoredebug", "linuxsystemcorerelease", "windowsx86-64debug", "windowsx86-64release")

    @Test
    fun `the selected target is used when it is available`()
    {
        assertEquals("windowsx86-64release", choosePrimaryTarget(targets, "windowsx86-64release"))
    }

    @Test
    fun `the robot's debug target is preferred`()
    {
        assertEquals("linuxsystemcoredebug", choosePrimaryTarget(targets, null))
        assertEquals("linuxsystemcoredebug", choosePrimaryTarget(targets, "linuxathenadebug"))
        assertEquals("linuxathenadebug", choosePrimaryTarget(listOf("linuxathenadebug", "linuxathenarelease", "linuxx86-64debug"), null))
    }

    @Test
    fun `a desktop debug target is used when the robot's toolchain is not installed`()
    {
        assertEquals("windowsx86-64debug", choosePrimaryTarget(listOf("windowsx86-64debug", "windowsx86-64release"), null))
        assertNull(choosePrimaryTarget(emptyList(), null))
    }

    @Test
    fun `the robot toolchain is missing when no robot target was generated`()
    {
        assertTrue(hasRobotTarget(targets))
        assertTrue(hasRobotTarget(listOf("linuxathenadebug", "windowsx86-64debug")))
        assertFalse(hasRobotTarget(listOf("windowsx86-64debug", "windowsx86-64release")))
    }

    @Test
    fun `the SystemCore toolchain is installed from 2027 on, and the roboRIO toolchain before`()
    {
        assertEquals("installRoboRioToolchain", robotToolchainInstallTask(2026))
        assertEquals("installSystemCoreToolchain", robotToolchainInstallTask(2027))
        assertEquals("installSystemCoreToolchain", robotToolchainInstallTask(2028))
    }

    @Test
    fun `only projects whose WPILib language is C++ are C++ projects`(@TempDir projectRoot: Path)
    {
        assertFalse(isWpiLibCppProjectDir(projectRoot))
        val preferences = projectRoot.resolve(".wpilib").createDirectories().resolve("wpilib_preferences.json")
        preferences.writeText("""{"currentLanguage": "cpp", "projectYear": "2027_alpha7", "teamNumber": 3838}""")
        assertTrue(isWpiLibCppProjectDir(projectRoot))
        preferences.writeText("""{"currentLanguage": "java", "projectYear": "2027_alpha7", "teamNumber": 3838}""")
        assertFalse(isWpiLibCppProjectDir(projectRoot))
        preferences.writeText("not json")
        assertFalse(isWpiLibCppProjectDir(projectRoot))
    }

    @Test
    fun `the tests are added from the desktop target of the same build type`(@TempDir projectRoot: Path)
    {
        writeCompileCommands(projectRoot, "linuxsystemcoredebug", "src/main/cpp/Robot.cpp" to "g++")
        writeCompileCommands(projectRoot, "windowsx86-64debug", "src/main/cpp/Robot.cpp" to "cl.exe", "src/test/cpp/RobotTest.cpp" to "cl.exe")
        writeCompileCommands(projectRoot, "windowsx86-64release", "src/test/cpp/OtherTest.cpp" to "cl.exe")

        val merged = JsonParser.parseString(mergeCompileCommands(projectRoot, "linuxsystemcoredebug", findCompileCommandsTargets(projectRoot)))
            .asJsonArray.map { it.asJsonObject.get("file").asString to it.asJsonObject.get("arguments").asJsonArray[0].asString }

        assertEquals(listOf("src/main/cpp/Robot.cpp" to "g++", "src/test/cpp/RobotTest.cpp" to "cl.exe"), merged)
    }

    private fun writeCompileCommands(projectRoot: Path, target: String, vararg files: Pair<String, String>)
    {
        val dir = projectRoot.resolve("build/TargetedCompileCommands").resolve(target).createDirectories()
        val entries = files.joinToString(",") { (file, compiler) -> """{"directory": ".", "file": "$file", "arguments": ["$compiler", "-c"]}""" }
        dir.resolve(compileCommandsFileName).writeText("[$entries]")
    }
}
