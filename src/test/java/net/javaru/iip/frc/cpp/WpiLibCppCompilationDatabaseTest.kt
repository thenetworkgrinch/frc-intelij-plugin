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

import com.google.gson.JsonArray
import com.google.gson.JsonObject
import com.google.gson.JsonParser
import org.junit.jupiter.api.Test
import org.junit.jupiter.api.io.TempDir
import java.nio.file.Path
import kotlin.io.path.createDirectories
import kotlin.io.path.name
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
    fun `the library headers get the project's compile command, without its output`(@TempDir dir: Path)
    {
        val projectRoot = dir.resolve("robot")
        val libraryHeaders = dir.resolve("caches/transformed/wpimath-cpp-2027.0.0-headers").createDirectories()
        listOf("wpi/math/Pose2d.hpp", "Eigen/Core", "gcem.h", "LICENSE", "README.md", "Eigen/src/Core/util/Macros.inc")
            .forEach { libraryHeaders.resolve(it).also { file -> file.parent.createDirectories() }.writeText("") }
        val otherIncludeDir = dir.resolve("include").createDirectories().also { it.resolve("Other.h").writeText("") }
        val source = projectRoot.resolve("src/main/cpp/Robot.cpp").toString()
        val dbDir = projectRoot.resolve("build/TargetedCompileCommands/linuxsystemcoredebug").createDirectories()
        val entry = JsonObject().apply {
            addProperty("directory", projectRoot.toString())
            addProperty("file", source)
            add("arguments", JsonArray().apply {
                listOf("g++", "-x", "c++", "-c", "-I", libraryHeaders.toString(), "-isystem", otherIncludeDir.toString(), "-o", "Robot.o", source).forEach { add(it) }
            })
        }
        dbDir.resolve(compileCommandsFileName).writeText(JsonArray().apply { add(entry) }.toString())

        val entries = JsonParser.parseString(mergeCompileCommands(listOf(projectRoot), null)!!.json).asJsonArray.map { it.asJsonObject }

        val headers = listOf("Eigen/Core", "gcem.h", "wpi/math/Pose2d.hpp").map { libraryHeaders.resolve(it).toString() }
        assertEquals(listOf(source) + headers, entries.map { it.get("file").asString })
        assertEquals(listOf("g++", "-x", "c++", "-c", "-I", libraryHeaders.toString(), "-isystem", otherIncludeDir.toString(), headers[0]),
                     entries[1].getAsJsonArray("arguments").map { it.asString })
        assertEquals(projectRoot.toString(), entries[1].get("directory").asString)
    }

    @Test
    fun `a header directory is from the vendordep that has its artifact, otherwise from WPILib`(@TempDir projectRoot: Path)
    {
        val vendordeps = projectRoot.resolve("vendordeps").createDirectories()
        vendordeps.resolve("Phoenix6.json").writeText("""{"name": "CTRE-Phoenix (v6)", "cppDependencies": [
            |{"artifactId": "wpiapi-cpp", "version": "26.70.0"}, {"artifactId": "tools", "version": "26.70.0"}, {"artifactId": "tools-sim", "version": "26.70.0"}]}""".trimMargin())
        vendordeps.resolve("CommandsV2.json").writeText("""{"name": "Commands V2", "cppDependencies": [{"artifactId": "commandsv2-cpp", "version": "wpilib"}]}""")
        vendordeps.resolve("CommandsV3.json").writeText("""{"name": "Commands v3", "cppDependencies": []}""")
        vendordeps.resolve("broken.json").writeText("not json")

        val artifactIds = findVendordepCppArtifactIds(projectRoot)

        assertEquals(mapOf("Commands V2" to setOf("commandsv2-cpp"), "CTRE-Phoenix (v6)" to setOf("wpiapi-cpp", "tools", "tools-sim")), artifactIds)
        assertEquals("CTRE-Phoenix (v6)", findHeaderDirLibrary("wpiapi-cpp-26.70.0-alpha-2-headers", artifactIds))
        assertEquals("CTRE-Phoenix (v6)", findHeaderDirLibrary("tools-sim-26.70.0-alpha-2-headers", artifactIds))
        assertEquals("Commands V2", findHeaderDirLibrary("commandsv2-cpp-2027.0.0-alpha-7-headers", artifactIds))
        assertEquals(wpiLibHeadersLibraryName, findHeaderDirLibrary("wpimath-cpp-2027.0.0-alpha-7-headers", artifactIds))
        assertEquals(wpiLibHeadersLibraryName, findHeaderDirLibrary("tools-extra-1.0-headers", artifactIds))
    }

    @Test
    fun `the headers of disabled libraries get no compile commands`(@TempDir dir: Path)
    {
        val projectRoot = dir.resolve("robot")
        projectRoot.resolve("vendordeps").createDirectories().resolve("REVLib.json")
            .writeText("""{"name": "REVLib", "cppDependencies": [{"artifactId": "REVLib-cpp", "version": "2027.0.0"}]}""")
        val wpiMath = dir.resolve("wpimath-cpp-2027.0.0-headers").createDirectories().also { it.resolve("Pose2d.hpp").writeText("") }
        val revLib = dir.resolve("REVLib-cpp-2027.0.0-headers").createDirectories().also { it.resolve("SparkMax.h").writeText("") }
        val source = projectRoot.resolve("src/main/cpp/Robot.cpp").toString()
        val entry = JsonObject().apply {
            addProperty("directory", projectRoot.toString())
            addProperty("file", source)
            add("arguments", JsonArray().apply { listOf("g++", "-I", wpiMath.toString(), "-I$revLib", source).forEach { add(it) } })
        }
        projectRoot.resolve("build/TargetedCompileCommands/linuxsystemcoredebug").createDirectories().resolve(compileCommandsFileName)
            .writeText(JsonArray().apply { add(entry) }.toString())
        fun headerFiles(disabled: Set<String>) = mergeCompileCommands(listOf(projectRoot), null, disabled)!!.let { merged ->
            merged.libraryHeaderCount to JsonParser.parseString(merged.json).asJsonArray.drop(1).map { Path.of(it.asJsonObject.get("file").asString).name }
        }

        assertEquals(2 to listOf("Pose2d.hpp", "SparkMax.h"), headerFiles(emptySet()))
        assertEquals(1 to listOf("Pose2d.hpp"), headerFiles(setOf("REVLib")))
        assertEquals(1 to listOf("SparkMax.h"), headerFiles(setOf(wpiLibHeadersLibraryName)))
        assertEquals(0 to emptyList(), headerFiles(setOf(wpiLibHeadersLibraryName, "REVLib")))
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
