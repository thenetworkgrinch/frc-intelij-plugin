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

package net.javaru.iip.frc.wpilib.vendordeps

import com.github.michaelbull.result.getOrThrow
import org.junit.jupiter.params.ParameterizedTest
import org.junit.jupiter.params.provider.CsvSource
import java.util.*
import kotlin.test.assertEquals
import kotlin.test.assertTrue

internal class VendorJsonRepoTest
{
    @ParameterizedTest
    @CsvSource(
        "2026.1.0, 2026.0.4",
        "2026.10.1, 2026.9.16",
        "2026.1.26.1, 2026.1.26",
        "2026.2.13, 2026.2.09",
        "2026.1.1, 2026.1.1-rc-4",
        "2026.1.1-rc-4, 2026.1.1-rc-3",
        "v2026.3.4, v2026.3.3",
        "26.3.0, 26.2.0",
              )
    fun `newer version compares greater than older version`(newer: String, older: String)
    {
        assertTrue(compareVersionText(newer, older) > 0, "Expected $newer > $older")
        assertTrue(compareVersionText(older, newer) < 0, "Expected $older < $newer")
    }

    @ParameterizedTest
    @CsvSource(
        "2027.0.0-alpha-7, 2027_alpha7",
        "2027.0.0-alpha7,  2027_alpha7",
        "2026.0.0-beta-3,  2026beta",
        "2026.2.1,         2026",
        "2025.3.2,         2025",
        "latest.release,   ",
              )
    fun `the vendor repo bundle is named from the GradleRIO version`(gradleRioVersion: String, expected: String?)
    {
        assertEquals(expected, vendorRepoBundleName(gradleRioVersion))
    }

    @ParameterizedTest
    @CsvSource(
        "'\"wpilibYear\": \"2027_alpha7\"', 2027", // 2027 vendordeps, e.g. YAMS's (versioned by date, e.g. 2026.10.15)
        "'\"frcYear\": 2026',               2026",
        "'\"frcYear\": \"2026beta\"',       2026",
        "'\"frcYear\": 2026, \"wpilibYear\": \"2027_alpha7\"', 2027", // a 2027 vendordeps that kept its frcYear
        "'\"other\": 1',                    ",
              )
    fun `the season is read from frcYear (before 2027) and wpilibYear (2027 on)`(yearProperty: String, expected: Int?)
    {
        val json = """{"name": "YAMS", "version": "2026.10.15", "uuid": "a1051e86-a979-4880-a28b-a0d5362d1d96", "fileName": "yams.json", $yearProperty}"""
        val vendordeps = Vendordeps.parse(json).getOrThrow()
        assertEquals(expected, vendordeps.frcYear)
        if (expected == 2027) assertEquals(2027, vendordeps.likelySeasonYear())
    }

    @ParameterizedTest
    @CsvSource(
        "2027.0.0-alpha-3, 2026, 2027", // ChoreoLib's jsonUrl: frcYear not updated for the next season's alpha
        "2027.2.0,         ,     2027", // DogLog's jsonUrl: no frcYear
        "v2027.0.0-alpha-2,,     2027", // photonlib's jsonUrl
        "26.3.0,           2026, 2026", // CTRE Phoenix 6
        "26.0.2,           ,     2026", // AdvantageKit
        "2026.9.17,        2026, 2026", // YAGSL
        "5.36.0,           2026, 2026", // CTRE Phoenix 5
        "0.4.0-beta,       ,         ", // maple-sim
        "1.0.0,            ,         ", // WPILibNewCommands
              )
    fun `likely season year is determined from frcYear and version`(version: String, frcYear: Int?, expected: Int?)
    {
        val vendordeps = Vendordeps(UUID.randomUUID(), "Test", LibVersion.parse(version), frcYear, "Test.json", null, emptyList())
        assertEquals(expected, vendordeps.likelySeasonYear())
    }
}
