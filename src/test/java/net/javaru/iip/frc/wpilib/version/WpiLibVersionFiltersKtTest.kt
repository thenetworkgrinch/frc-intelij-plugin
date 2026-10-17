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

@file:Suppress("LocalVariableName", "RemoveRedundantQualifierName")

package net.javaru.iip.frc.wpilib.version

import net.javaru.iip.frc.wpilib.version.GradleRioVersionsForTesting.versions
import net.javaru.iip.frc.setInTestModeSystemProperty
import org.junit.jupiter.api.Assertions.*
import org.junit.jupiter.api.BeforeAll
import org.junit.jupiter.api.Test
import org.junit.jupiter.api.assertAll
import net.javaru.iip.frc.wpilib.version.GradleRioVersionsForTesting as GRV


internal class WpiLibVersionFiltersKtTest
{
    companion object
    {
        @JvmStatic
        @BeforeAll
        fun beforeAll()
        {
            setInTestModeSystemProperty()
        }
    }

    @Test
    fun filterVersions()
    {
        assertAll(
                { assertEquals(GRV.releases, GRV.versions.filterVersions(IsReleaseFilter), "Wrong values for IsReleaseFilter") },
                { assertEquals(GRV.releaseCandidates, GRV.versions.filterVersions(IsReleaseCandidateFilter), "Wrong values for IsReleaseCandidateFilter") }
                 )
    }

    @Test
    fun filterOrTest()
    {
        assertAll(
                { assertEquals(GRV.releaseAndReleaseCandidates, GRV.versions.filterVersions(IsReleaseFilter.or(IsReleaseCandidateFilter)), "failed for ThisFilter.or(ThatFilter)") },
                { assertEquals(GRV.releaseAndReleaseCandidates, GRV.versions.filterVersions(WpiLibVersionFilter.or(IsReleaseFilter, IsReleaseCandidateFilter)), "failed for WpiLibVersionFilter.or(filter1, filter2)") }
                 )
    }

    @Test
    fun filterAndTest()
    {
        val expected = GRV.betas.filter { it.versionString.startsWith("2019") }
        assertAll(
                { assertEquals(expected, GRV.versions.filterVersions(IsBetaFilter.and(YearFilter(2019, false))), "failed for ThisFilter.and(ThatFilter)") },
                { assertEquals(expected, GRV.versions.filterVersions(WpiLibVersionFilter.and(IsBetaFilter, YearFilter(2019, false))), "failed for WpiLibVersionFilter.and(filter1, filter2)") }
                 )
    }
    
    @Test
    fun filterAndNotTest()
    {
        val expected = GRV.betas.filter { !it.versionString.startsWith("2019") }
        assertAll(
                { assertEquals(expected, GRV.versions.filterVersions(IsBetaFilter.andNot(YearFilter(2019, false))), "failed for ThisFilter.and(ThatFilter)") },
                { assertEquals(expected, GRV.versions.filterVersions(WpiLibVersionFilter.and(IsBetaFilter, WpiLibVersionFilter.not(YearFilter(2019, false)))), "failed for WpiLibVersionFilter.and(filter1, not(filter2))") }
                 )
    }
    
    @Test
    fun individualFilterTests()
    {
        assertAll(
                { assertEquals(GRV.betas, GRV.betasIncludingPreviews.filterVersions(IsNotPreReleasePreviewFilter), "Test 1 failed")},
                { assertEquals(GRV.betas, GRV.betasIncludingPreviews.filterVersions(IsPreReleasePreviewFilter.not()), "Test 2 failed")},
                { assertEquals(emptyList<WpiLibVersion>(), GRV.betas.filterOutVersions(IsPreReleasePreviewFilter.not()), "Test 3 failed")}
                 )
    }

    @Test
    fun yearFilterTest()
    {
        assertAll(
                { assertEquals(listOf(GRV.v2020_1_1, GRV.v2020_1_2, GRV.v2020_2_1, GRV.v2020_2_2, GRV.v2020_3_1), GRV.versions.filterVersions(YearFilter(2020, true)), "Test 1 failed") },
                { assertEquals(GRV.versions.filter { it.versionString.startsWith("2020") }, GRV.versions.filterVersions(YearFilter(2020, false)), "Test 2 failed") },
                { assertEquals(GRV.versions.filter { it.versionString.startsWith("2019") }, GRV.versions.filterVersions(YearFilter(2019, false)), "Test 3 failed") }
                 )
        
    }

    @Test
    fun filterOutVersions() = assertEquals(GRV.betas, GRV.betasIncludingPreviews.filterOutVersions(IsPreReleasePreviewFilter))
    
    @Test
    fun filterOutTransitionalVersions() = assertEquals(listOf(GRV.v2018_06_21), GRV.versions.filterVersions(Is2018TransitionalRelease))

    @Test
    fun filterOutAllButLatestForYear()
    {

        val list2019 = listOf(
            GRV.v2019_0_0_alpha_1,
            GRV.v2019_0_0_alpha_2_pre1,
            GRV.v2019_0_0_alpha_2,
            GRV.v2019_0_0_alpha_3,
            GRV.v2019_0_0_beta0_pre1,
            GRV.v2019_0_0_beta0_pre3,
            GRV.v2019_0_0_beta0_pre4,
            GRV.v2019_0_0_beta0_pre5,
            GRV.v2019_0_0_beta0_pre6,
            GRV.v2019_0_1,
            GRV.v2019_1_1_beta_1,
            GRV.v2019_1_1_beta_2a,
            GRV.v2019_1_1_beta_3_pre1,
            GRV.v2019_1_1_beta_3_p_2,
            GRV.v2019_1_1_beta_3_pre3,
            GRV.v2019_1_1_beta_3_pre4,
            GRV.v2019_1_1_beta_3_pre5,
            GRV.v2019_1_1_beta_3_pre6,
            GRV.v2019_1_1_beta_3_pre7,
            GRV.v2019_1_1_beta_3_pre8,
            GRV.v2019_1_1_beta_3_pre9,
            GRV.v2019_1_1_beta_3_pre10,
            GRV.v2019_1_1_beta_3,
            GRV.v2019_1_1_beta_3a,
            GRV.v2019_1_1_beta_4_pre1,
            GRV.v2019_1_1_beta_4_pre2,
            GRV.v2019_1_1_beta_4_pre4,
            GRV.v2019_1_1_beta_4,
            GRV.v2019_1_1_beta_4a,
            GRV.v2019_1_1_beta_4b,
            GRV.v2019_1_1_beta_4c,
            GRV.v2019_1_1_beta_5,
            GRV.v2019_1_1_beta_99,
            GRV.v2019_1_1_rc_1,
            GRV.v2019_1_1,
            GRV.v2019_1_2,
            GRV.v2019_2_1,
            GRV.v2019_3_1_rc,
            GRV.v2019_3_1,
            GRV.v2019_3_2_rc,
            GRV.v2019_3_2_rc2,
            GRV.v2019_3_2,
            GRV.v2019_4_1_rc1,
            GRV.v2019_4_1_rc2,
            GRV.v2019_4_1_rc3,
                             )
        val list2020NoPre = listOf(
            GRV.v2020_1_1_beta_1,
            GRV.v2020_1_1_beta_2,
            GRV.v2020_1_1_beta_3,
            GRV.v2020_1_1_beta_3a,
            GRV.v2020_1_1,
            GRV.v2020_1_2_rc_1_pre1,
            GRV.v2020_1_2_rc_1,
            GRV.v2020_1_2,
            GRV.v2020_2_1,
            GRV.v2020_2_2,
            GRV.v2020_3_1,
                                  )

        val ver2020_4_1_alpha_1 = WpiLibVersionImpl.parse("2020.4.1-alpha-1")
        val ver2020_4_1_alpha_2 = WpiLibVersionImpl.parse("2020.4.1-alpha-2")
        val list2020AndNextAlpha = list2020NoPre.toMutableList().apply {
            add(ver2020_4_1_alpha_1)
            add(ver2020_4_1_alpha_2)
        }.toList()

        val ver2020_4_1_beta_1 = WpiLibVersionImpl.parse("2020.4.1-beta-1")
        val list2020AndNextBeta1 = list2020AndNextAlpha.toMutableList().apply {
            add(ver2020_4_1_beta_1)
        }.toList()
        val ver2020_4_1_beta_2 = WpiLibVersionImpl.parse("2020.4.1-beta-2")
        val list2020AndNextBeta2 = list2020AndNextBeta1.toMutableList().apply {
            add(ver2020_4_1_beta_2)
        }.toList()
        
        val ver2020_4_1_beta_3 = WpiLibVersionImpl.parse("2020.4.1-beta-3")
        val list2020AndNextBeta3 = list2020AndNextBeta2.toMutableList().apply {
            add(ver2020_4_1_beta_3)
        }.toList()
        
        val ver2020_4_1_rc_1 = WpiLibVersionImpl.parse("2020.4.1-rc-1")
        val list2020AndNextRc1 = list2020AndNextBeta3.toMutableList().apply {
            add(ver2020_4_1_rc_1)
        }.toList()
        
        val ver2020_4_1_rc_2 = WpiLibVersionImpl.parse("2020.4.1-rc-2")
        val list2020AndNextRc2 = list2020AndNextRc1.toMutableList().apply {
            add(ver2020_4_1_rc_2)
        }.toList()

        val ver2020_4_1 = WpiLibVersionImpl.parse("2020.4.1")
        val list2020AndNextFull = list2020AndNextRc2.toMutableList().apply {
            add(ver2020_4_1)
        }.toList()

        val list2019Basic = listOf(
            GRV.v2019_0_1,
            GRV.v2019_1_1,
            GRV.v2019_1_2,
            GRV.v2019_2_1,
            GRV.v2019_3_1,
            GRV.v2019_3_2,
                                  )
        val list2021Basic = listOf(
            GRV.v2021_1_2,
            GRV.v2021_2_1,
            GRV.v2021_2_2,
            GRV.v2021_3_1,
                                  )

        assertAll(
            { assertEquals(listOf(GRV.v2019_3_2), list2019.filterOutAllButLatestForYear(2019, PreReleaseInclusion.None), "Case 2019 None") },
            { assertEquals(listOf(GRV.v2019_3_2, GRV.v2019_4_1_rc3 ), list2019.filterOutAllButLatestForYear(2019, PreReleaseInclusion.RcOnly), "Case 2019 RcOnly") },
            { assertEquals(listOf(GRV.v2019_3_2, GRV.v2019_4_1_rc3 ), list2019.filterOutAllButLatestForYear(2019, PreReleaseInclusion.RcAndOrBeta), "Case 2019 RcAndOrBeta") },
            { assertEquals(listOf(GRV.v2019_3_2, GRV.v2019_4_1_rc3 ), list2019.filterOutAllButLatestForYear(2019, PreReleaseInclusion.All), "Case 2019 All") },


            { assertEquals(listOf(GRV.v2020_3_1), list2020NoPre.filterOutAllButLatestForYear(2020, PreReleaseInclusion.None), "Case 2020-noPre None") },
            { assertEquals(listOf(GRV.v2020_3_1), list2020NoPre.filterOutAllButLatestForYear(2020, PreReleaseInclusion.RcOnly), "Case 2020-noPre RcOnly") },
            { assertEquals(listOf(GRV.v2020_3_1), list2020NoPre.filterOutAllButLatestForYear(2020, PreReleaseInclusion.RcAndOrBeta), "Case 2020-noPre RcAndOrBeta") },
            { assertEquals(listOf(GRV.v2020_3_1), list2020NoPre.filterOutAllButLatestForYear(2020, PreReleaseInclusion.All), "Case 2020-noPre All") },

            { assertEquals(listOf(GRV.v2020_3_1), list2020AndNextAlpha.filterOutAllButLatestForYear(2020, PreReleaseInclusion.None), "Case 2020-andAlpha None") },
            { assertEquals(listOf(GRV.v2020_3_1), list2020AndNextAlpha.filterOutAllButLatestForYear(2020, PreReleaseInclusion.RcOnly), "Case 2020-andAlpha RcOnly") },
            { assertEquals(listOf(GRV.v2020_3_1), list2020AndNextAlpha.filterOutAllButLatestForYear(2020, PreReleaseInclusion.RcAndOrBeta), "Case 2020-andAlpha RcAndOrBeta") },
            { assertEquals(listOf(GRV.v2020_3_1, ver2020_4_1_alpha_2), list2020AndNextAlpha.filterOutAllButLatestForYear(2020, PreReleaseInclusion.All), "Case 2020-andAlpha All") },

            { assertEquals(listOf(GRV.v2020_3_1), list2020AndNextBeta1.filterOutAllButLatestForYear(2020, PreReleaseInclusion.None), "Case 2020-andBeta1 None") },
            { assertEquals(listOf(GRV.v2020_3_1), list2020AndNextBeta1.filterOutAllButLatestForYear(2020, PreReleaseInclusion.RcOnly), "Case 2020-andBeta1 RcOnly") },
            { assertEquals(listOf(GRV.v2020_3_1, ver2020_4_1_beta_1), list2020AndNextBeta1.filterOutAllButLatestForYear(2020, PreReleaseInclusion.RcAndOrBeta), "Case 2020-andBeta1 RcAndOrBeta") },
            { assertEquals(listOf(GRV.v2020_3_1, ver2020_4_1_beta_1), list2020AndNextBeta1.filterOutAllButLatestForYear(2020, PreReleaseInclusion.All), "Case 2020-andBeta1 All") },

            { assertEquals(listOf(GRV.v2020_3_1), list2020AndNextBeta2.filterOutAllButLatestForYear(2020, PreReleaseInclusion.None), "Case 2020-andBeta2 None") },
            { assertEquals(listOf(GRV.v2020_3_1), list2020AndNextBeta2.filterOutAllButLatestForYear(2020, PreReleaseInclusion.RcOnly), "Case 2020-andBeta2 RcOnly") },
            { assertEquals(listOf(GRV.v2020_3_1, ver2020_4_1_beta_2), list2020AndNextBeta2.filterOutAllButLatestForYear(2020, PreReleaseInclusion.RcAndOrBeta), "Case 2020-andBeta2 RcAndOrBeta") },
            { assertEquals(listOf(GRV.v2020_3_1, ver2020_4_1_beta_2), list2020AndNextBeta2.filterOutAllButLatestForYear(2020, PreReleaseInclusion.All), "Case 2020-andBeta2 All") },

            { assertEquals(listOf(GRV.v2020_3_1), list2020AndNextBeta3.filterOutAllButLatestForYear(2020, PreReleaseInclusion.None), "Case 2020-andBeta3 None") },
            { assertEquals(listOf(GRV.v2020_3_1), list2020AndNextBeta3.filterOutAllButLatestForYear(2020, PreReleaseInclusion.RcOnly), "Case 2020-andBeta3 RcOnly") },
            { assertEquals(listOf(GRV.v2020_3_1, ver2020_4_1_beta_3), list2020AndNextBeta3.filterOutAllButLatestForYear(2020, PreReleaseInclusion.RcAndOrBeta), "Case 2020-andBeta3 RcAndOrBeta") },
            { assertEquals(listOf(GRV.v2020_3_1, ver2020_4_1_beta_3), list2020AndNextBeta3.filterOutAllButLatestForYear(2020, PreReleaseInclusion.All), "Case 2020-andBeta3 All") },

            { assertEquals(listOf(GRV.v2020_3_1), list2020AndNextRc1.filterOutAllButLatestForYear(2020, PreReleaseInclusion.None), "Case 2020-andRc1 None") },
            { assertEquals(listOf(GRV.v2020_3_1, ver2020_4_1_rc_1), list2020AndNextRc1.filterOutAllButLatestForYear(2020, PreReleaseInclusion.RcOnly), "Case 2020-andRc1 RcOnly") },
            { assertEquals(listOf(GRV.v2020_3_1, ver2020_4_1_rc_1), list2020AndNextRc1.filterOutAllButLatestForYear(2020, PreReleaseInclusion.RcAndOrBeta), "Case 2020-andRc1 RcAndOrBeta") },
            { assertEquals(listOf(GRV.v2020_3_1, ver2020_4_1_rc_1), list2020AndNextRc1.filterOutAllButLatestForYear(2020, PreReleaseInclusion.All), "Case 2020-andRc1 All") },

            { assertEquals(listOf(GRV.v2020_3_1), list2020AndNextRc2.filterOutAllButLatestForYear(2020, PreReleaseInclusion.None), "Case 2020-andRc2 None") },
            { assertEquals(listOf(GRV.v2020_3_1, ver2020_4_1_rc_2), list2020AndNextRc2.filterOutAllButLatestForYear(2020, PreReleaseInclusion.RcOnly), "Case 2020-andRc2 RcOnly") },
            { assertEquals(listOf(GRV.v2020_3_1, ver2020_4_1_rc_2), list2020AndNextRc2.filterOutAllButLatestForYear(2020, PreReleaseInclusion.RcAndOrBeta), "Case 2020-andRc2 RcAndOrBeta") },
            { assertEquals(listOf(GRV.v2020_3_1, ver2020_4_1_rc_2), list2020AndNextRc2.filterOutAllButLatestForYear(2020, PreReleaseInclusion.All), "Case 2020-andRc2 All") },


            { assertEquals(listOf(ver2020_4_1), list2020AndNextFull.filterOutAllButLatestForYear(2020, PreReleaseInclusion.None), "Case 2020-andFull None") },
            { assertEquals(listOf(ver2020_4_1), list2020AndNextFull.filterOutAllButLatestForYear(2020, PreReleaseInclusion.RcOnly), "Case 2020-andFull RcOnly") },
            { assertEquals(listOf(ver2020_4_1), list2020AndNextFull.filterOutAllButLatestForYear(2020, PreReleaseInclusion.RcAndOrBeta), "Case 2020-andFull RcAndOrBeta") },
            { assertEquals(listOf(ver2020_4_1), list2020AndNextFull.filterOutAllButLatestForYear(2020, PreReleaseInclusion.All), "Case 2020-andFull All") },


            { assertEquals(combineLists(list2019Basic, listOf(GRV.v2020_3_1), list2021Basic), combineLists(list2019Basic, list2020NoPre, list2021Basic).filterOutAllButLatestForYear(2020, PreReleaseInclusion.None), "Case MULTI 2020-noPre None") },
            { assertEquals(combineLists(list2019Basic, listOf(GRV.v2020_3_1), list2021Basic), combineLists(list2019Basic, list2020NoPre, list2021Basic).filterOutAllButLatestForYear(2020, PreReleaseInclusion.RcOnly), "Case MULTI 2020-noPre RcOnly") },
            { assertEquals(combineLists(list2019Basic, listOf(GRV.v2020_3_1), list2021Basic), combineLists(list2019Basic, list2020NoPre, list2021Basic).filterOutAllButLatestForYear(2020, PreReleaseInclusion.RcAndOrBeta), "Case MULTI 2020-noPre RcAndOrBeta") },
            { assertEquals(combineLists(list2019Basic, listOf(GRV.v2020_3_1), list2021Basic), combineLists(list2019Basic, list2020NoPre, list2021Basic).filterOutAllButLatestForYear(2020, PreReleaseInclusion.All), "Case MULTI 2020-noPre All") },

            { assertEquals(combineLists(list2019Basic, listOf(GRV.v2020_3_1), list2021Basic), combineLists(list2019Basic, list2020AndNextAlpha, list2021Basic).filterOutAllButLatestForYear(2020, PreReleaseInclusion.None), "Case MULTI 2020-andAlpha None") },
            { assertEquals(combineLists(list2019Basic, listOf(GRV.v2020_3_1), list2021Basic), combineLists(list2019Basic, list2020AndNextAlpha, list2021Basic).filterOutAllButLatestForYear(2020, PreReleaseInclusion.RcOnly), "Case MULTI 2020-andAlpha RcOnly") },
            { assertEquals(combineLists(list2019Basic, listOf(GRV.v2020_3_1), list2021Basic), combineLists(list2019Basic, list2020AndNextAlpha, list2021Basic).filterOutAllButLatestForYear(2020, PreReleaseInclusion.RcAndOrBeta), "Case MULTI 2020-andAlpha RcAndOrBeta") },
            { assertEquals(combineLists(list2019Basic, listOf(GRV.v2020_3_1, ver2020_4_1_alpha_2), list2021Basic), combineLists(list2019Basic, list2020AndNextAlpha, list2021Basic).filterOutAllButLatestForYear(2020, PreReleaseInclusion.All), "Case MULTI 2020-andAlpha All") },

            { assertEquals(combineLists(list2019Basic, listOf(GRV.v2020_3_1), list2021Basic), combineLists(list2019Basic, list2020AndNextBeta1, list2021Basic).filterOutAllButLatestForYear(2020, PreReleaseInclusion.None), "Case MULTI 2020-andBeta1 None") },
            { assertEquals(combineLists(list2019Basic, listOf(GRV.v2020_3_1), list2021Basic), combineLists(list2019Basic, list2020AndNextBeta1, list2021Basic).filterOutAllButLatestForYear(2020, PreReleaseInclusion.RcOnly), "Case MULTI 2020-andBeta1 RcOnly") },
            { assertEquals(combineLists(list2019Basic, listOf(GRV.v2020_3_1, ver2020_4_1_beta_1), list2021Basic), combineLists(list2019Basic, list2020AndNextBeta1, list2021Basic).filterOutAllButLatestForYear(2020, PreReleaseInclusion.RcAndOrBeta), "Case MULTI 2020-andBeta1 RcAndOrBeta") },
            { assertEquals(combineLists(list2019Basic, listOf(GRV.v2020_3_1, ver2020_4_1_beta_1), list2021Basic), combineLists(list2019Basic, list2020AndNextBeta1, list2021Basic).filterOutAllButLatestForYear(2020, PreReleaseInclusion.All), "Case MULTI 2020-andBeta1 All") },

            { assertEquals(combineLists(list2019Basic, listOf(GRV.v2020_3_1), list2021Basic), combineLists(list2019Basic, list2020AndNextBeta2, list2021Basic).filterOutAllButLatestForYear(2020, PreReleaseInclusion.None), "Case MULTI 2020-andBeta2 None") },
            { assertEquals(combineLists(list2019Basic, listOf(GRV.v2020_3_1), list2021Basic), combineLists(list2019Basic, list2020AndNextBeta2, list2021Basic).filterOutAllButLatestForYear(2020, PreReleaseInclusion.RcOnly), "Case MULTI 2020-andBeta2 RcOnly") },
            { assertEquals(combineLists(list2019Basic, listOf(GRV.v2020_3_1, ver2020_4_1_beta_2), list2021Basic), combineLists(list2019Basic, list2020AndNextBeta2, list2021Basic).filterOutAllButLatestForYear(2020, PreReleaseInclusion.RcAndOrBeta), "Case MULTI 2020-andBeta2 RcAndOrBeta") },
            { assertEquals(combineLists(list2019Basic, listOf(GRV.v2020_3_1, ver2020_4_1_beta_2), list2021Basic), combineLists(list2019Basic, list2020AndNextBeta2, list2021Basic).filterOutAllButLatestForYear(2020, PreReleaseInclusion.All), "Case MULTI 2020-andBeta2 All") },

            { assertEquals(combineLists(list2019Basic, listOf(GRV.v2020_3_1), list2021Basic), combineLists(list2019Basic, list2020AndNextBeta3, list2021Basic).filterOutAllButLatestForYear(2020, PreReleaseInclusion.None), "Case MULTI 2020-andBeta3 None") },
            { assertEquals(combineLists(list2019Basic, listOf(GRV.v2020_3_1), list2021Basic), combineLists(list2019Basic, list2020AndNextBeta3, list2021Basic).filterOutAllButLatestForYear(2020, PreReleaseInclusion.RcOnly), "Case MULTI 2020-andBeta3 RcOnly") },
            { assertEquals(combineLists(list2019Basic, listOf(GRV.v2020_3_1, ver2020_4_1_beta_3), list2021Basic), combineLists(list2019Basic, list2020AndNextBeta3, list2021Basic).filterOutAllButLatestForYear(2020, PreReleaseInclusion.RcAndOrBeta), "Case MULTI 2020-andBeta3 RcAndOrBeta") },
            { assertEquals(combineLists(list2019Basic, listOf(GRV.v2020_3_1, ver2020_4_1_beta_3), list2021Basic), combineLists(list2019Basic, list2020AndNextBeta3, list2021Basic).filterOutAllButLatestForYear(2020, PreReleaseInclusion.All), "Case MULTI 2020-andBeta3 All") },

            { assertEquals(combineLists(list2019Basic, listOf(GRV.v2020_3_1), list2021Basic), combineLists(list2019Basic, list2020AndNextRc1, list2021Basic).filterOutAllButLatestForYear(2020, PreReleaseInclusion.None), "Case MULTI 2020-andRc1 None") },
            { assertEquals(combineLists(list2019Basic, listOf(GRV.v2020_3_1, ver2020_4_1_rc_1), list2021Basic), combineLists(list2019Basic, list2020AndNextRc1, list2021Basic).filterOutAllButLatestForYear(2020, PreReleaseInclusion.RcOnly), "Case MULTI 2020-andRc1 RcOnly") },
            { assertEquals(combineLists(list2019Basic, listOf(GRV.v2020_3_1, ver2020_4_1_rc_1), list2021Basic), combineLists(list2019Basic, list2020AndNextRc1, list2021Basic).filterOutAllButLatestForYear(2020, PreReleaseInclusion.RcAndOrBeta), "Case MULTI 2020-andRc1 RcAndOrBeta") },
            { assertEquals(combineLists(list2019Basic, listOf(GRV.v2020_3_1, ver2020_4_1_rc_1), list2021Basic), combineLists(list2019Basic, list2020AndNextRc1, list2021Basic).filterOutAllButLatestForYear(2020, PreReleaseInclusion.All), "Case MULTI 2020-andRc1 All") },

            { assertEquals(combineLists(list2019Basic, listOf(GRV.v2020_3_1), list2021Basic), combineLists(list2019Basic, list2020AndNextRc2, list2021Basic).filterOutAllButLatestForYear(2020, PreReleaseInclusion.None), "Case MULTI 2020-andRc2 None") },
            { assertEquals(combineLists(list2019Basic, listOf(GRV.v2020_3_1, ver2020_4_1_rc_2), list2021Basic), combineLists(list2019Basic, list2020AndNextRc2, list2021Basic).filterOutAllButLatestForYear(2020, PreReleaseInclusion.RcOnly), "Case MULTI 2020-andRc2 RcOnly") },
            { assertEquals(combineLists(list2019Basic, listOf(GRV.v2020_3_1, ver2020_4_1_rc_2), list2021Basic), combineLists(list2019Basic, list2020AndNextRc2, list2021Basic).filterOutAllButLatestForYear(2020, PreReleaseInclusion.RcAndOrBeta), "Case MULTI 2020-andRc2 RcAndOrBeta") },
            { assertEquals(combineLists(list2019Basic, listOf(GRV.v2020_3_1, ver2020_4_1_rc_2), list2021Basic), combineLists(list2019Basic, list2020AndNextRc2, list2021Basic).filterOutAllButLatestForYear(2020, PreReleaseInclusion.All), "Case MULTI 2020-andRc2 All") },

            { assertEquals(combineLists(list2019Basic, listOf(ver2020_4_1), list2021Basic), combineLists(list2019Basic, list2020AndNextFull, list2021Basic).filterOutAllButLatestForYear(2020, PreReleaseInclusion.None), "Case MULTI 2020-andFull None") },
            { assertEquals(combineLists(list2019Basic, listOf(ver2020_4_1), list2021Basic), combineLists(list2019Basic, list2020AndNextFull, list2021Basic).filterOutAllButLatestForYear(2020, PreReleaseInclusion.RcOnly), "Case MULTI 2020-andFull RcOnly") },
            { assertEquals(combineLists(list2019Basic, listOf(ver2020_4_1), list2021Basic), combineLists(list2019Basic, list2020AndNextFull, list2021Basic).filterOutAllButLatestForYear(2020, PreReleaseInclusion.RcAndOrBeta), "Case MULTI 2020-andFull RcAndOrBeta") },
            { assertEquals(combineLists(list2019Basic, listOf(ver2020_4_1), list2021Basic), combineLists(list2019Basic, list2020AndNextFull, list2021Basic).filterOutAllButLatestForYear(2020, PreReleaseInclusion.All), "Case MULTI 2020-andFull All") },


            )
    }

    private fun <T> combineLists(vararg lists: List<T>): List<T>
    {
        val list = mutableListOf<T>()
        lists.forEach { list.addAll(it) }
        return list.toList()
    }


    @Test
    fun filterToDefaultListingNoOverride()
    {
        System.setProperty(SHOW_BETAS_SYS_PROP_KEY, "false")

        val ver2022_1_1_alpha_1 = WpiLibVersionImpl.parse("2022.1.1-alpha-1")
        val ver2022_1_1_alpha_2 = WpiLibVersionImpl.parse("2022.1.1-alpha-2")
        val ver2022_1_1_alpha_3 = WpiLibVersionImpl.parse("2022.1.1-alpha-3")
        val ver2022_1_1_beta_1 = WpiLibVersionImpl.parse("2022.1.1-beta-1")
        val ver2022_1_1_beta_2 = WpiLibVersionImpl.parse("2022.1.1-beta-2")
        val ver2022_1_1_rc_1 = WpiLibVersionImpl.parse("2022.1.1-rc-1")
        val ver2022_1_1_rc_2 = WpiLibVersionImpl.parse("2022.1.1-rc-2")
        val ver2022_1_1 = WpiLibVersionImpl.parse("2022.1.1")

        val ver2022_2_1_rc_1 = WpiLibVersionImpl.parse("2022.2.1-rc-1")
        val ver2022_2_1_rc_2 = WpiLibVersionImpl.parse("2022.2.1-rc-2")
        val ver2022_2_1_rc_3 = WpiLibVersionImpl.parse("2022.2.1-rc-3")
        val ver2022_2_1 = WpiLibVersionImpl.parse("2022.2.1")

        val ver2022_2_2 = WpiLibVersionImpl.parse("2022.2.2")

        val ver2022_2_3_beta_1 = WpiLibVersionImpl.parse("2022.2.3-beta-1")
        val ver2022_2_3_beta_2 = WpiLibVersionImpl.parse("2022.2.3-beta-2")
        val ver2022_2_3_rc_1 = WpiLibVersionImpl.parse("2022.2.3-rc-1")
        val ver2022_2_3_rc_2 = WpiLibVersionImpl.parse("2022.2.3-rc-2")


        val baseExpected = listOf(
            GRV.v2019_4_1,
            GRV.v2020_3_1,
            GRV.v2021_3_1
                                            ).sortedDescending()

        val inputForOneRC = versions.toMutableList().apply {
            add(ver2022_1_1_alpha_1)
            add(ver2022_1_1_alpha_2)
            add(ver2022_1_1_alpha_3)
            add(ver2022_1_1_beta_1)
            add(ver2022_1_1_beta_2)
            add(ver2022_1_1_rc_1)
        }.toList()

        val expectedForOneRc = baseExpected.toMutableList().apply {
            add(GRV.v2021_1_2)
            add(GRV.v2021_2_1)
            add(GRV.v2021_2_2)
            add(ver2022_1_1_rc_1)
        }.sortedDescending()

        val inputForTwoRC = inputForOneRC.toMutableList().apply {
            add(ver2022_1_1_rc_2)
        }.toList()

        val expectedForTwoRc = baseExpected.toMutableList().apply {
            add(GRV.v2021_1_2)
            add(GRV.v2021_2_1)
            add(GRV.v2021_2_2)
            add(ver2022_1_1_rc_2)
        }.sortedDescending()


        val inputForOneRelease = inputForTwoRC.toMutableList().apply {
            add(ver2022_1_1)
        }.toList()

        val expectedForOneRelease = baseExpected.toMutableList().apply {
            add(ver2022_1_1)
        }.sortedDescending()

        val inputForOneReleaseAndOneRc = inputForOneRelease.toMutableList().apply {
            add(ver2022_2_1_rc_1)
        }.toList()

        val expectedForOneReleaseAndOneRc = baseExpected.toMutableList().apply {
            add(ver2022_1_1)
            add(ver2022_2_1_rc_1)
        }.sortedDescending()

        val inputForOneReleaseAndTwoRc = expectedForOneReleaseAndOneRc.toMutableList().apply {
            add(ver2022_2_1_rc_2)
        }.toList()

        val expectedForOneReleaseAndTwoRc = baseExpected.toMutableList().apply {
            add(ver2022_1_1)
            add(ver2022_2_1_rc_2)
        }.sortedDescending()


        val inputForTwoReleases = inputForOneRelease.toMutableList().apply {
            add(ver2022_2_1_rc_1)
            add(ver2022_2_1_rc_2)
            add(ver2022_2_1_rc_3)
            add(ver2022_2_1)
        }.toList()

        val expectedForTwoReleases = expectedForOneRelease.toMutableList().apply {
            add(ver2022_2_1)
        }.sortedDescending()

        val inputForThreeReleases = inputForTwoReleases.toMutableList().apply {
            add(ver2022_2_2)
        }.toList()

        val expectedForThreeReleases = expectedForTwoReleases.toMutableList().apply {
            add(ver2022_2_2)
        }.sortedDescending()

        val inputForThreeReleasesAndOneBeta = expectedForThreeReleases.toMutableList().apply {
            add(ver2022_2_3_beta_1)
        }.toList()

        val expectedForThreeReleasesAndOneBeta = expectedForThreeReleases.toMutableList().sortedDescending()

        val inputForThreeReleasesAndTwoBetas = inputForThreeReleasesAndOneBeta.toMutableList().apply {
            add(ver2022_2_3_beta_2)
        }.toList()

        val expectedForThreeReleasesAndTwoBetas = expectedForThreeReleases.toMutableList().sortedDescending()

        val inputForThreeReleasesAndOneRc = inputForThreeReleasesAndTwoBetas.toMutableList().apply {
            add(ver2022_2_3_rc_1)
        }.toList()

        val expectedForThreeReleasesAndOneRc = expectedForThreeReleases.toMutableList().apply{
            add(ver2022_2_3_rc_1)
        }.sortedDescending()


        val inputForThreeReleasesAndTwoRc = inputForThreeReleasesAndOneRc.toMutableList().apply {
            add(ver2022_2_3_rc_2)
        }.toList()

        val expectedForThreeReleasesAndTwoRc = expectedForThreeReleases.toMutableList().apply{
            add(ver2022_2_3_rc_2)
        }.sortedDescending()


        assertAll(
            { assertEquals(expectedForOneRc, inputForOneRC.filterToDefaultListing(), "Failure for One RC") },
            { assertEquals(expectedForTwoRc, inputForTwoRC.filterToDefaultListing(), "Failure for Two RC") },
            { assertEquals(expectedForOneRelease, inputForOneRelease.filterToDefaultListing(), "Failure for One Release") },
            { assertEquals(expectedForOneReleaseAndOneRc, inputForOneReleaseAndOneRc.filterToDefaultListing(), "Failure for One Release and One RC") },
            { assertEquals(expectedForOneReleaseAndTwoRc, inputForOneReleaseAndTwoRc.filterToDefaultListing(), "Failure for One Release and Two RC") },
            { assertEquals(expectedForTwoReleases, inputForTwoReleases.filterToDefaultListing(), "Failure for Two Releases") },
            { assertEquals(expectedForThreeReleases, inputForThreeReleases.filterToDefaultListing(), "Failure for Three Releases") },
            { assertEquals(expectedForThreeReleasesAndOneBeta, inputForThreeReleasesAndOneBeta.filterToDefaultListing(), "Failure for Three Releases and One Beta") },
            { assertEquals(expectedForThreeReleasesAndTwoBetas, inputForThreeReleasesAndTwoBetas.filterToDefaultListing(), "Failure for Three Releases and Two Betas") },
            { assertEquals(expectedForThreeReleasesAndOneRc, inputForThreeReleasesAndOneRc.filterToDefaultListing(), "Failure for Three Releases and One RC") },
            { assertEquals(expectedForThreeReleasesAndTwoRc, inputForThreeReleasesAndTwoRc.filterToDefaultListing(), "Failure for Three Releases and Two RC") },
                 )
    }

//    @Disabled("Need to fix. The expected values need to be adjusted to have all RCs and all Betas")
//    @Test
//    fun filterToDefaultListingWithOverride()
//    {
//        System.setProperty(SHOW_BETAS_SYS_PROP_KEY, "true")
//
//        val ver2022_1_1_alpha_1 = WpiLibVersionImpl.parse("2022.1.1-alpha-1")
//        val ver2022_1_1_alpha_2 = WpiLibVersionImpl.parse("2022.1.1-alpha-2")
//        val ver2022_1_1_alpha_3 = WpiLibVersionImpl.parse("2022.1.1-alpha-3")
//        val ver2022_1_1_beta_1 = WpiLibVersionImpl.parse("2022.1.1-beta-1")
//        val ver2022_1_1_beta_2 = WpiLibVersionImpl.parse("2022.1.1-beta-2")
//        val ver2022_1_1_rc_1 = WpiLibVersionImpl.parse("2022.1.1-rc-1")
//        val ver2022_1_1_rc_2 = WpiLibVersionImpl.parse("2022.1.1-rc-2")
//        val ver2022_1_1 = WpiLibVersionImpl.parse("2022.1.1")
//
//        val ver2022_2_1_rc_1 = WpiLibVersionImpl.parse("2022.2.1-rc-1")
//        val ver2022_2_1_rc_2 = WpiLibVersionImpl.parse("2022.2.1-rc-2")
//        val ver2022_2_1_rc_3 = WpiLibVersionImpl.parse("2022.2.1-rc-3")
//        val ver2022_2_1 = WpiLibVersionImpl.parse("2022.2.1")
//
//        val ver2022_2_2 = WpiLibVersionImpl.parse("2022.2.2")
//
//        val ver2022_2_3_beta_1 = WpiLibVersionImpl.parse("2022.2.3-beta-1")
//        val ver2022_2_3_beta_2 = WpiLibVersionImpl.parse("2022.2.3-beta-2")
//        val ver2022_2_3_rc_1 = WpiLibVersionImpl.parse("2022.2.3-rc-1")
//        val ver2022_2_3_rc_2 = WpiLibVersionImpl.parse("2022.2.3-rc-2")
//
//
//        val baseExpected = listOf(
//            GRV.v2019_4_1,
//            GRV.v2020_3_1,
//            GRV.v2021_3_1
//                                            ).sortedDescending()
//
//        val inputForOneRC = versions.toMutableList().apply {
//            add(ver2022_1_1_alpha_1)
//            add(ver2022_1_1_alpha_2)
//            add(ver2022_1_1_alpha_3)
//            add(ver2022_1_1_beta_1)
//            add(ver2022_1_1_beta_2)
//            add(ver2022_1_1_rc_1)
//        }.toList()
//
//        val expectedForOneRc = baseExpected.toMutableList().apply {
//            add(GRV.v2021_1_2)
//            add(GRV.v2021_2_1)
//            add(GRV.v2021_2_2)
//            add(ver2022_1_1_rc_1)
//        }.sortedDescending()
//
//        val inputForTwoRC = inputForOneRC.toMutableList().apply {
//            add(ver2022_1_1_rc_2)
//        }.toList()
//
//        val expectedForTwoRc = baseExpected.toMutableList().apply {
//            add(GRV.v2021_1_2)
//            add(GRV.v2021_2_1)
//            add(GRV.v2021_2_2)
//            add(ver2022_1_1_rc_2)
//        }.sortedDescending()
//
//
//        val inputForOneRelease = inputForTwoRC.toMutableList().apply {
//            add(ver2022_1_1)
//        }.toList()
//
//        val expectedForOneRelease = baseExpected.toMutableList().apply {
//            add(ver2022_1_1)
//        }.sortedDescending()
//
//        val inputForOneReleaseAndOneRc = inputForOneRelease.toMutableList().apply {
//            add(ver2022_2_1_rc_1)
//        }.toList()
//
//        val expectedForOneReleaseAndOneRc = baseExpected.toMutableList().apply {
//            add(ver2022_1_1)
//            add(ver2022_2_1_rc_1)
//        }.sortedDescending()
//
//        val inputForOneReleaseAndTwoRc = expectedForOneReleaseAndOneRc.toMutableList().apply {
//            add(ver2022_2_1_rc_2)
//        }.toList()
//
//        val expectedForOneReleaseAndTwoRc = baseExpected.toMutableList().apply {
//            add(ver2022_1_1)
//            add(ver2022_2_1_rc_2)
//        }.sortedDescending()
//
//
//        val inputForTwoReleases = inputForOneRelease.toMutableList().apply {
//            add(ver2022_2_1_rc_1)
//            add(ver2022_2_1_rc_2)
//            add(ver2022_2_1_rc_3)
//            add(ver2022_2_1)
//        }.toList()
//
//        val expectedForTwoReleases = expectedForOneRelease.toMutableList().apply {
//            add(ver2022_2_1)
//        }.sortedDescending()
//
//        val inputForThreeReleases = inputForTwoReleases.toMutableList().apply {
//            add(ver2022_2_2)
//        }.toList()
//
//        val expectedForThreeReleases = expectedForTwoReleases.toMutableList().apply {
//            add(ver2022_2_2)
//        }.sortedDescending()
//
//        val inputForThreeReleasesAndOneBeta = expectedForThreeReleases.toMutableList().apply {
//            add(ver2022_2_3_beta_1)
//        }.toList()
//
//        val expectedForThreeReleasesAndOneBeta = expectedForThreeReleases.toMutableList().apply{
//            add(ver2022_2_3_beta_1)
//        }.sortedDescending()
//
//        val inputForThreeReleasesAndTwoBetas = inputForThreeReleasesAndOneBeta.toMutableList().apply {
//            add(ver2022_2_3_beta_2)
//        }.toList()
//
//        val expectedForThreeReleasesAndTwoBetas = expectedForThreeReleases.toMutableList().apply {
//            add(ver2022_2_3_beta_2)
//        }.sortedDescending()
//
//        val inputForThreeReleasesAndOneRc = inputForThreeReleasesAndTwoBetas.toMutableList().apply {
//            add(ver2022_2_3_rc_1)
//        }.toList()
//
//        val expectedForThreeReleasesAndOneRc = expectedForThreeReleases.toMutableList().apply{
//            add(ver2022_2_3_rc_1)
//        }.sortedDescending()
//
//
//        val inputForThreeReleasesAndTwoRc = inputForThreeReleasesAndOneRc.toMutableList().apply {
//            add(ver2022_2_3_rc_2)
//        }.toList()
//
//        val expectedForThreeReleasesAndTwoRc = expectedForThreeReleases.toMutableList().apply{
//            add(ver2022_2_3_rc_2)
//        }.sortedDescending()
//
//
//        assertAll(
//            { assertEquals(expectedForOneRc, inputForOneRC.filterToDefaultListing2(), "Failure for One RC") },
//            { assertEquals(expectedForTwoRc, inputForTwoRC.filterToDefaultListing2(), "Failure for Two RC") },
//            { assertEquals(expectedForOneRelease, inputForOneRelease.filterToDefaultListing2(), "Failure for One Release") },
//            { assertEquals(expectedForOneReleaseAndOneRc, inputForOneReleaseAndOneRc.filterToDefaultListing2(), "Failure for One Release and One RC") },
//            { assertEquals(expectedForOneReleaseAndTwoRc, inputForOneReleaseAndTwoRc.filterToDefaultListing2(), "Failure for One Release and Two RC") },
//            { assertEquals(expectedForTwoReleases, inputForTwoReleases.filterToDefaultListing2(), "Failure for Two Releases") },
//            { assertEquals(expectedForThreeReleases, inputForThreeReleases.filterToDefaultListing2(), "Failure for Three Releases") },
//            { assertEquals(expectedForThreeReleasesAndOneBeta, inputForThreeReleasesAndOneBeta.filterToDefaultListing2(), "Failure for Three Releases and One Beta") },
//            { assertEquals(expectedForThreeReleasesAndTwoBetas, inputForThreeReleasesAndTwoBetas.filterToDefaultListing2(), "Failure for Three Releases and Two Betas") },
//            { assertEquals(expectedForThreeReleasesAndOneRc, inputForThreeReleasesAndOneRc.filterToDefaultListing2(), "Failure for Three Releases and One RC") },
//            { assertEquals(expectedForThreeReleasesAndTwoRc, inputForThreeReleasesAndTwoRc.filterToDefaultListing2(), "Failure for Three Releases and Two RC") },
//                 )
//    }

    @Test
    fun filterToDefaultListingIncludesTheLatestPreReleaseOfAnUnreleasedSeason()
    {
        System.setProperty(SHOW_BETAS_SYS_PROP_KEY, "false")
        val v2026_1_1 = WpiLibVersionImpl.parse("2026.1.1")
        val v2026_2_1 = WpiLibVersionImpl.parse("2026.2.1")
        val v2027_alpha_6 = WpiLibVersionImpl.parse("2027.0.0-alpha-6")
        val v2027_alpha_7 = WpiLibVersionImpl.parse("2027.0.0-alpha-7")
        val v2027_1_1 = WpiLibVersionImpl.parse("2027.1.1")
        assertAll(
            // Before 2027 is released, its latest alpha is listed so that 2027 projects can be created
            { assertEquals(listOf(v2027_alpha_7, v2026_2_1, v2026_1_1),
                           listOf(v2026_1_1, v2026_2_1, v2027_alpha_6, v2027_alpha_7).filterToDefaultListing(), "Before the 2027 release") },
            // Once 2027 is released, its pre-releases are no longer listed
            { assertEquals(listOf(v2027_1_1, v2026_2_1),
                           listOf(v2026_1_1, v2026_2_1, v2027_alpha_7, v2027_1_1).filterToDefaultListing(), "After the 2027 release") },
                 )
    }
}
