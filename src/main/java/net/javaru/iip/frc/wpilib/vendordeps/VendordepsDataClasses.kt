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

package net.javaru.iip.frc.wpilib.vendordeps


import com.beust.klaxon.JsonObject
import com.beust.klaxon.Parser
import com.github.michaelbull.result.Result
import com.intellij.json.psi.JsonFile
import com.intellij.openapi.diagnostic.logger
import com.intellij.openapi.vfs.VirtualFile
import com.intellij.psi.PsiFile
import net.javaru.iip.frc.util.letSafely
import net.javaru.iip.frc.util.tryIt
import net.javaru.iip.frc.util.uri
import net.javaru.iip.frc.util.urisList
import net.javaru.iip.frc.wpilib.extractProjectYear
import java.io.InputStream
import java.io.Reader
import java.io.StringReader
import java.net.URI
import java.nio.charset.Charset
import java.nio.file.Files
import java.nio.file.Path
import java.util.*

/**
 * A data class representing the content (and thus details/properties) of a vendordeps file.
 * Also see the [VendordepsProjectFile] which wraps this data class along with the `JsonFile`
 * for the vendordeps.
 * 
 * @see VendordepsProjectFile
 */
data class Vendordeps(
    val uuid: UUID,
    val name: String,
    val version: LibVersion,
    val frcYear: Int?, // Added in 2022. See Issue #111. Although it is not clear if this is an official property (since th official schema is massively out of date) or one added by CTRE 
    val fileName: String,
    val jsonUrl: URI?, // WPILib Command vendordeps have an empty string for the jsonUrl
    val mavenUrls: List<URI>
                     ) : Comparable<Vendordeps>
{
    companion object
    {
        private val nonConformingUuidsMap = mutableMapOf<String, UUID>()
        private val parser: Parser = Parser.default()
        private val LOG = logger<Vendordeps>()

        // @formatter:off
        fun parse(jsonFile: PsiFile): Result<Vendordeps, Throwable> = tryIt { transform(parser.parse(jsonFile.virtualFile.inputStream) as JsonObject) }
        fun parse(jsonFile: VirtualFile): Result<Vendordeps, Throwable> = tryIt { transform(parser.parse(jsonFile.inputStream) as JsonObject) }
        fun parse(jsonFile: Path, charset: Charset = Charsets.UTF_8): Result<Vendordeps, Throwable> = tryIt { transform(parser.parse(Files.newBufferedReader(jsonFile, charset)) as JsonObject) }
        fun parse(json: InputStream, charset: Charset = Charsets.UTF_8): Result<Vendordeps, Throwable> = tryIt { transform(parser.parse(json, charset) as JsonObject) }
        fun parse(json: Reader): Result<Vendordeps, Throwable> = tryIt { transform(parser.parse(json) as JsonObject) }
        fun parse(json: String): Result<Vendordeps, Throwable> = tryIt { transform(parser.parse(StringReader(json)) as JsonObject) }
        // @formatter:on

        fun transform(json: JsonObject): Vendordeps
        {
            val name = json.string("name")?.trim() ?: ""
            val version = LibVersion.parse(json.string("version")?.trim() ?: "0.0.0")
            // The season is 'frcYear' before 2027, and 'wpilibYear' (e.g. "2027_alpha7", as the WPILib project year) from 2027 on.
            // If both are present (e.g. a 2027 vendordeps that kept its 'frcYear'), the later one is used.
            val frcYear = listOfNotNull(json.parseYear("frcYear"), json.parseYear("wpilibYear")).maxOrNull()
            val fileName = json.string("fileName")?.trim() ?: ""
            val jsonUrl = json.uri("jsonUrl")
            val mavenUrls = json.urisList("mavenUrls")
            val uuid = json.parseUuid(name, fileName, jsonUrl)
            return Vendordeps(uuid, name, version, frcYear, fileName, jsonUrl, mavenUrls)

        }

        private fun JsonObject.parseYear(key: String): Int? = try
        {
            int(key)
        }
        catch (t: ClassCastException)
        {
            // The year should be an int. But just in case a vendor enters it as a String, we want to handle it.
            // Beta/alpha vendordeps use values such as "2026beta" or "2027_alpha7", so we extract just the year in such cases.
            string(key)?.let { it.trim().toIntOrNull() ?: extractProjectYear(it) }
        }

        private const val navxUuidString = "cb311d09-36e9-4143-a032-55bb2b94443b"
        private val navxUuid: UUID = UUID.fromString(navxUuidString)
        val dmc60cRemappedUuid: UUID = UUID.fromString("d2dafb2b-4b81-40d1-98ff-7e66289fcfb4")
        val libCuRemappedUuid: UUID = UUID.fromString("f002471f-3077-469a-8b00-3d5b343e8a68")

        private fun JsonObject.parseUuid(name: String, fileName: String, jsonUrl: URI?): UUID
        {
            val uuidString = this.string("uuid")?.trim()
            // We have to handle some special cases
            @Suppress("SpellCheckingInspection")
            return when
            {
                uuidString == null                                     -> nonConformingUuidsMap.computeIfAbsent(name) { UUID.randomUUID() }
                // the  Coppersource "LibCu" library has an invalid UUID. I've opened an issue: https://github.com/Coppersource/LibCu/issues/4
                // For 2022, they resoved the issue, but we still check and map to the new valid UUID 
                (uuidString == "libcufrc-e6e8-4db6-89f0-copperforge0") -> libCuRemappedUuid
                // Honor the navX UUID when in the navX file
                (uuidString == navxUuidString &&
                    (
                        name.contains("navX", ignoreCase = true)) ||
                    fileName.contains("navX", ignoreCase = true) ||
                    jsonUrl?.toString()?.contains("kauailabs", ignoreCase = true) ?: false ||
                    jsonUrl?.toString()?.contains("navX", ignoreCase = true) ?: false
                    )                                                  -> navxUuid
                // Handle the known duplicate UUID of the DMC60C lib: https://github.com/Digilent/dmc60c-frc-api/issues/13
                (uuidString == navxUuidString &&
                    (
                        name.contains("DMC60C", ignoreCase = true)) ||
                    fileName.contains("DMC60C", ignoreCase = true) ||
                    jsonUrl?.toString()?.contains("DMC60C", ignoreCase = true) ?: false
                    )                                                  -> dmc60cRemappedUuid
                // Handle any other duplicates of the navx UUID
                uuidString == navxUuidString                           -> nonConformingUuidsMap.computeIfAbsent(name) { UUID.randomUUID() }
                else                                                   -> try
                {
                    UUID.fromString(uuidString)
                }
                catch (e: Exception)
                {
                    LOG.warn("[FRC] Vendordeps UUID string '$uuidString' could not be converted to UUID. Reason: $e")
                    nonConformingUuidsMap.computeIfAbsent(name) { UUID.randomUUID() }
                }
            }
        }
    }

    override fun compareTo(other: Vendordeps): Int = compareValuesBy(this, other, {it.uuid}, {it.version})

    /** Returns a Simple String of: $name: $version */
    @Suppress("unused")
    fun toStringSimple(): String = "$name : $version"
}

/**
 * A data class to virtually represent a Vendordeps file. It contains the properties:
 * 
 * @param jsonPsiFile the [JsonFile] (sub-interface of [PsiFile]) for the vendordeps file
 * @param vendordeps a [Vendordeps] data class representing the content of the vendordeps file
 * 
 * @see Vendordeps
 */
@Suppress("MemberVisibilityCanBePrivate")
data class VendordepsProjectFile(val jsonPsiFile: JsonFile, val vendordeps: Vendordeps) : Comparable<VendordepsProjectFile>
{
    val virtualFile: VirtualFile by lazy { jsonPsiFile.virtualFile }
    val nioPath: Path by lazy { virtualFile.toNioPath() }
    override fun compareTo(other: VendordepsProjectFile): Int = 
        compareValuesBy(this, other, { it.vendordeps }, { it.nioPath })
}

private val uuidRegex =     """"uuid"\s*:\s*"(?<jsonValue>[^"]+)"""".toRegex() // we allow for invalid UUIDs
private val fileNameRegex = """"fileName"\s*:\s*"(?<jsonValue>[^"]+)"""".toRegex()
private val nameRegex =     """"name"\s*:\s*"(?<jsonValue>[^"]+)"""".toRegex()
private val versionRegex =  """"version"\s*:\s*"(?<jsonValue>[^"]+)"""".toRegex()
private val frcYearRegex =  """"(?:frcYear|wpilibYear)"\s*:\s*"?(?<jsonValue>[^",]+)"?,""".toRegex()
private val jsonUrlRegex =  """"jsonUrl"\s*:\s*"(?<jsonValue>[^"]+)"""".toRegex()
data class InvalidVendordepsProjectFile(val jsonPsiFile: JsonFile)
{
    val virtualFile: VirtualFile by lazy { jsonPsiFile.virtualFile }
    @Suppress("unused")
    val nioPath: Path by lazy { virtualFile.toNioPath() }
    val data = extractVendordepsData(jsonPsiFile.text)
    data class VendordepsData(
        val libUuidString: String?,
        val libUuid: UUID?,
        val libFileName: String?,
        val libName: String?,
        val libVersionString: String?,
        val libVersion: LibVersion?,
        val libFrcYearString: String?,
        val libFrcYear: Int?,
        val libJsonUrlString: String?,
        val libJsonUrl: URI?, // WPILib Command vendordeps have an empty string for the jsonUrl
        //val libMavenUrls: List<URI>, For now, I do not think we need this
                             )
    companion object
    {
        fun extractVendordepsData(text: String): VendordepsData
        {
            fun Regex.findJsonValue(): String? = this.find(text)?.groups?.get("jsonValue")?.value?.trim()
            val libUuidString = uuidRegex.findJsonValue()
            val libUuid = libUuidString.letSafely { UUID.fromString(it) }
            val libFileName = fileNameRegex.findJsonValue()
            val libName = nameRegex.findJsonValue()
            val libVersionString = versionRegex.findJsonValue()
            val libVersion = libVersionString?.let { LibVersion.parse(it) }
            val libFrcYearString = frcYearRegex.findJsonValue()
            val libFrcYear = libFrcYearString?.letSafely { it.toIntOrNull() ?: extractProjectYear(it) }
            val libJsonUrlString = jsonUrlRegex.findJsonValue()
            val libJsonUrl = libJsonUrlString.letSafely { URI(it) }
            
            return VendordepsData(
                libUuidString, libUuid, libFileName, libName, libVersionString, libVersion, libFrcYearString, libFrcYear, libJsonUrlString, libJsonUrl,)
        }
    }
}

/** A data class to represent a known Vendordeps library. */
@Suppress("unused")
data class KnownVendordepsInfo(
    val uuid:UUID,
    val name: String,
    val jsonUrl: URI, // TODO: Need a way to represent this by year for libs that do such, and not for those that do not
                      //       It would be nice to represent it as "Before 2022", "2022:, 2023" etc.
                      //       So an Int to URL pair or map would likely not work         
                              ) : Comparable<KnownVendordepsInfo>
{
    override fun compareTo(other: KnownVendordepsInfo): Int = compareValuesBy(this, other, {it.uuid}, {it.name})
}


