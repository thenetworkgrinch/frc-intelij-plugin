/*
 * Copyright 2015-2022 the original author or authors.
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

@file:Suppress("unused")

package net.javaru.iip.frc.wpilib.version

import com.intellij.openapi.diagnostic.logger
import com.intellij.openapi.diagnostic.trace
import org.apache.commons.lang3.BooleanUtils
import net.javaru.iip.frc.ifNotInUnitTestModeOrElse
import net.javaru.iip.frc.settings.FrcApplicationSettings
import java.time.LocalDate
import java.time.Month
import java.util.stream.Stream

private object WpiLibVersionFilters
private val logger = logger<WpiLibVersionFilters>()

/** The 2018 transitional release (when WPI took over the development of GradleRIO). */
val ver2018_06_21 = WpiLibVersionImpl.parse("2018.06.21")

const val SHOW_BETAS_SYS_PROP_KEY = "frc.show.betas.in.new.project.wizard"

enum class PreReleaseInclusion
{
    None,
    RcOnly,
    RcAndOrBeta,
    All
}

/**
 * Returns a List containing only elements matching the given [WpiLibVersionFilter].
 */
fun Iterable<WpiLibVersion>.filterVersions(filter: WpiLibVersionFilter): List<WpiLibVersion>
{
    return this.filter { filter.predicate().invoke(it) }
}

/**
 * Returns a Stream containing only elements matching the given [WpiLibVersionFilter].
 */
fun Stream<WpiLibVersion>.filterVersions(filter: WpiLibVersionFilter): Stream<WpiLibVersion>
{
    return this.filter { filter.predicate().invoke(it) }
}

/**
 *  Returns a List with elements matching the given [WpiLibVersionFilter] removed.
 */
fun Iterable<WpiLibVersion>.filterOutVersions(filter: WpiLibVersionFilter): List<WpiLibVersion>
{
    return this.filter { filter.not().predicate().invoke(it) }
}

/**
 *  Returns a Stream with elements matching the given [WpiLibVersionFilter] removed.
 */
fun Stream<WpiLibVersion>.filterOutVersions(filter: WpiLibVersionFilter): Stream<WpiLibVersion>
{
    return this.filter { filter.not().predicate().invoke(it) }
}

/**
 * For the given year, filters out ALL but the latest version for that year. Other years are unaffected.
 * If [preReleaseInclusion] is set to:
 *   - [PreReleaseInclusion.None] No pre-releases (betas, release candidates, etc.) are included for the filtered year.
 *   - [PreReleaseInclusion.RcOnly] If the latest version available is an RC, it and the previous full version are included for the filtered year
 *   - [PreReleaseInclusion.RcAndOrBeta] If the latest version available is a beta or an RC, it and the previous full version are included for the filtered year.
 *   - [PreReleaseInclusion.All] If the latest is any sort of pre-release, it and the previous full version are included for the filtered year.
 */
@JvmOverloads
fun Iterable<WpiLibVersion>.filterOutAllButLatestForYear(year: Int, preReleaseInclusion: PreReleaseInclusion = PreReleaseInclusion.None): List<WpiLibVersion>
{
    val allowedForYear = mutableSetOf<WpiLibVersion>()
    this.filterToLatestForYear(year, true)?.also {
        allowedForYear.add(it)
    }
    if (preReleaseInclusion != PreReleaseInclusion.None)
    {
        val latestRelease = this.filterToLatestForYear(year, false)
        if (latestRelease?.isPreRelease() == true)
        {
            when (preReleaseInclusion)
            {
                PreReleaseInclusion.All -> allowedForYear.add(latestRelease)
                PreReleaseInclusion.RcAndOrBeta -> if (latestRelease.isBetaOrReleaseCandidate()) allowedForYear.add(latestRelease)
                PreReleaseInclusion.RcOnly -> if (latestRelease.isReleaseCandidate()) allowedForYear.add(latestRelease)
            }
        }
    }

    return this.asSequence()
        .filter { it.frcYear != year || allowedForYear.contains(it) }
        .toList()
}



@JvmOverloads
fun Iterable<WpiLibVersion>.filterToLatestForYear(year: Int, excludePreReleases: Boolean = true): WpiLibVersion? =  this.filterVersions(YearFilter(year, excludePreReleases)).maxOrNull()


/**
 * Filters the Iterable to include:
 *   - For current year: All full releases, and if the latest release is an RC, it is included as well.
 *   - For previous years: The latest full version
 * It also filters out the transitional `2018.06.21` version. Finally, it sorts the list
 * in descending order' so the latest version is first.
 *
 *
 * Be careful about showing betas to end users as there may be peculiarities with betas. For example, during the beta program of 2020,
 * the `projectYear` in the wpilib_preferences.json file was "Beta2020-2" and not 2020. But I could find no mapping of
 * the WpiLib Version to this value. It was basically a hard coded value in the code checking for it. Likely a one-off or an error.
 */
fun Iterable<WpiLibVersion>.filterToDefaultListing(): List<WpiLibVersion>
{
    val versionList = this.toList().sortedDescending()
    val showBetas = BooleanUtils.toBoolean(System.getProperty(SHOW_BETAS_SYS_PROP_KEY, "false")) || isTeam3838AndInAllowableTimeWindow()
    val filter = if (showBetas) IsReleaseOrRcOrBetaFilter else IsReleaseFilter
    val initialFilteredList = versionList.filterVersions(filter).filterOutVersions(Is2018TransitionalRelease)

    val latest = initialFilteredList.maxOrNull()?.frcYear ?: LocalDate.now().year
    val pastYears = initialFilteredList.map { it.frcYear }.distinct().filter { it != latest }.sorted()

    var filteredList = initialFilteredList
    logger.trace { "List before filtering years :  $filteredList" }
    pastYears.forEach{
        filteredList = filteredList.filterOutAllButLatestForYear(it, PreReleaseInclusion.RcOnly)
        logger.trace { "List after filtering for $it : $filteredList" }
    }

    return addLatestPreReleaseOfAnUnreleasedSeason(versionList, addRcBackIfItIsTheLatest(versionList, filteredList))
}

/**
 * Adds the latest pre-release (alpha, beta or RC) of the newest season when that season has no full release yet, such as
 * `2027.0.0-alpha-7` before 2027 is released, so that projects for the coming season can be created. The wizard still
 * selects the newest full release by default.
 */
private fun addLatestPreReleaseOfAnUnreleasedSeason(fullVersionList: List<WpiLibVersion>, filteredList: List<WpiLibVersion>): List<WpiLibVersion>
{
    val newestSeason = fullVersionList.maxOfOrNull { it.frcYear } ?: return filteredList
    if (fullVersionList.any { it.frcYear == newestSeason && it.isRelease() }) return filteredList
    val latestPreRelease = fullVersionList.filter { it.frcYear == newestSeason && it.isPreRelease() }.maxOrNull() ?: return filteredList
    return if (filteredList.contains(latestPreRelease)) filteredList else (filteredList + latestPreRelease).sortedDescending()
}

private fun isTeam3838AndInAllowableTimeWindow(): Boolean
{
    return ifNotInUnitTestModeOrElse(whenInUnitTestModeResult = false) {
        val now = LocalDate.now()
        FrcApplicationSettings.getInstance().isTeam3838() &&
            ((now.month == Month.DECEMBER && now.dayOfMonth >= 15) || (now.month == Month.JANUARY && now.dayOfMonth <= 10))
    }
}

private fun addRcBackIfItIsTheLatest(fullVersionList: List<WpiLibVersion>, filteredList: List<WpiLibVersion>): List<WpiLibVersion>
{
    return if (fullVersionList.isNotEmpty() && !filteredList.contains(fullVersionList[0]) && fullVersionList[0].isReleaseCandidate())
    {
        // the latest version is not included, and is a release candidate, and we want to show it.
        val mutableList = filteredList.toMutableList()
        mutableList.add(fullVersionList[0])
        mutableList.sortDescending()
        mutableList
    }
    else
    {
        filteredList
    }
}

interface WpiLibVersionFilter
{
    fun predicate(): (WpiLibVersion) -> Boolean

    /** Returns an OR filter that "ors" this filter with the supplied filter. */
    fun or(filter: WpiLibVersionFilter): WpiLibVersionFilter = Filters.or(this, filter)

    /** Returns an AND filter that "ands" this filter with the supplied filter. */
    fun and(filter: WpiLibVersionFilter): WpiLibVersionFilter = Filters.and(this, filter)

    /** Returns an AND filter that "ands" this filter with the inverse of the supplied filter. For example
     * `IsPreReleaseFilter.andNot(IsAlphaFilter)` would return a filter that returns all prerelease versions
     * that are not alpha release. Thus, it would return only release candidates and betas .*/
    fun andNot(filter: WpiLibVersionFilter): WpiLibVersionFilter = Filters.and(this, filter.not())

    /** Returns the inverse of this boolean. For example, for the IsBetaFilter, it effectually returns an IsNotBetaFilter. */
    fun not(): WpiLibVersionFilter = Filters.not(this)


    companion object Filters
    {
        fun not(filter: WpiLibVersionFilter) = object : WpiLibVersionFilter
        {
            override fun predicate(): (WpiLibVersion) -> Boolean = { wpiLibVersion: WpiLibVersion ->
                !filter.predicate().invoke(wpiLibVersion)
            }
        }

        fun or(vararg filters: WpiLibVersionFilter) = object : WpiLibVersionFilter
        {
            override fun predicate(): (WpiLibVersion) -> Boolean = { wpiLibVersion: WpiLibVersion ->
                var result = false
                for (filter in filters)
                {
                    if (filter.predicate().invoke(wpiLibVersion))
                    {
                        result = true
                        break
                    }
                }
                result
            }
        }

        fun and(vararg filters: WpiLibVersionFilter) = object : WpiLibVersionFilter
        {
            override fun predicate(): (WpiLibVersion) -> Boolean = { wpiLibVersion: WpiLibVersion ->
                var result = true
                for (filter in filters)
                {
                    if (!filter.predicate().invoke(wpiLibVersion))
                    {
                        result = false
                        break
                    }
                }
                result
            }
        }
    }
}


object Is2018TransitionalRelease : WpiLibVersionFilter
{
    override fun predicate(): (WpiLibVersion) -> Boolean = { wpiLibVersion -> wpiLibVersion == ver2018_06_21 }
}

object IsReleaseFilter : WpiLibVersionFilter
{
    override fun predicate(): (WpiLibVersion) -> Boolean = { wpiLibVersion -> wpiLibVersion.isRelease() }
}


object IsReleaseCandidateFilter : WpiLibVersionFilter
{
    override fun predicate(): (WpiLibVersion) -> Boolean = { wpiLibVersion -> wpiLibVersion.isReleaseCandidate() }
}

object IsBetaFilter : WpiLibVersionFilter
{
    override fun predicate(): (WpiLibVersion) -> Boolean = { wpiLibVersion -> wpiLibVersion.isBeta() }
}

object IsPreReleasePreviewFilter : WpiLibVersionFilter
{
    override fun predicate(): (WpiLibVersion) -> Boolean = { wpiLibVersion -> wpiLibVersion.isPreReleasePreview() }
}

object IsReleaseOrRcOrBetaFilter : WpiLibVersionFilter
{
    override fun predicate(): (WpiLibVersion) -> Boolean = { wpiLibVersion -> wpiLibVersion.isRelease() || wpiLibVersion.isReleaseCandidate() || wpiLibVersion.isBeta() }
}

object IsNotPreReleasePreviewFilter : WpiLibVersionFilter
{
    override fun predicate(): (WpiLibVersion) -> Boolean = { wpiLibVersion -> !wpiLibVersion.isPreReleasePreview() }
}

/**
 * Filters a list so that it contains just the values for a particular year. By default, it will filter out pre-releases. Note that NO
 * sorting takes place. The items original list's order is maintained in the returned value.
 */
open class YearFilter @JvmOverloads constructor(private val year: Int, private val excludePreReleases: Boolean = true) : WpiLibVersionFilter
{
    override fun predicate(): (WpiLibVersion) -> Boolean =
            if (excludePreReleases)
                { wpiLibVersion -> wpiLibVersion.frcYear == year && wpiLibVersion.isRelease() }
            else 
                { wpiLibVersion -> wpiLibVersion.frcYear == year }
}


