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

        val merged = mergeCompileCommands(listOf(projectRoot), null)!!

        assertEquals(mapOf(projectRoot to "linuxsystemcoredebug"), merged.primaryTargets)
        assertEquals(listOf("src/main/cpp/Robot.cpp" to "g++", "src/test/cpp/RobotTest.cpp" to "cl.exe"), merged.files())
    }

    @Test
    fun `the compile commands of several projects are merged, using a file compiled by several projects from the first`(@TempDir dir: Path)
    {
        val robot = dir.resolve("examples/robot")
        val library = dir.resolve("library")
        val shared = dir.resolve("shared/src/Shared.cpp").toString()
        writeCompileCommands(robot, "linuxsystemcoredebug", "src/main/cpp/Robot.cpp" to "g++", shared to "g++", directory = robot.toString())
        writeCompileCommands(library, "linuxsystemcoredebug", "../shared/src/Shared.cpp" to "lib-g++", "src/Library.cpp" to "lib-g++", directory = library.toString())

        val merged = mergeCompileCommands(listOf(robot, library), null)!!

        assertEquals(listOf("src/main/cpp/Robot.cpp" to "g++", shared to "g++", "src/Library.cpp" to "lib-g++"), merged.files())
        assertEquals(listOf("linuxsystemcoredebug", "linuxsystemcoredebug"), merged.primaryTargets.values.toList())
        assertNull(mergeCompileCommands(listOf(dir.resolve("none")), null))
    }

    @Test
    fun `WPILib C++ projects are found in subdirectories, but not in other WPILib projects or build directories`(@TempDir dir: Path)
    {
        writePreferences(dir.resolve("vendordep"), "cpp")
        writePreferences(dir.resolve("examples/cpptest"), "cpp")
        writePreferences(dir.resolve("examples/cpptest/nested"), "cpp")
        writePreferences(dir.resolve("examples/javatest"), "java")
        writePreferences(dir.resolve("examples/javatest/nested"), "cpp")
        writePreferences(dir.resolve("examples/build/generated"), "cpp")
        writePreferences(dir.resolve(".hidden/robot"), "cpp")
        writePreferences(dir.resolve("a/b/c/tooDeep"), "cpp")

        assertEquals(listOf(dir.resolve("examples/cpptest"), dir.resolve("vendordep")), findNestedCppProjectRoots(dir))
        assertEquals(listOf(dir.resolve("vendordep")), findNestedCppProjectRoots(dir.resolve("vendordep")))
    }

    @Test
    fun `robot projects are told apart from libraries by their frcUserProgram`(@TempDir dir: Path)
    {
        dir.resolve("robot").createDirectories().resolve("build.gradle").writeText("model { components { frcUserProgram(NativeExecutableSpec) {} } }")
        dir.resolve("library").createDirectories().resolve("build.gradle").writeText("model { components { YAMS(NativeLibrarySpec) {} } }")
        assertTrue(isRobotProjectDir(dir.resolve("robot")))
        assertFalse(isRobotProjectDir(dir.resolve("library")))
        assertFalse(isRobotProjectDir(dir.resolve("none")))
    }

    @Test
    fun `the project year is from the GradleRIO version, otherwise from the WPILib preferences`(@TempDir dir: Path)
    {
        val groovy = dir.resolve("groovy").createDirectories()
        groovy.resolve("build.gradle").writeText("""plugins {
            |    id "org.wpilib.GradleRIO" version "2027.0.0-alpha-7"
            |}""".trimMargin())
        writePreferences(groovy, "cpp", projectYear = "2026")
        assertEquals(2027, findProjectYear(groovy))

        val kotlin = dir.resolve("kotlin").createDirectories()
        kotlin.resolve("build.gradle.kts").writeText("""plugins { id("edu.wpi.first.GradleRIO") version "2026.2.1" }""")
        assertEquals(2026, findProjectYear(kotlin))

        val noGradleRio = dir.resolve("noGradleRio")
        writePreferences(noGradleRio, "cpp", projectYear = "Beta2025-2")
        assertEquals(2025, findProjectYear(noGradleRio))
        writePreferences(noGradleRio, "cpp", projectYear = "intellisense")
        assertNull(findProjectYear(noGradleRio))
    }

    private fun MergedCompileCommands.files(): List<Pair<String, String>> =
        JsonParser.parseString(json).asJsonArray.map { it.asJsonObject.get("file").asString to it.asJsonObject.get("arguments").asJsonArray[0].asString }

    private fun writePreferences(projectRoot: Path, language: String, projectYear: String = "2027")
    {
        projectRoot.resolve(".wpilib").createDirectories().resolve("wpilib_preferences.json")
            .writeText("""{"currentLanguage": "$language", "projectYear": "$projectYear", "teamNumber": 3838}""")
    }

    private fun writeCompileCommands(projectRoot: Path, target: String, vararg files: Pair<String, String>, directory: String = ".")
    {
        val dir = projectRoot.resolve("build/TargetedCompileCommands").resolve(target).createDirectories()
        val json = { s: String -> s.replace("\\", "\\\\") }
        val entries = files.joinToString(",") { (file, compiler) -> """{"directory": "${json(directory)}", "file": "${json(file)}", "arguments": ["$compiler", "-c"]}""" }
        dir.resolve(compileCommandsFileName).writeText("[$entries]")
    }
}
