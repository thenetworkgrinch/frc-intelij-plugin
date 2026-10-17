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

package net.javaru.iip.frc.wizard

import net.javaru.iip.frc.wpilib.version.WpiLibVersionImpl
import org.junit.jupiter.api.Assertions.assertEquals
import org.junit.jupiter.params.ParameterizedTest
import org.junit.jupiter.params.provider.CsvSource

internal class FrcProjectWizardDataTest
{
    private fun data(wpilibVersion: String, kotlinVersion: KotlinVersion) = FrcProjectWizardData(
        teamNumber = 1234,
        wpilibVersion = WpiLibVersionImpl.parse(wpilibVersion),
        kotlinVersion = kotlinVersion,
        // true short-circuits FrcProjectWizardData.gradleDistributionUrl's lookup of FrcApplicationSettings (an application service)
        useGradleAllDistribution = true,
                                                                                                 )

    @ParameterizedTest
    @CsvSource(
        "2026.2.1, 2.1.0, 2.1.0",
        // 2027 targets Java 25, which Kotlin supports from 2.3.0
        "2027.0.0-alpha-7, 2.1.0, 2.3.0",
        "2027.0.0-alpha-7, 2.4.0, 2.4.0",
              )
    fun `the Kotlin plugin version can target the year's Java version`(wpilibVersion: String, kotlinVersion: String, expected: String)
    {
        val (major, minor, patch) = kotlinVersion.split('.').map { it.toInt() }
        assertEquals(expected, data(wpilibVersion, KotlinVersion(major, minor, patch)).kotlinPluginVersion)
    }

    @ParameterizedTest
    @CsvSource(
        "2026.2.1, https\\://services.gradle.org/distributions/gradle-8.11-all.zip",
        "2027.0.0-alpha-7, https\\://services.gradle.org/distributions/gradle-9.4.1-all.zip",
              )
    fun `the Gradle wrapper version matches the year's official templates`(wpilibVersion: String, expected: String)
    {
        assertEquals(expected, data(wpilibVersion, KotlinVersion(2, 1, 0)).gradleDistributionUrl)
    }
}
