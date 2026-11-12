/*
 * Copyright 2015-2021 the original author or authors.
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

package net.javaru.iip.frc.riolog.ui;

import javax.swing.*;

import org.jetbrains.annotations.NotNull;
import com.intellij.execution.Executor;
import com.intellij.execution.ExecutorRegistry;
import com.intellij.icons.AllIcons;
import com.intellij.openapi.diagnostic.Logger;
import com.intellij.openapi.util.IconLoader;

import icons.FrcIcons.FRC;



// This class is registered in the plugin.xml file in the extensions element
// Access is obtained via:  ExecutionManager.getInstance(myProject);
// For example, as used in AbstractRioLogContentExecutor:  
//           ExecutionManager.getInstance(myProject).getContentManager().showRunContent(myExecutor, myRunContentDescriptor);
// Also see com.intellij.execution.executors.DefaultRunExecutor for examples
public class FrcRioLogToolWindowExecutor extends Executor
{
    private static final Logger LOG = Logger.getInstance(FrcRioLogToolWindowExecutor.class);

    public static final String FRC_RIO_LOG_TOOL_WINDOW_ID = "SystemCore Console"; // Also the tool window's name (see getActionName())
    // The executor ID must match the id attribute of the <extensions>/<executor> element in the plugin.xml file
    public static final String EXECUTOR_ID = FrcRioLogToolWindowExecutor.class.getSimpleName();
    public static final Icon FRC_TOOL_WINDOW_ICON = FRC.FIRST_ICON_SMALL_13_ELEVATED;
    
    
    @Override
    @NotNull
    public String getToolWindowId() { return FRC_RIO_LOG_TOOL_WINDOW_ID; }


    @Override
    @NotNull
    public Icon getToolWindowIcon() { return FRC_TOOL_WINDOW_ICON; }


    @NotNull
    @Override
    public Icon getIcon() { return AllIcons.Actions.Execute; }


    @Override
    public Icon getDisabledIcon() { return IconLoader.getDisabledIcon(getIcon()); /* As done in  com.intellij.execution.executors.DefaultRunExecutor */ }


    @Override
    public String getDescription() { return "SystemCore Console tool window"; }


    @NotNull
    @Override // NOTE: as of 2020.3, this value gets used as the tool window name. See Issue #87
    public String getActionName() { return FRC_RIO_LOG_TOOL_WINDOW_ID; }


    @NotNull
    @Override
    public String getId() { return EXECUTOR_ID; }


    @NotNull
    @Override
    public String getStartActionText() { return "SystemCore Console"; }


    @Override
    public String getContextActionId() { return "FrcRioLogToolWindowContextActionId"; }


    @Override
    public String getHelpId()
    {
        return null;
    }


    public static Executor getRunExecutorInstance()
    {
        return ExecutorRegistry.getInstance().getExecutorById(EXECUTOR_ID);
    }

}
