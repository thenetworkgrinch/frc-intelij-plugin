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

package net.javaru.iip.frc.run

import com.intellij.execution.ExecutionListener
import com.intellij.execution.Executor
import com.intellij.execution.executors.ExecutorGroup
import com.intellij.execution.process.ProcessHandler
import com.intellij.execution.runners.ExecutionEnvironment
import com.intellij.openapi.application.ApplicationManager
import com.intellij.openapi.application.ModalityState
import com.intellij.openapi.diagnostic.logger
import com.intellij.openapi.externalSystem.service.execution.ExternalSystemRunConfiguration
import com.intellij.openapi.project.Project
import com.intellij.openapi.wm.ToolWindowManager
import net.javaru.iip.frc.wpilib.isWpiLibProject

private val logger = logger<OpenProfilerAfterSimulationListener>()

/**
 * Opens the Profiler tool window when a profiled simulation ends, so the results are shown. When a Gradle run configuration is
 * profiled, the profiler profiles the process started by its Java task (e.g. GradleRIO's `run` task), and reads its data when the
 * process ends, but does not bring the Profiler tool window to the front.
 *
 * Registered as a project listener in the plugin.xml file.
 */
class OpenProfilerAfterSimulationListener(private val project: Project) : ExecutionListener
{
    override fun processTerminated(executorId: String, env: ExecutionEnvironment, handler: ProcessHandler, exitCode: Int)
    {
        // Any exit code, as the simulation is normally ended by stopping it
        if (project.isDisposed || !isProfilerExecutor(env.executor) || !isGradleSimulation(env) || !project.isWpiLibProject()) return
        ApplicationManager.getApplication().invokeLater({
            val toolWindow = ToolWindowManager.getInstance(project).getToolWindow(PROFILER_TOOL_WINDOW_ID)
            if (toolWindow == null)
            {
                logger.info("[FRC] The '$PROFILER_TOOL_WINDOW_ID' tool window was not found, so it was not opened after the profiled simulation ended.")
                return@invokeLater
            }
            logger.info("[FRC] The profiled simulation ended. Opening the '$PROFILER_TOOL_WINDOW_ID' tool window.")
            toolWindow.activate(null)
        }, ModalityState.nonModal(), project.disposed)
    }

    companion object
    {
        /** The ID of the IntelliJ Profiler's tool window (ProfilerToolWindowManager.TOOLWINDOW_ID). */
        const val PROFILER_TOOL_WINDOW_ID = "Profiler"

        /** The ID of the IntelliJ Profiler's executor group (DefaultProfilerExecutorGroup.EXECUTOR_ID). */
        private const val PROFILER_EXECUTOR_GROUP_ID = "Profiler"

        /**
         * The GradleRIO tasks that run the simulation: `run` (2027+), and `simulateJava` or `simulateJavaDebug` (2026 and earlier), as
         * in WpiLibSimulation.kt. Literals, so this listener (which is called for every run, including in CLion, which does not have
         * the Java plugin) does not load the simulation classes, which use the Java plugin's.
         */
        private val simulationTasks = setOf("run", "simulateJava", "simulateJavaDebug")

        /** Whether the executor is the profiler's, i.e. one of the profilers (e.g. IntelliJ Profiler or Java Flight Recorder) of its executor group. */
        fun isProfilerExecutor(executor: Executor): Boolean =
            executor.id == PROFILER_EXECUTOR_GROUP_ID || ExecutorGroup.getGroupIfProxy(executor)?.id == PROFILER_EXECUTOR_GROUP_ID

        private fun isGradleSimulation(env: ExecutionEnvironment): Boolean
        {
            val settings = (env.runProfile as? ExternalSystemRunConfiguration)?.settings ?: return false
            // Compared by ID (rather than to GradleConstants.SYSTEM_ID) so this does not depend on the Gradle plugin's classes
            return settings.externalSystemId.id.equals("GRADLE", ignoreCase = true) && isSimulation(settings.taskNames)
        }

        /** Whether the Gradle task names include a simulation task, of the root project (e.g. `run` or `:run`) or a subproject. */
        fun isSimulation(taskNames: List<String>): Boolean = taskNames.any { it.trim().substringAfterLast(':') in simulationTasks }
    }
}
