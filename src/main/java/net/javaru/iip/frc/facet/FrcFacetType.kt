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

package net.javaru.iip.frc.facet

import com.intellij.facet.Facet
import com.intellij.facet.FacetType
import com.intellij.facet.FacetTypeRegistry
import com.intellij.facet.ui.DefaultFacetSettingsEditor
import com.intellij.openapi.module.Module
import com.intellij.openapi.module.ModuleType
import net.javaru.iip.frc.util.isJavaPluginAvailable
import com.intellij.openapi.project.Project
import icons.FrcIcons.FRC
import javax.swing.Icon



class FrcFacetType : FacetType<FrcFacet, FrcFacetConfiguration>(FrcFacet.FACET_TYPE_ID, FrcFacet.FACET_TYPE_ID_STRING, FrcFacet.FACET_NAME)
{
    // private val LOG = Logger.getInstance(FrcFacetType::class.java)
    
    companion object
    {
        val INSTANCE: FrcFacetType
            //get() = findInstance(FrcFacetType::class.java) // This seems to be the older methodology
            get() =  FacetTypeRegistry.getInstance().findFacetType(FrcFacet.FACET_TYPE_ID) as FrcFacetType  // an alternative methodology I found in the Kotlin Plugin: org/jetbrains/kotlin/idea/facet/KotlinFacetType.kt:25 It is alos used by a number of other JetBrains writen plugins
    }
    
    override fun createDefaultConfiguration(): FrcFacetConfiguration
    {
        return FrcFacetConfiguration()
    }

    /**
     * Create a new facet instance
     * @param module parent module for facet. Must be passed to [Facet] constructor
     * @param name name of facet. Must be passed to [Facet] constructor
     * @param facetConfiguration facet configuration. Must be passed to [Facet] constructor
     * @param underlyingFacet underlying facet. Must be passed to [Facet] constructor
     * @return a created facet
     */
    override fun createFacet(module: Module, name: String, facetConfiguration: FrcFacetConfiguration, underlyingFacet: Facet<*>?): FrcFacet
    {
        @Suppress("UNCHECKED_CAST")
        return FrcFacet(this, module, name, facetConfiguration, underlyingFacet)
    }


    override fun isSuitableModuleType(moduleType: ModuleType<*>): Boolean
    {
        // The Java module type is checked by its ID, since the Java plugin is not available in CLion, where modules of any type can be used
        return !isJavaPluginAvailable || moduleType.id == "JAVA_MODULE"
    }


    override fun createDefaultConfigurationEditor(project: Project, configuration: FrcFacetConfiguration): DefaultFacetSettingsEditor?
    {
        // super returns null - may want to implement if needed
        return super.createDefaultConfigurationEditor(project, configuration)
    }


    override fun getIcon(): Icon?
    {
        return FRC.FIRST_ICON_MEDIUM_16
    }


    override fun getHelpTopic(): String?
    {
        // super returns null - may want to implement if help system is every added
        return super.getHelpTopic()
    }
}
