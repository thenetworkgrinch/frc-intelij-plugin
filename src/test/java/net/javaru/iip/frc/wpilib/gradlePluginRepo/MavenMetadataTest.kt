/*
 * Copyright 2015-2020 the original author or authors
 *
 *     Licensed under the Apache License, Version 2.0 (the "License");
 *     you may not use this file except in compliance with the License.
 *     You may obtain a copy of the License at
 *
 *       http://www.apache.org/licenses/LICENSE-2.0
 *     
 *     Unless required by applicable law or agreed to in writing, software
 *     distributed under the License is distributed on an "AS IS" BASIS,
 *     WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *     See the License for the specific language governing permissions and
 *     limitations under the License.
 */

package net.javaru.iip.frc.wpilib.gradlePluginRepo

import net.javaru.iip.frc.util.fromJson
import net.javaru.iip.frc.util.lastCheckedDateTimeFormatter
import net.javaru.iip.frc.util.toJson
import net.javaru.iip.frc.wpilib.version.GradleRioVersionsForTesting.v2018_06_21
import net.javaru.iip.frc.wpilib.version.GradleRioVersionsForTesting.v2019_0_0_alpha_1
import net.javaru.iip.frc.wpilib.version.GradleRioVersionsForTesting.v2020_1_1_beta_3a
import org.intellij.lang.annotations.Language
import org.junit.jupiter.api.Assertions.*
import org.junit.jupiter.api.Tag
import org.junit.jupiter.api.Test
import org.junit.jupiter.api.assertAll


internal class MavenMetadataTest
{
    @Test
    fun parsingMavenMetadataTest()
    {
        val actual = parseMavenMetadata(mavenMetadataXML)
        assertEquals(mavenMetadata, actual)
    }
    
    @Test
    fun testWpiLibMavenMetadata()
    {
        val actual = WpiLibMavenMetadata(mavenMetadata)
        assertAll(
                { assertEquals(mavenMetadata, actual.mavenMetadata, "Wrong mavenMetadata") },
                { assertEquals(v2020_1_1_beta_3a, actual.versionAsWpiLibVersion, "Wrong versionAsWpiLibVersion") },
                { assertEquals(v2020_1_1_beta_3a, actual.latestAsWpiLibVersion, "Wrong latestAsWpiLibVersion") },
                { assertEquals(v2020_1_1_beta_3a, actual.releaseAsWpiLibVersion, "Wrong releaseAsWpiLibVersion") },
                { assertEquals(v2018_06_21, actual.wpiLibVersions[0], "Wrong first version value") },
                { assertEquals(v2019_0_0_alpha_1, actual.wpiLibVersions[1], "Wrong second version value") },
                { assertEquals(v2020_1_1_beta_3a, actual.wpiLibVersions.last(), "Wrong last version value") },
                { assertEquals("20191123193733", lastCheckedDateTimeFormatter.format(actual.lastUpdatedAsDateTime), "Wrong lastUpdatedAsDateTime") }
                 )
    }
    
    @Test
    fun testSerialization()
    {
        val mavenMetadataJSON = mavenMetadata.toJson(true)
        assertEquals(mavenMetadata, mavenMetadataJSON.fromJson<MavenMetadata>(), "Could not round trip serialize the mavenMetadata object")
    }

    @Test
    @Tag("slow")
    fun fetchWpiLibGradlePluginMavenMetadataTest()
    {
        val metadata = fetchGradleRioMavenMetadata()
        assertNotNull(metadata, "Could not download the latest WpiLib Gradle Plugin maven-metadata.")
    }
    
    companion object
    {
        
        @Language("XML")
        val mavenMetadataXML = """<?xml version='1.0' encoding='US-ASCII'?>
        <metadata>
            <groupId>edu.wpi.first.GradleRIO</groupId>
            <artifactId>edu.wpi.first.GradleRIO.gradle.plugin</artifactId>
            <version>2020.1.1-beta-3a</version>
            <versioning>
                <latest>2020.1.1-beta-3a</latest>
                <release>2020.1.1-beta-3a</release>
                <versions>
                    <version>2018.06.21</version>
                    <version>2019.0.0-alpha-1</version>
                    <version>2019.0.0-alpha-2</version>
                    <version>2019.0.0-alpha-3</version>
                    <version>2019.0.0-beta0-pre1</version>
                    <version>2019.0.0-beta0-pre3</version>
                    <version>2019.0.0-beta0-pre4</version>
                    <version>2019.0.0-beta0-pre5</version>
                    <version>2019.0.0-beta0-pre6</version>
                    <version>2019.1.1-beta-1</version>
                    <version>2019.1.1-beta-2a</version>
                    <version>2019.1.1-beta-3</version>
                    <version>2019.1.1-beta-3a</version>
                    <version>2019.1.1-beta-3-p-2</version>
                    <version>2019.1.1-beta-3-pre3</version>
                    <version>2019.1.1-beta-3-pre4</version>
                    <version>2019.1.1-beta-3-pre5</version>
                    <version>2019.1.1-beta-3-pre6</version>
                    <version>2019.1.1-beta-3-pre7</version>
                    <version>2019.1.1-beta-3-pre8</version>
                    <version>2019.1.1-beta-3-pre9</version>
                    <version>2019.1.1-beta-4</version>
                    <version>2019.1.1-beta-4a</version>
                    <version>2019.1.1-beta-4b</version>
                    <version>2019.1.1-beta-4c</version>
                    <version>2019.1.1-beta-4-pre1</version>
                    <version>2019.1.1-beta-4-pre2</version>
                    <version>2019.1.1-beta-4-pre4</version>
                    <version>2019.1.1-rc-1</version>
                    <version>2019.1.1</version>
                    <version>2019.2.1</version>
                    <version>2019.3.1</version>
                    <version>2019.3.2</version>
                    <version>2019.4.1</version>
                    <version>2020.1.1-beta-1</version>
                    <version>2020.1.1-beta-2</version>
                    <version>2020.1.1-beta-3</version>
                    <version>2020.1.1-beta-3a</version>
                </versions>
                <lastUpdated>20191123193733</lastUpdated>
            </versioning>
        </metadata>    
        """.trimIndent()

        val expectedVersionStrings = listOf(
                "2018.06.21",
                "2019.0.0-alpha-1",
                "2019.0.0-alpha-2",
                "2019.0.0-alpha-3",
                "2019.0.0-beta0-pre1",
                "2019.0.0-beta0-pre3",
                "2019.0.0-beta0-pre4",
                "2019.0.0-beta0-pre5",
                "2019.0.0-beta0-pre6",
                "2019.1.1-beta-1",
                "2019.1.1-beta-2a",
                "2019.1.1-beta-3",
                "2019.1.1-beta-3a",
                "2019.1.1-beta-3-p-2",
                "2019.1.1-beta-3-pre3",
                "2019.1.1-beta-3-pre4",
                "2019.1.1-beta-3-pre5",
                "2019.1.1-beta-3-pre6",
                "2019.1.1-beta-3-pre7",
                "2019.1.1-beta-3-pre8",
                "2019.1.1-beta-3-pre9",
                "2019.1.1-beta-4",
                "2019.1.1-beta-4a",
                "2019.1.1-beta-4b",
                "2019.1.1-beta-4c",
                "2019.1.1-beta-4-pre1",
                "2019.1.1-beta-4-pre2",
                "2019.1.1-beta-4-pre4",
                "2019.1.1-rc-1",
                "2019.1.1",
                "2019.2.1",
                "2019.3.1",
                "2019.3.2",
                "2019.4.1",
                "2020.1.1-beta-1",
                "2020.1.1-beta-2",
                "2020.1.1-beta-3",
                "2020.1.1-beta-3a")

        val mavenMetadata = MavenMetadata("edu.wpi.first.GradleRIO", "edu.wpi.first.GradleRIO.gradle.plugin", "2020.1.1-beta-3a", "2020.1.1-beta-3a", "2020.1.1-beta-3a", expectedVersionStrings, "20191123193733")

    }

    @Test
    fun mergesTheGradleRioMetadataFromBeforeAndAfterTheMoveToOrgWpilib()
    {
        val legacy = MavenMetadata("edu.wpi.first.GradleRIO", "edu.wpi.first.GradleRIO.gradle.plugin", "2026.2.1", "2026.2.1", "2026.2.1",
                                   listOf("2026.1.1", "2026.2.1"), "20260215000000")
        val current = MavenMetadata("org.wpilib.GradleRIO", "org.wpilib.GradleRIO.gradle.plugin", "2027.0.0-alpha-7", "2027.0.0-alpha-7", "2027.0.0-alpha-7",
                                    listOf("2027.0.0-alpha-6", "2027.0.0-alpha-7"), "20260930000000")
        val merged = WpiLibMavenMetadata(mergeMavenMetadata(legacy, current))
        assertAll(
            { assertEquals(listOf("2026.1.1", "2026.2.1", "2027.0.0-alpha-6", "2027.0.0-alpha-7"), merged.mavenMetadata.versions) },
            { assertEquals("2027.0.0-alpha-7", merged.mavenMetadata.latest) },
            { assertEquals("2027.0.0-alpha-7", merged.mavenMetadata.release) },
            { assertEquals("20260930000000", merged.mavenMetadata.lastUpdated) },
            { assertEquals("2027.0.0-alpha-7", merged.wpiLibVersionsDescending.first().versionString) },
                 )
    }
}
