/*
 * Copyright 2015-2021 the original author or authors.
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

import net.javaru.iip.frc.assertPathsEqual
import net.javaru.iip.frc.setInTestModeSystemProperty
import net.javaru.iip.frc.wpilib.version.WpiLibVersionImpl
import org.apache.commons.lang3.SystemUtils
import org.junit.jupiter.api.Assertions.assertEquals
import org.junit.jupiter.api.Assumptions.*
import org.junit.jupiter.api.BeforeAll
import org.junit.jupiter.api.Test
import org.junit.jupiter.api.assertAll
import org.junit.jupiter.params.ParameterizedTest
import org.junit.jupiter.params.provider.CsvSource
import java.nio.file.Paths


internal class WpiLibHelpersKtTest
{

    @Suppress("unused")
    companion object
    {
        @BeforeAll
        @JvmStatic
        fun initAll()
        {
            setInTestModeSystemProperty()
        }
    }

    @Test
    fun getWpiLibRootTest()
    {
        assumingThat(SystemUtils.IS_OS_WINDOWS) {
            assertAll({ assertPathsEqual(Paths.get("C:\\Users\\Public\\frc2019"), getWpiLibRootPath(2019, project = null)) },
                      { assertPathsEqual(Paths.get("C:\\Users\\Public\\wpilib\\2020"), getWpiLibRootPath(2020, project = null)) },
                      { assertPathsEqual(Paths.get("C:\\Users\\Public\\wpilib\\2021"), getWpiLibRootPath(2021, project = null)) },
                      { assertPathsEqual(Paths.get("C:\\Users\\Public\\wpilib\\2020"), getWpiLibRootPath(WpiLibVersionImpl.parse("2020.1.2"), project = null)) })
        }
// Disabling for now as it fails on CI/CD as it tries to display the Notification (and fails) despite setting "frc.testing.inUnitTestMode"
// Tried setting it in build script as well, and it still did not work. Will investigate later when time allows
//        assumingThat(!SystemUtils.IS_OS_WINDOWS) {
//            val home = SystemUtils.getUserHome()?.toPath()
//            assumeTrue(home != null) {
//                "Cannot test getWpiLibRootPath as user home was null"
//            }
//            assertAll({ assertPathsEqual(home?.resolve("frc2019"), getWpiLibRootPath(2019)) },
//                      { assertPathsEqual(home?.resolve("wpilib/2020"), getWpiLibRootPath(2020)) },
//                      { assertPathsEqual(home?.resolve("wpilib/2021"), getWpiLibRootPath(2021)) },
//                      { assertPathsEqual(home?.resolve("wpilib/2020"), getWpiLibRootPath(WpiLibVersionImpl.parse("2020.1.2"))) })
//        }
    }


    // Needs to be run manually since the local machine may not have wpilib installed
    //@Test
    //fun getWpiLibJdkReleaseJavaVersionTest()
    //{
    //    assertAll(
    //            { assertEquals("11.0.1", getWpiLibJdkReleaseJavaVersionString(2019)) },
    //            { assertEquals(com.intellij.util.lang.JavaVersion.tryParse("11.0.1"), getWpiLibJdkReleaseJavaVersion(2019)) },
    //            { assertEquals(11, getWpiLibJdkReleaseJavaFeatureVersion(2019)) }
    //             )
    //}

    @ParameterizedTest
    @CsvSource(
        "2026.2.1, 2026",
        "2027.0.0-alpha-7, 2027_alpha7",
        "2027.1.1, 2027",
                                                 )
    fun determinesTheProjectYearForTheWpiLibVersion(version: String, expected: String)
    {
        // From 2027 on, the project year is the WPILib installer's, which settings.gradle and the vendordeps' wpilibYear use
        assertEquals(expected, determineProjectYearStringForVersion(WpiLibVersionImpl.parse(version)))
    }

    @Test
    fun `wpiLibHomeRoot is wpilib in the base path before 2027 on Linux, and on other systems`()
    {
        val home = Paths.get("/home/frc")
        assertAll({ assertPathsEqual(home.resolve("wpilib"), wpiLibHomeRoot(2026, home, isLinux = true, xdgDataHome = "/data")) },
                  { assertPathsEqual(home.resolve("wpilib"), wpiLibHomeRoot(2027, home, isLinux = false, xdgDataHome = "/data")) })
    }

    @Test
    fun `wpiLibHomeRoot is wpilib in the XDG data directory from 2027 on Linux`()
    {
        val home = Paths.get("/home/frc")
        assertAll({ assertPathsEqual(Paths.get("/data/wpilib"), wpiLibHomeRoot(2027, home, isLinux = true, xdgDataHome = "/data")) },
                  { assertPathsEqual(home.resolve(".local/share/wpilib"), wpiLibHomeRoot(2027, home, isLinux = true, xdgDataHome = null)) },
                  { assertPathsEqual(home.resolve(".local/share/wpilib"), wpiLibHomeRoot(2028, home, isLinux = true, xdgDataHome = " ")) },
                  // A relative XDG_DATA_HOME is ignored
                  { assertPathsEqual(home.resolve(".local/share/wpilib"), wpiLibHomeRoot(2027, home, isLinux = true, xdgDataHome = "data")) })
    }
}
