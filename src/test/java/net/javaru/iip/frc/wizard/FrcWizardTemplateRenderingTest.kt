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

import freemarker.template.Configuration
import freemarker.template.Template
import net.javaru.iip.frc.freemarker.FM_TEMPLATE_EXT_WITH_DOT
import net.javaru.iip.frc.freemarker.KOTLIN_FM_TEMPLATE_FILE_EXT
import net.javaru.iip.frc.freemarker.KOTLIN_SCRIPT_FM_TEMPLATE_FILE_EXT
import net.javaru.iip.frc.freemarker.freemarkerConfiguration
import net.javaru.iip.frc.freemarker.freemarkerConfigurationForKotlinTemplates
import net.javaru.iip.frc.wizard.FrcModuleBuilder.TemplatePaths
import net.javaru.iip.frc.wizard.FrcProjectWizardData.GradleDslOption
import net.javaru.iip.frc.wpilib.version.WpiLibVersion
import net.javaru.iip.frc.wpilib.version.WpiLibVersionImpl
import org.junit.jupiter.api.Assertions.assertEquals
import org.junit.jupiter.api.Assertions.assertTrue
import org.junit.jupiter.params.ParameterizedTest
import org.junit.jupiter.params.provider.ValueSource
import java.nio.file.Files
import java.nio.file.Path
import java.nio.file.Paths
import java.util.Locale
import kotlin.io.path.createDirectories
import kotlin.io.path.exists
import kotlin.io.path.invariantSeparatorsPathString
import kotlin.io.path.isRegularFile
import kotlin.io.path.name
import kotlin.io.path.readText
import kotlin.io.path.relativeTo
import kotlin.io.path.writeText

/**
 * Renders every project template for the recent FRC years (in each supported language, with both Gradle DSLs)
 * and a few complex examples, mirroring the file layout produced by [FrcModuleBuilder.setupRootModel] (minus the IDE-specific
 * `.gitignore` generation and Gradle import). This catches Freemarker errors and wrong vendordeps years without
 * needing a running IDE.
 *
 * Set the `FRC_TEMPLATE_RENDER_OUTPUT_DIR` environment variable to keep the rendered projects (e.g. to build
 * them with GradleRIO), in a subdirectory per year. Otherwise, they are rendered into a temp directory that is
 * deleted afterwards.
 */
internal class FrcWizardTemplateRenderingTest
{
    /** The WPILib (GradleRIO) version to render each year's templates with. */
    private val wpilibVersionsByYear = mapOf(
        2025 to "2025.3.2",
        2026 to "2026.2.1",
                                            )
    private val fmStd = freemarkerConfiguration(this, "/")
    private val fmKotlin = freemarkerConfigurationForKotlinTemplates(this, "/")

    @ParameterizedTest
    @ValueSource(ints = [2025, 2026])
    fun `render templates`(year: Int)
    {
        val wpilibVersion = WpiLibVersionImpl.parse(wpilibVersionsByYear.getValue(year))
        val keepDir = System.getenv("FRC_TEMPLATE_RENDER_OUTPUT_DIR")?.let { Paths.get(it).resolve(year.toString()) }
        val outRoot = keepDir?.also { it.createDirectories() } ?: Files.createTempDirectory("frc-$year-templates")
        // Complex examples, plus the examples whose resource directory names don't follow the enum-name convention
        val examplesToRender = setOf("HatchbotInlined", "HatchbotTraditional", "RomiReference", "XrpReference", "RapidReactCommandBot",
                                     "PdpCanMonitoring", "Mechanism2D", "SimpleVision", "DifferentialDrivePoseEstimator", "I2CCommunication")
        val definitions = projectTemplateDefinitionsFor(year).toList() +
                          exampleTemplateDefinitionsFor(year).filter { (it as Enum<*>).name in examplesToRender }
        val rendered = mutableListOf<Path>()
        try
        {
            for (definition in definitions)
            {
                for (language in definition.availableTemplateLanguages)
                {
                    for (dsl in GradleDslOption.entries)
                    {
                        val name = "${definition.templateResourcesDirName()}-${language.name.lowercase()}-${if (dsl == GradleDslOption.GroovyDSL) "groovy" else "kts"}"
                        rendered.add(renderProject(year, wpilibVersion, definition, language, dsl, outRoot.resolve(name)))
                    }
                }
            }
            assertTrue(rendered.size >= 30, "Expected at least 30 rendered projects but got ${rendered.size}")
            rendered.forEach { project ->
                val vendordeps = project.resolve("vendordeps")
                Files.list(vendordeps).use { files ->
                    files.filter { it.name.endsWith(".json") }.forEach {
                        assertTrue(it.readText().contains(""""frcYear": "$year""""), "$it does not declare frcYear $year")
                    }
                }
                assertEquals(year.toString(), """"projectYear"\s*:\s*"(\d+)"""".toRegex().find(project.resolve(".wpilib/wpilib_preferences.json").readText())?.groupValues?.get(1))
            }
            println("[FRC] Rendered ${rendered.size} $year projects to $outRoot")
        }
        finally
        {
            openedFileSystems.values.forEach { runCatching { it.close() } }
            openedFileSystems.clear()
            if (keepDir == null) outRoot.toFile().deleteRecursively()
        }
    }

    private fun renderProject(year: Int,
                              wpilibVersion: WpiLibVersion,
                              definition: FrcWizardTemplateDefinition,
                              language: TemplateLanguageOption,
                              dsl: GradleDslOption,
                              target: Path): Path
    {
        val data = FrcProjectWizardData(
            teamNumber = 1234,
            wpilibVersion = wpilibVersion,
            frcWizardTemplateDefinition = definition,
            enableDesktopSupport = definition.robotType.includeDesktopSupportDefault,
            includeKotlinSupport = language == TemplateLanguageOption.Kotlin,
            kotlinVersion = KotlinVersion(2, 1, 0),
            gradleDslOption = dsl,
            templateLanguageOption = language,
            // true short-circuits FrcProjectWizardData.gradleDistributionUrl's lookup of FrcApplicationSettings (an application service)
            useGradleAllDistribution = true,
                                       )
        val base = Paths.get(TemplatePaths.frcWizardTemplatesDirName, year.toString())
        val defaults = base.resolve(TemplatePaths.defaultFilesDirName)
        val languageSubPath = if (language == TemplateLanguageOption.Java) TemplatePaths.javaCodeSubPath else TemplatePaths.kotlinCodeSubPath
        val selectedTemplateBase = base.resolve(definition.templateResourcesDirName()).resolve(languageSubPath)
        val templateHasUnitTests = resourceDir(selectedTemplateBase).resolve("src/test").exists()
        val copyDefaultUnitTestFiles = if (templateHasUnitTests || data.isExampleTemplate) false else data.includeJUnitSupport
        val copyTemplateUnitTestFiles = if (templateHasUnitTests && data.includeJUnitSupport) true else if (data.isExampleTemplate) false else data.includeJUnitSupport

        // Same order and filters as FrcModuleBuilder.setupRootModel / copyAllResourcesToModuleRoot
        copyAll(data, target, defaults.resolve(if (dsl == GradleDslOption.GroovyDSL) TemplatePaths.gradleGroovyDslSubPath else TemplatePaths.gradleKotlinDslSubPath))
        copyAll(data, target, defaults.resolve(TemplatePaths.gradleWrapperSubPath))
        copyAll(data, target, defaults.resolve(TemplatePaths.configsSubPath)) {
            when
            {
                it.name.contains("frc-plugin-notes-README.txt") -> false
                it.name.contains("WPILibOldCommands") -> definition.commandVersion == 1
                it.name.contains("WPILibNewCommands") -> definition.commandVersion == 2
                it.name.contains("XRPVendordep")      -> data.isXrpTemplate
                it.name.contains("RomiVendordep")     -> data.isRomiTemplate
                else                                  -> true
            }
        }
        copyAll(data, target, defaults.resolve(TemplatePaths.commonCodeSubPath))
        copyAll(data, target, defaults.resolve(languageSubPath), copyUnitTestFiles = copyDefaultUnitTestFiles)
        copyAll(data, target, defaults.resolve(TemplatePaths.extrasSubPath).resolve(TemplatePaths.vsCodeConfigsSubPath))
        if (definition.includeAutoGenReadMe) copyAll(data, target, defaults.resolve(TemplatePaths.extrasSubPath).resolve(TemplatePaths.projectAutoGenReadMeSubPath))
        copyAll(data, target, selectedTemplateBase, copyUnitTestFiles = copyTemplateUnitTestFiles)
        target.resolve("gradlew").toFile().setExecutable(true)
        return target
    }

    /** Resources come from the composed plugin jar on the test classpath (as at runtime), or from a directory. */
    private val openedFileSystems = mutableMapOf<java.net.URI, java.nio.file.FileSystem>()

    private fun resourceDir(resourcePath: Path): Path
    {
        val url = javaClass.classLoader.getResource(resourcePath.invariantSeparatorsPathString)
                  ?: error("Resource directory not found: $resourcePath")
        val uri = url.toURI()
        if (uri.scheme == "jar")
        {
            val jarUri = java.net.URI.create(uri.toString().substringBefore("!/"))
            val fs = openedFileSystems.getOrPut(jarUri) {
                try { java.nio.file.FileSystems.getFileSystem(uri) }
                catch (_: java.nio.file.FileSystemNotFoundException) { java.nio.file.FileSystems.newFileSystem(uri, emptyMap<String, Any>()) }
            }
            return fs.getPath(uri.toString().substringAfter("!"))
        }
        return Paths.get(uri)
    }

    private fun copyAll(data: FrcProjectWizardData,
                        target: Path,
                        resourcePath: Path,
                        copyUnitTestFiles: Boolean = data.includeJUnitSupport,
                        keepFilter: (Path) -> Boolean = { true })
    {
        val srcBase = resourceDir(resourcePath)
        Files.walk(srcBase).use { stream ->
            stream.filter { it.isRegularFile() }
                .filter { copyUnitTestFiles || !it.invariantSeparatorsPathString.contains("src/test") }
                .filter(keepFilter)
                .forEach { src ->
                    val relative = src.relativeTo(srcBase).invariantSeparatorsPathString
                        .replace("base-package/", "${data.basePackageAsDirString}/")
                    if (relative.endsWith(FM_TEMPLATE_EXT_WITH_DOT))
                    {
                        val dest = target.resolve(relative.removeSuffix(FM_TEMPLATE_EXT_WITH_DOT))
                        dest.parent.createDirectories()
                        val cfg: Configuration = if (relative.endsWith(KOTLIN_FM_TEMPLATE_FILE_EXT) || relative.endsWith(KOTLIN_SCRIPT_FM_TEMPLATE_FILE_EXT)) fmKotlin else fmStd
                        val template = Template(relative, src.readText(), cfg)
                        Files.newBufferedWriter(dest, Charsets.UTF_8).use { writer ->
                            val env = template.createProcessingEnvironment(hashMapOf("data" to data), writer)
                            env.outputEncoding = Charsets.UTF_8.toString()
                            env.locale = Locale.ENGLISH
                            env.process()
                        }
                    }
                    else
                    {
                        val dest = target.resolve(relative)
                        dest.parent.createDirectories()
                        Files.copy(src, dest, java.nio.file.StandardCopyOption.REPLACE_EXISTING)
                    }
                }
        }
    }
}
