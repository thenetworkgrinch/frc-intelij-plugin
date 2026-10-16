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

package net.javaru.iip.frc.cpp

import com.intellij.openapi.actionSystem.ActionUpdateThread
import com.intellij.openapi.actionSystem.AnAction
import com.intellij.openapi.actionSystem.AnActionEvent
import com.intellij.openapi.application.ApplicationManager
import com.intellij.openapi.application.ModalityState
import com.intellij.openapi.project.DumbAware
import com.intellij.openapi.project.Project
import com.intellij.openapi.ui.DialogWrapper
import com.intellij.openapi.ui.popup.JBPopupFactory
import com.intellij.openapi.ui.popup.PopupStep
import com.intellij.openapi.ui.popup.util.BaseListPopupStep
import com.intellij.ui.components.JBCheckBox
import com.intellij.ui.dsl.builder.panel
import net.javaru.iip.frc.notify.FrcNotifyType
import javax.swing.JComponent

/** Base for the actions that are only available in WPILib C++ projects. */
abstract class AbstractWpiLibCppAction : AnAction(), DumbAware
{
    override fun getActionUpdateThread(): ActionUpdateThread = ActionUpdateThread.BGT

    override fun update(e: AnActionEvent)
    {
        val project = e.project
        e.presentation.isEnabledAndVisible = project != null && WpiLibCppCompilationDatabaseService.getInstance(project).cppProjectRoots.isNotEmpty()
    }
}

/** Regenerates, via GradleRIO, the compilation database that provides the C++ code insight. */
class RegenerateCppCompileCommandsAction : AbstractWpiLibCppAction()
{
    override fun actionPerformed(e: AnActionEvent)
    {
        val project = e.project ?: return
        WpiLibCppCompilationDatabaseService.getInstance(project).update(userInitiated = true)
    }
}

/** Chooses the libraries (WPILib and the vendordeps) whose headers are given compile commands, e.g. to speed up CLion's indexing. */
class ChooseCppLibraryHeadersAction : AbstractWpiLibCppAction()
{
    override fun actionPerformed(e: AnActionEvent)
    {
        val project = e.project ?: return
        chooseCppLibraryHeaders(project)
    }
}

/** Shows the dialog to choose the libraries whose headers are given compile commands, and reloads the compilation database if they changed. */
fun chooseCppLibraryHeaders(project: Project)
{
    val service = WpiLibCppCompilationDatabaseService.getInstance(project)
    ApplicationManager.getApplication().executeOnPooledThread {
        val libraries = service.getHeaderLibraries()
        val disabledLibraries = service.getDisabledHeaderLibraries()
        ApplicationManager.getApplication().invokeLater({
            val dialog = CppLibraryHeadersDialog(project, libraries, disabledLibraries)
            if (dialog.showAndGet() && dialog.disabledLibraries != disabledLibraries)
            {
                ApplicationManager.getApplication().executeOnPooledThread { service.setDisabledHeaderLibraries(dialog.disabledLibraries) }
            }
        }, ModalityState.nonModal(), project.disposed)
    }
}

private class CppLibraryHeadersDialog(project: Project, libraries: List<String>, disabledLibraries: Set<String>) : DialogWrapper(project)
{
    private val checkBoxes = libraries.associateWith { JBCheckBox(it, it !in disabledLibraries) }
    // Keeps the disabled libraries that are not currently listed (e.g. a vendordep that was removed, and may be added back)
    private val unlistedDisabledLibraries = disabledLibraries - libraries.toSet()

    val disabledLibraries: Set<String>
        get() = unlistedDisabledLibraries + checkBoxes.filterValues { !it.isSelected }.keys

    init
    {
        title = "C++ Library Headers"
        init()
    }

    override fun createCenterPanel(): JComponent = panel {
        row {
            text("The headers of the checked libraries are given compile commands, so they have code insight when opened. " +
                 "Uncheck libraries if CLion's indexing is slow. Vendordeps that are added later are included.", maxLineLength = 60)
        }
        checkBoxes.values.forEach { checkBox -> row { cell(checkBox) } }
    }
}

/** Selects the target (platform and build type) whose compile commands are used for the C++ code insight. */
class SelectCppCodeInsightTargetAction : AbstractWpiLibCppAction()
{
    override fun actionPerformed(e: AnActionEvent)
    {
        val project = e.project ?: return
        val service = WpiLibCppCompilationDatabaseService.getInstance(project)
        ApplicationManager.getApplication().executeOnPooledThread {
            val (targets, currentTarget) = service.getTargets()
            ApplicationManager.getApplication().invokeLater({
                if (targets.isEmpty())
                {
                    FrcNotifyType.ACTIONABLE_WARN.builder()
                        .withContent("There are no C++ compile commands yet. Regenerate them first (Tools | FRC | Regenerate C++ Compile Commands).")
                        .withFrcPrefixedTitle("No C++ targets")
                        .notify(project)
                    return@invokeLater
                }
                val step = object : BaseListPopupStep<String>("C++ Code Insight Target", targets)
                {
                    override fun getTextFor(value: String): String = if (value == currentTarget) "$value (current)" else value

                    override fun onChosen(selectedValue: String, finalChoice: Boolean): PopupStep<*>?
                    {
                        if (selectedValue != currentTarget) service.selectTarget(selectedValue)
                        return FINAL_CHOICE
                    }
                }
                step.defaultOptionIndex = targets.indexOf(currentTarget).coerceAtLeast(0)
                JBPopupFactory.getInstance().createListPopup(step).showCenteredInCurrentWindow(project)
            }, ModalityState.nonModal(), project.disposed)
        }
    }
}
