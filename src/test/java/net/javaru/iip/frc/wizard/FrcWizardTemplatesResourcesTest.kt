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

import org.junit.jupiter.api.Assertions.assertEquals
import org.junit.jupiter.api.Assertions.assertNotNull
import org.junit.jupiter.api.Assertions.assertTrue
import org.junit.jupiter.params.ParameterizedTest
import org.junit.jupiter.params.provider.CsvSource
import org.junit.jupiter.params.provider.ValueSource

/**
 * Sanity checks for the per-year New Project Wizard template resources. These catch a missing year directory
 * (in which case the wizard silently falls back to the previous year's templates) and stale vendordeps `frcYear`
 * values, which GradleRIO rejects with "Vendor Dependency ... has invalid year".
 */
internal class FrcWizardTemplatesResourcesTest
{
    private fun resourceExists(path: String) = javaClass.classLoader.getResource(path) != null

    @ParameterizedTest
    @ValueSource(ints = [2025, 2026])
    fun `every template definition for the year has a resources directory`(year: Int)
    {
        // Note: these functions return enum arrays cast to Array<FrcWizardTemplateDefinition>, so concatenate as lists
        val definitions = projectTemplateDefinitionsFor(year).toList() + exampleTemplateDefinitionsFor(year).toList()
        assertTrue(definitions.isNotEmpty())
        val missing = definitions
            .map { "frc-wizard-templates/$year/${it.templateResourcesDirName()}" }
            .filterNot { resourceExists(it) }
        assertEquals(emptyList<String>(), missing, "Template definitions without a resources directory")
    }

    @ParameterizedTest
    @CsvSource(
        "2025, WPILibNewCommands.json.ftl", "2025, XRPVendordep.json.ftl", "2025, RomiVendordep.json.ftl",
        "2026, WPILibNewCommands.json.ftl", "2026, XRPVendordep.json.ftl", "2026, RomiVendordep.json.ftl",
              )
    fun `vendordeps declare the template year as frcYear`(year: Int, fileName: String)
    {
        val path = "frc-wizard-templates/$year/-DEFAULT-FILES-/configs/vendordeps/$fileName"
        val text = javaClass.classLoader.getResource(path)?.readText()
        assertNotNull(text, "Missing resource: $path")
        val frcYear = """"frcYear"\s*:\s*"?(\d{4})"?""".toRegex().find(text!!)?.groupValues?.get(1)
        assertEquals(year.toString(), frcYear, "frcYear in $path")
    }
}
