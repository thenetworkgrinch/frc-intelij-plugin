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

package net.javaru.iip.frc.services

import com.intellij.psi.PsiElement
import com.intellij.psi.PsiFile
import net.javaru.iip.frc.util.isGroovyPluginAvailable
import org.jetbrains.plugins.groovy.lang.psi.GroovyFile
import org.jetbrains.plugins.groovy.lang.psi.GroovyPsiElement
import org.jetbrains.plugins.groovy.lang.psi.GroovyRecursiveElementVisitor
import org.jetbrains.plugins.groovy.lang.psi.api.statements.GrVariable
import org.jetbrains.plugins.groovy.lang.psi.api.statements.blocks.GrClosableBlock
import org.jetbrains.plugins.groovy.lang.psi.api.statements.expressions.GrApplicationStatement
import org.jetbrains.plugins.groovy.lang.psi.api.statements.expressions.GrCommandArgumentList
import org.jetbrains.plugins.groovy.lang.psi.api.statements.expressions.GrReferenceExpression
import org.jetbrains.plugins.groovy.lang.psi.api.statements.expressions.literals.GrLiteral
import org.jetbrains.plugins.groovy.lang.psi.impl.PsiImplUtil

/**
 * The Groovy PSI based handling of Gradle build files. The Groovy plugin is optional, as it is not available in CLion, so this
 * object must only be used once [isGroovyPluginAvailable] is checked, since (JVM) verifying it requires the Groovy classes. Code
 * that uses it should otherwise fall back to the file's text.
 */
internal object GroovyGradleBuildPsi
{
    fun isGroovyFile(psiFile: PsiFile): Boolean = psiFile is GroovyFile

    /** The value of the `includeDesktopSupport` variable, or `null` if it is not found. */
    fun findIncludeDesktopSupport(psiFile: PsiFile): Boolean?
    {
        var result: Boolean? = null
        (psiFile as GroovyFile).accept(
            object : GroovyRecursiveElementVisitor()
            {
                override fun visitElement(element: GroovyPsiElement)
                {
                    super.visitElement(element)
                    if (element is GrVariable && element.name == "includeDesktopSupport")
                    {
                        val literal = element.children.asSequence().filter { it is GrLiteral }.firstOrNull()
                        result = literal?.firstChild?.text?.toBoolean()
                    }
                }
            })
        return result
    }

    /** Whether the file has a reference expression that is (or, if [useContains], contains) the target text. */
    fun hasReferenceText(psiFile: PsiFile, targetText: String, useContains: Boolean): Boolean
    {
        var result = false
        (psiFile as GroovyFile).accept(
            object : GroovyRecursiveElementVisitor()
            {
                override fun visitReferenceExpression(referenceExpression: GrReferenceExpression)
                {
                    super.visitReferenceExpression(referenceExpression)
                    if (if (useContains) referenceExpression.text.contains(targetText) else referenceExpression.text == targetText)
                    {
                        result = true
                    }
                }
            })
        return result
    }

    /**
     * Updates the version of the GradleRIO plugin declaration (in the `plugins` block). Legacy (`buildscript` & `apply plugin`)
     * syntax is not supported. Calls [onUpdated] once the version is updated.
     *
     * @return `false` if a `plugins` block was found without a GradleRIO plugin declaration, otherwise `true`
     */
    fun updateGradleRioVersion(psiFile: PsiFile, gradleRioId: String, versionString: String, onUpdated: () -> Unit): Boolean
    {
        // Examples of working with a Gradle PSI file:
        //     ConvertGStringToStringIntention.processIntention()
        //     GradleMiscContributor.process()
        var found = true
        (psiFile as GroovyFile).accept(
            object : GroovyRecursiveElementVisitor()
            {
                override fun visitElement(element: GroovyPsiElement)
                {
                    super.visitElement(element)
                    if (element is GrReferenceExpression && element.qualifiedReferenceName == "plugins")
                    {
                        // We have the plugins block… now let's find the GradleRIO declaration
                        var block: PsiElement? = element.nextSibling
                        while (block != null && block !is GrClosableBlock)
                        {
                            block = block.nextSibling
                        }

                        if (block is GrClosableBlock)
                        {
                            // children will include things like PsiWhiteSpace, PsiElement(new line), GrParameterList (likely empty)
                            // We want the "call expressions" which are the plugin declarations
                            val gradleRioCallExpression = block.children
                                .filterIsInstance<GrApplicationStatement>()
                                .firstOrNull { it.text.contains(gradleRioId) }

                            if (gradleRioCallExpression == null)
                            {
                                found = false
                            }
                            else
                            {
                                // The Call Expression has two primary children
                                //     GrReferenceExpression [Reference Expression] : "id "edu.wpi.first.GradleRIO" version"
                                //     GrCommandArgumentList [Command Arguments] : "2021.2.3"
                                gradleRioCallExpression
                                    .children
                                    .filterIsInstance<GrCommandArgumentList>()
                                    .firstOrNull()
                                    ?.children
                                    ?.filterIsInstance<GrLiteral>()
                                    ?.firstOrNull()
                                    ?.let { literal: GrLiteral ->
                                        val replacement = if (literal.text?.startsWith('\'') == true) "'$versionString'" else "\"$versionString\""
                                        PsiImplUtil.replaceExpression(replacement, literal)
                                        onUpdated()
                                    }
                            }
                        }
                    }
                }
            })
        return found
    }
}
