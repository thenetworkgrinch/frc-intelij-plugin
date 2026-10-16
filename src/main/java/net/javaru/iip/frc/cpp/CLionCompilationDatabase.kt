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

import com.intellij.openapi.actionSystem.ActionManager
import com.intellij.openapi.diagnostic.logger
import com.intellij.openapi.externalSystem.importing.ImportSpecBuilder
import com.intellij.openapi.externalSystem.model.ProjectSystemId
import com.intellij.openapi.externalSystem.util.ExternalSystemApiUtil
import com.intellij.openapi.externalSystem.util.ExternalSystemUtil
import com.intellij.openapi.project.Project
import com.intellij.openapi.util.io.FileUtil
import com.intellij.openapi.vfs.VirtualFile

/**
 * Loads a `compile_commands.json` file as CLion's Compilation Database project model, which provides CLion's C++ code insight.
 *
 * CLion's compilation database support (the bundled `com.intellij.clion-compdb` plugin) has no public API, so the model is
 * linked via its 'Load Compilation Database Project' action (as when the user selects it on the file), and reloaded via the
 * platform's External System API, as the model is an External System. This avoids needing to compile against CLion.
 */
internal object CLionCompilationDatabase
{
    private val logger = logger<CLionCompilationDatabase>()

    /** The ID of CLion's `CompDBLoadProjectAction`, which has a `performLink(Project, VirtualFile)` method and the model's `getSystemId()`. */
    private const val loadProjectActionId = "CompDB.LoadMakefileProject"

    /** Links the compile commands file as the project's compilation database, or reloads it if it is already linked. Must be called on the EDT. */
    fun linkOrReload(project: Project, compileCommandsFile: VirtualFile)
    {
        if (project.isDisposed) return
        val action = ActionManager.getInstance().getAction(loadProjectActionId)
        if (action == null)
        {
            logger.warn("[FRC] CLion's '$loadProjectActionId' action was not found. Unable to load '${compileCommandsFile.path}'.")
            return
        }
        try
        {
            val systemId = action.javaClass.getMethod("getSystemId").invoke(action) as ProjectSystemId
            val linkedPath = ExternalSystemApiUtil.getSettings(project, systemId).linkedProjectsSettings
                .mapNotNull { it.externalProjectPath }
                .firstOrNull { FileUtil.pathsEqual(it, compileCommandsFile.path) || FileUtil.pathsEqual(it, compileCommandsFile.parent?.path) }
            if (linkedPath == null)
            {
                logger.info("[FRC] Loading '${compileCommandsFile.path}' as the compilation database of project '${project.name}'")
                action.javaClass.getMethod("performLink", Project::class.java, VirtualFile::class.java).invoke(action, project, compileCommandsFile)
            }
            else
            {
                logger.info("[FRC] Reloading the compilation database '$linkedPath' of project '${project.name}'")
                ExternalSystemUtil.refreshProject(linkedPath, ImportSpecBuilder(project, systemId))
            }
        }
        catch (e: Exception)
        {
            // i.e. CLion's (internal) action has changed
            logger.warn("[FRC] Could not load '${compileCommandsFile.path}' as the compilation database of project '${project.name}': $e", e)
        }
    }
}
