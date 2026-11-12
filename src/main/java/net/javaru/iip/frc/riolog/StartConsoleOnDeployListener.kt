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

package net.javaru.iip.frc.riolog

import com.intellij.execution.ExecutionListener
import com.intellij.execution.process.ProcessHandler
import com.intellij.execution.runners.ExecutionEnvironment
import com.intellij.openapi.diagnostic.logger
import com.intellij.openapi.externalSystem.service.execution.ExternalSystemRunConfiguration
import com.intellij.openapi.project.Project
import net.javaru.iip.frc.settings.FrcApplicationSettings
import net.javaru.iip.frc.wpilib.isWpiLibProject

private val logger = logger<StartConsoleOnDeployListener>()

/**
 * Starts (and shows) the SystemCore Console when the robot code is successfully deployed, as the WPILib VS Code extension does. That
 * is, when a Gradle run of the `deploy` task completes successfully. This includes the plugin's "Build and Deploy" run configurations,
 * and running the task from the Gradle tool window. It can be turned off via the console's "Start on Deploy" toolbar toggle.
 *
 * Registered as a project listener in the plugin.xml file.
 */
class StartConsoleOnDeployListener(private val project: Project) : ExecutionListener
{
    override fun processTerminated(executorId: String, env: ExecutionEnvironment, handler: ProcessHandler, exitCode: Int)
    {
        if (exitCode != 0 || project.isDisposed || !FrcApplicationSettings.getInstance().startConsoleOnDeploy) return
        if (!isGradleDeploy(env) || !project.isWpiLibProject()) return
        logger.info("[FRC] The robot code was deployed. Starting the SystemCore Console.")
        RioLogProjectService.getInstance(project).startTcpWithoutFocus()
    }

    companion object
    {
        /** WPILib's (GradleRIO's) deploy task. */
        private const val DEPLOY_TASK = "deploy"

        /** Whether the run is a Gradle run of the deploy task (e.g. `deploy`, `:deploy`, or `clean deploy`). */
        fun isGradleDeploy(env: ExecutionEnvironment): Boolean
        {
            val settings = (env.runProfile as? ExternalSystemRunConfiguration)?.settings ?: return false
            // Compared by ID (rather than to GradleConstants.SYSTEM_ID) so this does not depend on the Gradle plugin's classes
            if (!settings.externalSystemId.id.equals("GRADLE", ignoreCase = true)) return false
            return isDeploy(settings.taskNames)
        }

        /** Whether the Gradle task names include the deploy task, of the root project (`deploy` or `:deploy`) or a subproject (`:robot:deploy`). */
        fun isDeploy(taskNames: List<String>): Boolean = taskNames.any { it.trim().substringAfterLast(':') == DEPLOY_TASK }
    }
}
