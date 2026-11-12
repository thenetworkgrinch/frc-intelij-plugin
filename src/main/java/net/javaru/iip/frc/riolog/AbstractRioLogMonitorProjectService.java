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

package net.javaru.iip.frc.riolog;


import org.jetbrains.annotations.NotNull;
import org.jetbrains.annotations.Nullable;
import com.intellij.openapi.diagnostic.Logger;
import com.intellij.openapi.project.Project;
import com.intellij.openapi.util.Disposer;
import com.intellij.openapi.wm.ToolWindow;
import com.intellij.openapi.wm.ToolWindowManager;

import net.javaru.iip.frc.settings.FrcApplicationSettings;
import net.javaru.iip.frc.wpilib.WpiLibProjectDetectionKt;



/**
 * Service that manages RioLog monitoring. 
 */
public abstract class AbstractRioLogMonitorProjectService
{

    // TODO: This class needs a some refactoring/rework. 
    //       It's kind of grown into a mess as it was written when first starting 
    //       out with less understanding of the IntelliJ IDEA plugin API.
    //       Also, its not acting as a ProjectService but more an ApplicationService
    //       We need to fix that and have better cross project support in the event 
    //       multiple FRC projects are open
    
    private static final Logger LOG = Logger.getInstance(AbstractRioLogMonitorProjectService.class);
    @NotNull
    protected final Project myProject;
    @Nullable
    private AbstractRioLogContentExecutor contentExecutor;

    protected AbstractRioLogMonitorProjectService(@NotNull Project myProject) {this.myProject = myProject;}


    public synchronized void update()
    {
        // The console is always shown for a WPILib project. This includes projects detected by their file layout (a Gradle build file,
        // '.wpilib' directory and 'vendordeps' directory) so it is shown as soon as the project is opened, before the Gradle import adds the FRC facet
        final boolean needConsole = WpiLibProjectDetectionKt.isWpiLibProject(myProject);

        final FrcApplicationSettings frcSettings = FrcApplicationSettings.getInstance();
        
        final int configuredPort = frcSettings.getRioLogUdpPort();
        final int currentPort = determineCurrentlyMonitoredPort();
        final boolean portBounceNeeded = currentPort != -1 && currentPort != configuredPort;
        final boolean haveConsole = contentExecutor != null && isFrcToolWindowAvailable();


        final Thread currentThread = Thread.currentThread();
        LOG.debug("[FRC]     Current thread:   " + currentThread.getId() + " :: " + currentThread.getName());
        LOG.debug("[FRC]     needConsole:      " + needConsole);
        LOG.debug("[FRC]     haveConsole:      " + haveConsole);
        LOG.debug("[FRC]     configuredPort:   " + configuredPort);
        LOG.debug("[FRC]     currentPort:      " + currentPort);
        LOG.debug("[FRC]     portBounceNeeded: " + portBounceNeeded);


        if (needConsole && haveConsole && contentExecutor.getRioLogMonitorProcess() != null && contentExecutor.getRioLogMonitorProcess().isEnabled())
        {
            // Case 1 - we have and need it, but we need to check if it is listening on the right port (i.e. settings change)
            LOG.debug("[FRC] Case 1: have console and need it. Checking if correct port. Project is: " + myProject.getName());

            if (portBounceNeeded)
            {
                LOG.debug("[FRC] Case 1.3A: have console, need it, and it is the right type, but port has changed. Triggering 'reRun' action. Project is: "
                          + myProject.getName());
                if (contentExecutor != null) {contentExecutor.reRun();}
            }
            else
            {
                // Not activated, as update() is called for many project changes, and should not repeatedly take the focus (or reopen
                // the tool window after the user has closed it). The console is activated on demand via activate().
                LOG.debug("[FRC] Case 1.3B: have console, need it, and it is the right type, listening on the correct port. No action needed. Project is: "
                          + myProject.getName());
            }
        }
        else if (needConsole && haveConsole && contentExecutor.getRioLogMonitorProcess() != null && !contentExecutor.getRioLogMonitorProcess().isEnabled())
        {
            // Case 2 - We need it, have, but it is not running. It is started on demand, via its Start button.
            LOG.debug("[FRC] Case 2: need a console, have it, but it is not running. No action needed. Project is: " + myProject.getName());
        }
        else if (needConsole)
        {
            // Case 3 - we need it, but don't have it
            LOG.debug("[FRC] Case 3: need a console, but we don't have one. Creating one. Project is: " + myProject.getName());
            initContentExecutor(true);
        }
        else if (haveConsole)
        {
            // Case 4 we have it, but don't need it
            LOG.debug("[FRC] Case 4: We have a console, but don't need it. Closing it. Project is: " + myProject.getName());
            closeContentExecutor();
        }
        else
        {
            //Case 5, we don't have it and don't need it... so do nothing
            LOG.debug("[FRC] Case 5: We don't have a console window an we don't need one. No action needed. Project is: " + myProject.getName());
        }
    }


    protected boolean isFrcToolWindowAvailable()
    {
        if (contentExecutor != null && !myProject.isDisposed())
        {
            final ToolWindowManager toolWindowManager = ToolWindowManager.getInstance(myProject);
            if (toolWindowManager != null)
            {
                final ToolWindow toolWindow = toolWindowManager.getToolWindow(contentExecutor.getToolWindowId());
                if (toolWindow != null)
                {
                    return toolWindow.isAvailable();
                }
            }
        }
        
        return false;
    }


    private int determineCurrentlyMonitoredPort()
    {
        if (contentExecutor != null)
        {
            final AbstractRioLogMonitorProcess rioLogMonitorProcess = contentExecutor.getRioLogMonitorProcess();
            if (rioLogMonitorProcess != null)
            {
                return rioLogMonitorProcess.getMonitoredPort();
            }
        }
        return -1;
    }


    public void activate()
    {
        if (contentExecutor != null)
        {
            LOG.debug("[FRC] activate called for " + contentExecutor.toString());
            contentExecutor.activateRioLogConsole();
        }
        else
        {
            LOG.debug("[FRC] activate called, but contentExecutor is null. No action taken.");
        }
    }

    /**
     * Starts monitoring, and shows the console without taking the focus, as is done when the robot code is deployed. If the console
     * is already monitoring (e.g. it is connected, or waiting for the robot to restart), it is just shown. Must be called on the EDT.
     */
    public synchronized void startMonitoringWithoutFocus()
    {
        if (myProject.isDisposed() || !WpiLibProjectDetectionKt.isWpiLibProject(myProject)) return;

        if (contentExecutor == null || !isFrcToolWindowAvailable())
        {
            closeContentExecutor();
            initContentExecutor(false, false);
        }
        else if (contentExecutor.isMonitoring())
        {
            contentExecutor.showRioLogConsole();
        }
        else
        {
            contentExecutor.reRun(false);
        }
    }

    public void stop()
    {
        if (contentExecutor != null)
        {
            contentExecutor.invokeStop();
        }
    }

    public void closeContentExecutor()
    {
        if (contentExecutor != null)
        {
            try
            {
                contentExecutor.close();
            }
            catch (Exception e)
            {
                LOG.debug("[FRC] An exception occurred when closing the contentExecutor. Cause Summary: " + e.toString(), e);
            }
            contentExecutor = null;
        }
    }


    private void initContentExecutor(final boolean isFreshActivation)
    {
        // A fresh activation (e.g. when the project is opened) shows the console without taking the focus
        initContentExecutor(isFreshActivation, !isFreshActivation);
    }


    private void initContentExecutor(final boolean isFreshActivation, final boolean requestFocus)
    {
        LOG.debug("[FRC] Creating AbstractRioLogContentExecutor: isFreshActivation=" + isFreshActivation + " requestFocus=" + requestFocus);
        try
        {
            contentExecutor = createRioLogContentExecutor();
            Disposer.register(myProject, contentExecutor);
            contentExecutor.run(isFreshActivation, requestFocus);
        }
        catch (Exception e)
        {
            LOG.warn("[FRC] An exception occurred when creating the content executor. Cause Summary: " + e.toString(), e);
            try
            {
                closeContentExecutor();
            }
            catch (Exception ignore) {}
        }
    }


    @NotNull
    protected abstract AbstractRioLogContentExecutor createRioLogContentExecutor();

}
