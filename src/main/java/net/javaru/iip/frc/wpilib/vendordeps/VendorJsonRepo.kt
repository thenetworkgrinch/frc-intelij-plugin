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

import com.beust.klaxon.JsonArray
import com.beust.klaxon.JsonObject
import com.beust.klaxon.Parser
import com.github.michaelbull.result.Err
import com.github.michaelbull.result.Ok
import com.github.michaelbull.result.Result
import com.github.michaelbull.result.getOrElse
import com.intellij.openapi.components.Service
import com.intellij.openapi.components.service
import com.intellij.openapi.diagnostic.logger
import com.intellij.openapi.progress.ProcessCanceledException
import com.intellij.openapi.progress.ProgressIndicator
import com.intellij.util.concurrency.AppExecutorUtil
import com.intellij.util.io.HttpRequests
import net.javaru.iip.frc.wpilib.extractProjectYear
import java.io.StringReader
import java.util.*
import java.util.concurrent.ConcurrentHashMap
import java.util.concurrent.Future

/**
 * A vendor library available from the [WPILib Vendor JSON Repository](https://github.com/wpilibsuite/vendor-json-repo),
 * combining the library's entry in the `YEAR_metadata.json` file with its latest vendordeps JSON file in the `YEAR` directory.
 */
data class VendorRepoLibrary(
    val uuid: UUID,
    val name: String,
    val description: String,
    val website: String?,
    val instructions: String?,
    val latestVersion: LibVersion,
    /** The raw download URL of the latest vendordeps JSON file in the repository. */
    val downloadUrl: String,
    /** The vendor's own `jsonUrl` from the latest vendordeps JSON, which may provide a newer (i.e. beta/pre-release) version. */
    val jsonUrl: String?,
                            ) : Comparable<VendorRepoLibrary>
{
    override fun compareTo(other: VendorRepoLibrary): Int = compareValuesBy(this, other, { it.name.lowercase() }, { it.uuid })
}

/** A downloaded vendordeps JSON file, along with its parsed [vendordeps] data. */
data class VendordepsDownload(val url: String, val vendordeps: Vendordeps, val content: String)
{
    /** The file name to use when installing into the vendordeps directory. */
    val fileName: String
        get() = vendordeps.fileName.ifBlank { url.substringAfterLast('/').substringBefore('?') }.let { if (it.endsWith(".json", ignoreCase = true)) it else "$it.json" }
}

/** The libraries available for a given bundle (i.e. year) of the vendor JSON repository. */
data class VendorRepoBundle(val bundleName: String, val libraries: List<VendorRepoLibrary>)

private val gradleRioBundleRegex = Regex("""^(\d{4})\.\d+\.\d+(?:-(alpha|beta)-?(\d+))?""", RegexOption.IGNORE_CASE)

/**
 * The vendor JSON repository bundle for a GradleRIO version, which is named as the WPILib installer's project year is: e.g.
 * `2027_alpha7` for `2027.0.0-alpha-7`, `2026beta` for `2026.0.0-beta-3`, and `2026` for `2026.2.1`. Returns `null` if the version is not recognized.
 */
fun vendorRepoBundleName(gradleRioVersion: String): String?
{
    val (year, preRelease, number) = gradleRioBundleRegex.find(gradleRioVersion.trim())?.destructured ?: return null
    return when (preRelease.lowercase())
    {
        "alpha" -> "${year}_alpha$number"
        "beta"  -> "${year}beta"
        else    -> year
    }
}

/**
 * Fetches, and caches, the listing of vendor libraries available in the
 * [WPILib Vendor JSON Repository](https://github.com/wpilibsuite/vendor-json-repo) for a project year.
 */
@Service(Service.Level.APP)
class VendorJsonRepoService
{
    private val logger = logger<VendorJsonRepoService>()
    private val cache = ConcurrentHashMap<String, VendorRepoBundle>()
    /** Cache of the vendordeps served by vendors' `jsonUrl`s. An empty Optional indicates the download or parsing failed. */
    private val jsonUrlCache = ConcurrentHashMap<String, Optional<VendordepsDownload>>()

    companion object
    {
        private const val repoRawBaseUrl = "https://raw.githubusercontent.com/wpilibsuite/vendor-json-repo/main"
        private const val repoContentsApiUrl = "https://api.github.com/repos/wpilibsuite/vendor-json-repo/contents"
        /** Matches the `NAME-VERSION.json` naming convention used for files in the repository. */
        private val repoFileNameRegex = """^(?<name>.+?)-[vV]?(?<version>\d.*)\.json$""".toRegex()
        private val parser: Parser = Parser.default()

        @JvmStatic
        fun getInstance(): VendorJsonRepoService = service()
    }

    /**
     * Gets the libraries available for the provided project year (i.e. the `projectYear` value from the `wpilib_preferences.json`
     * file, such as "2026" or "2026beta"). If no bundle exists for the exact project year, the bundle for just the year is tried,
     * then the [fallbackBundleNames] (e.g. the bundle for the project's GradleRIO version, for a `projectYear` such as
     * "intellisense" that is not a year). **This makes network calls and must not be called on the EDT.**
     */
    fun getLibraries(projectYear: String, forceRefresh: Boolean = false, indicator: ProgressIndicator? = null,
                     fallbackBundleNames: List<String> = emptyList()): Result<VendorRepoBundle, Exception>
    {
        val candidates = linkedSetOf<String>()
        projectYear.trim().lowercase().ifBlank { null }?.let { candidates.add(it) }
        extractProjectYear(projectYear)?.let { candidates.add(it.toString()) }
        fallbackBundleNames.forEach { candidates.add(it.trim().lowercase()) }

        var lastError: Exception? = null
        for (bundleName in candidates)
        {
            if (!forceRefresh) cache[bundleName]?.let { return Ok(it) }
            try
            {
                val bundle = fetchBundle(bundleName, indicator)
                cache[bundleName] = bundle
                return Ok(bundle)
            }
            catch (e: ProcessCanceledException)
            {
                throw e
            }
            catch (e: HttpRequests.HttpStatusException)
            {
                logger.debug("[FRC] No vendor JSON repo bundle found for '$bundleName': ${e.statusCode} ${e.url}")
                lastError = e
            }
            catch (e: Exception)
            {
                logger.info("[FRC] Could not fetch vendor JSON repo bundle '$bundleName'. Cause: $e", e)
                lastError = e
            }
        }
        return Err(lastError ?: IllegalStateException("No vendor library bundle found for project year '$projectYear'"))
    }

    private fun fetchBundle(bundleName: String, indicator: ProgressIndicator?): VendorRepoBundle
    {
        indicator?.text = "Fetching $bundleName vendor library metadata"
        val metadata = (parser.parse(StringReader(HttpRequests.request("$repoRawBaseUrl/${bundleName}_metadata.json").readString(indicator))) as JsonArray<*>)
            .filterIsInstance<JsonObject>()
            .mapNotNull { json -> json.string("uuid")?.trim()?.let { uuidString -> runCatching { UUID.fromString(uuidString) }.getOrNull()?.let { it to json } } }
            .toMap()

        indicator?.checkCanceled()
        indicator?.text = "Fetching $bundleName vendor library listing"
        val repoFiles = (parser.parse(StringReader(HttpRequests.request("$repoContentsApiUrl/$bundleName").accept("application/vnd.github+json").readString(indicator))) as JsonArray<*>)
            .filterIsInstance<JsonObject>()
            .filter { it.string("type") == "file" }
            .mapNotNull { json ->
                val name = json.string("name") ?: return@mapNotNull null
                val downloadUrl = json.string("download_url") ?: return@mapNotNull null
                // Files not following the NAME-VERSION.json convention are kept as their own "library" so that they are still downloaded
                val match = repoFileNameRegex.matchEntire(name)
                RepoFile(match?.groups?.get("name")?.value ?: name, match?.groups?.get("version")?.value ?: "0", downloadUrl)
            }

        // Only the newest file for each library name needs to be downloaded, rather than every version in the directory
        val latestRepoFiles = repoFiles.groupBy { it.libName.lowercase() }.values.map { files -> files.maxWith { a, b -> compareVersionText(a.versionText, b.versionText) } }

        indicator?.checkCanceled()
        indicator?.text = "Fetching $bundleName vendordeps files"
        val futures: List<Pair<RepoFile, Future<String>>> = latestRepoFiles.map { repoFile ->
            repoFile to AppExecutorUtil.getAppExecutorService().submit<String> { HttpRequests.request(repoFile.downloadUrl).readString() }
        }
        val downloaded = futures.mapNotNull { (repoFile, future) ->
            indicator?.checkCanceled()
            try
            {
                val vendordeps = Vendordeps.parse(future.get()).getOrElse { throw it }
                Triple(repoFile, vendordeps, repoFile.downloadUrl)
            }
            catch (e: Exception)
            {
                logger.info("[FRC] Could not download or parse vendordeps file ${repoFile.downloadUrl}. Cause: $e")
                null
            }
        }

        // Different file names can represent the same library (e.g. a library that was renamed), so we group by the UUID
        val libraries = downloaded
            .groupBy { it.second.uuid }
            .mapNotNull { (uuid, entries) ->
                val (_, vendordeps, downloadUrl) = entries.maxWith { a, b -> compareVersionText(a.second.version.asText, b.second.version.asText) }
                val meta = metadata[uuid]
                VendorRepoLibrary(
                    uuid = uuid,
                    name = meta?.string("name")?.trim() ?: vendordeps.name,
                    description = meta?.string("description")?.trim() ?: "",
                    website = meta?.string("website")?.trim()?.ifBlank { null },
                    instructions = meta?.string("instructions")?.trim()?.ifBlank { null },
                    latestVersion = vendordeps.version,
                    downloadUrl = downloadUrl,
                    jsonUrl = vendordeps.jsonUrl?.toString()?.ifBlank { null },
                                 )
            }
            .sorted()

        return VendorRepoBundle(bundleName, libraries)
    }

    /**
     * Downloads, and parses, the vendordeps JSON file at the provided URL. Fails if the file is not a valid vendordeps file.
     * **This makes a network call and must not be called on the EDT.**
     */
    fun downloadVendordeps(url: String, indicator: ProgressIndicator? = null): Result<VendordepsDownload, Exception>
    {
        return try
        {
            val content = HttpRequests.request(url).readString(indicator)
            Vendordeps.parse(content).getOrElse { throw IllegalArgumentException("The file at $url is not a valid vendordeps JSON file: ${it.message}", it) }
                .let { Ok(VendordepsDownload(url, it, content)) }
        }
        catch (e: ProcessCanceledException)
        {
            throw e
        }
        catch (e: Exception)
        {
            Err(e)
        }
    }

    /**
     * Downloads, in parallel, the vendordeps served by the provided vendor `jsonUrl`s, returning a map of URL to the download for
     * those that were successfully downloaded and parsed. Results are cached. **This makes network calls and must not be called on the EDT.**
     */
    fun getVendordepsFromJsonUrls(urls: Collection<String>, forceRefresh: Boolean = false, indicator: ProgressIndicator? = null): Map<String, VendordepsDownload>
    {
        if (forceRefresh) urls.forEach { jsonUrlCache.remove(it) }
        val futures = urls.distinct().filter { !jsonUrlCache.containsKey(it) }.map { url ->
            url to AppExecutorUtil.getAppExecutorService().submit<Optional<VendordepsDownload>> {
                Optional.ofNullable(downloadVendordeps(url).getOrElse {
                    logger.debug("[FRC] Could not get vendordeps from jsonUrl $url. Cause: $it")
                    null
                })
            }
        }
        futures.forEach { (url, future) ->
            indicator?.checkCanceled()
            jsonUrlCache[url] = runCatching { future.get() }.getOrElse { Optional.empty() }
        }
        return urls.mapNotNull { url -> jsonUrlCache[url]?.orElse(null)?.let { url to it } }.toMap()
    }

    private data class RepoFile(val libName: String, val versionText: String, val downloadUrl: String)
}

/**
 * Compares vendor library version strings by their numeric components, so that versions with more than three parts
 * (e.g. `2026.1.26.1`) and zero-padded parts (e.g. `2026.2.09`) compare correctly. A pre-release (i.e. a version
 * with a `-` suffix such as `2026.1.1-rc-2`) is considered older than the same version without the suffix.
 */
fun compareVersionText(a: String, b: String): Int
{
    fun String.mainPart() = removePrefix("v").removePrefix("V").substringBefore('-')
    fun String.numbers() = mainPart().split('.').map { it.takeWhile(Char::isDigit).toLongOrNull() ?: 0L }
    val aNumbers = a.numbers()
    val bNumbers = b.numbers()
    for (i in 0 until maxOf(aNumbers.size, bNumbers.size))
    {
        val result = aNumbers.getOrElse(i) { 0L }.compareTo(bNumbers.getOrElse(i) { 0L })
        if (result != 0) return result
    }
    val aIsPreRelease = a.removePrefix("v").removePrefix("V").contains('-')
    val bIsPreRelease = b.removePrefix("v").removePrefix("V").contains('-')
    return when
    {
        aIsPreRelease == bIsPreRelease -> a.compareTo(b)
        aIsPreRelease                  -> -1
        else                           -> 1
    }
}

/**
 * Determines the FRC season the vendordeps is likely for. The `frcYear` property cannot be relied upon alone, since it is optional and
 * some vendors do not update it (e.g. a `2027.0.0-alpha-3` release with an `frcYear` of 2026). So the version is also used when its
 * major component is a year, either as a full year (e.g. `2026.1.2`) or as a two digit year (e.g. CTRE's `26.3.0`). The later of the two is returned.
 */
fun Vendordeps.likelySeasonYear(): Int?
{
    val major = version.asText.trim().removePrefix("v").removePrefix("V").substringBefore('.').toIntOrNull()
    val yearFromVersion = when (major)
    {
        null         -> null
        in 2000..2099 -> major
        in 20..99    -> 2000 + major
        else         -> null
    }
    return listOfNotNull(frcYear, yearFromVersion).maxOrNull()
}
