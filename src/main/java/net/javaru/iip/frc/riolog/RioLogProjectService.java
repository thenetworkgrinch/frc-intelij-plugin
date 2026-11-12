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

package net.javaru.iip.frc.riolog;

import org.jetbrains.annotations.NotNull;
import com.intellij.openapi.Disposable;
import com.intellij.openapi.application.Application;
import com.intellij.openapi.application.ApplicationManager;
import com.intellij.openapi.application.ModalityState;
import com.intellij.openapi.diagnostic.Logger;
import com.intellij.openapi.module.Module;
import com.intellij.openapi.project.Project;
import com.intellij.openapi.project.ProjectManager;

import net.javaru.iip.frc.riolog.ssh.SshRioLogMonitorProjectService;
import net.javaru.iip.frc.riolog.tcp.TcpRioLogMonitorProjectService;
import net.javaru.iip.frc.riolog.udp.UdpRioLogMonitorProjectService;
import net.javaru.iip.frc.settings.FrcProjectTeamNumberChangeListener;
import net.javaru.iip.frc.settings.FrcProjectTeamNumberService;



/**
 * Class that manages the displaying of the RioLog console window. It {@link #update() updates} the RioLog Console
 * view creating/opening, destroying/closing, or moving it as needed based on the state of the UI and on the current
 * configuration of the project and the presence of any FRC facets.
 * Access via the {@link #getInstance(Project)} method or as a Project Service via the IntelliJ
 * <a href="http://www.jetbrains.org/intellij/sdk/docs/basics/plugin_structure/plugin_services.html">Plugin Services</a>.
 * For example:
 * <pre>
 * final RioLogProjectService rioLogConsoleProjectService = project.getService(RioLogProjectService.class);
 * </pre>
 * There are also three static {@code update} methods that can be used when the caller has access to a facet, a module, or a project.
 */
public class RioLogProjectService implements FrcProjectTeamNumberChangeListener,
                                             Disposable
{
    private static final Logger LOG = Logger.getInstance(RioLogProjectService.class);

    @NotNull
    private final Project myProject;
    
    //private boolean hasToolWindowBeenRegistered = false;

    private final AbstractRioLogMonitorProjectService udpRioLogConsoleProjectService;
    private final AbstractRioLogMonitorProjectService sshRioLogConsoleProjectService;
    private final AbstractRioLogMonitorProjectService tcpRioLogConsoleProjectService;

    /*
        Use cases we want to be sure the RioLog Console status is updated, and where they are handled:
        
        1) Project Open
            Handled via: This classes implementation of FrcOpenRioLogStartupActivity.runActivity()
        2) Facet Added to Project
            Handled via: FrcProjectLifecycleService.facetAdded() (via its impl of FacetManagerListener)
        3) Facet Removed from Project
            a) was only facet and  we want to close the console
            b) there are other FRC facets still configured on the project
            Handled via: FrcProjectLifecycleService.facetRemoved() (via its impl of FacetManagerListener)
        4) New module created and facet was Added - likely dup of #2, but we want to test it
            Handled via: FrcOpenRioLogStartupActivity.moduleAdded()
        5) Module imported (with FRC facet)
            Handled via: FrcOpenRioLogStartupActivity.moduleAdded()
        6) Module Removed from project
            a) was only module with an FRC facet and  we want to close the console
            b) there are other modules with FRC facets still configured on the project
            Handled via: FrcOpenRioLogStartupActivity.disposeComponent()
        7) Change to the target window in the FrcSettings
            Previously handled via in FrcApplicationComponent's impl of UnnamedConfigurable.apply()
            Need to see if we still handle this properly
     */


    @SuppressWarnings("unused")
    public static void updateAllOpenProjects()
    {
        final Project[] openProjects = ProjectManager.getInstance().getOpenProjects();
        for (Project project : openProjects)
        {
            getInstance(project).update();
        }
    }

    public static RioLogProjectService getInstance(@NotNull Module module)
    {
        return getInstance(module.getProject());
    }
    
    public static RioLogProjectService getInstance(@NotNull Project project)
    {
        return project.getService(RioLogProjectService.class);
    }


    /**
     * Do not call the constructor directly. Use as a project service via {@code com.intellij.openapi.components.ServiceManager}:<br/>
     * <pre>
     * final RioLogProjectService rioLogConsoleProjectService = project.getService(RioLogProjectService.class);
     * </pre>
     *
     * @param myProject the project
     */
    private RioLogProjectService(@NotNull Project myProject)
    {
        LOG.debug("[FRC] RioLogProjectService constructor called.");
        this.myProject = myProject;
        myProject.getMessageBus().connect().subscribe(FrcProjectTeamNumberService.getPROJECT_TEAM_NUMBER_CHANGES(), this);
        this.udpRioLogConsoleProjectService = UdpRioLogMonitorProjectService.getInstance(myProject);
        this.sshRioLogConsoleProjectService = SshRioLogMonitorProjectService.getInstance(myProject);
        this.tcpRioLogConsoleProjectService = TcpRioLogMonitorProjectService.getInstance(myProject);
    }


    /**
     * Updates the RioLog Console view creating/opening, destroying/closing, or moving it as needed, or moving it
     * as needed based on the state of the UI and the current configuration of the project and the presence of any FRC facets.
     */
    public void update()
    {
        //For now, we are only going to update the primary console
        runOnEdt(tcpRioLogConsoleProjectService::update);
    }

    @SuppressWarnings("unused")
    public void updateAll()
    {
        runOnEdt(() -> {
            sshRioLogConsoleProjectService.update();
            udpRioLogConsoleProjectService.update();
            tcpRioLogConsoleProjectService.update();
        });
    }

    public void updateUdp()
    {
        runOnEdt(udpRioLogConsoleProjectService::update);
    }

    public void updateSsh()
    {
        runOnEdt(sshRioLogConsoleProjectService::update);
    }

    public void updateTcp() { runOnEdt(tcpRioLogConsoleProjectService::update); }

    /** Starts the SystemCore Console (if it is not already monitoring), and shows it without taking the focus. Used on a deploy. */
    public void startTcpWithoutFocus() { runOnEdt(tcpRioLogConsoleProjectService::startMonitoringWithoutFocus); }

    /**
     * Runs the (console) update on the EDT: immediately if already on the EDT, otherwise later. Updates create UI (and wait on
     * the EDT to do so), so they are confined to the EDT. Previously they were synchronized and called from both the EDT (e.g.
     * when the FRC facet is added) and background threads (e.g. the startup activity), which could deadlock: the background thread
     * holding the lock while waiting on the EDT, and the EDT waiting for the lock.
     */
    private void runOnEdt(@NotNull Runnable update)
    {
        final Application application = ApplicationManager.getApplication();
        if (application.isDispatchThread())
        {
            update.run();
        }
        else
        {
            application.invokeLater(() -> {
                if (!myProject.isDisposed()) update.run();
            }, ModalityState.nonModal());
        }
    }
    
    
    @Override
    public void onTeamNumberChange(@NotNull Project project, int previousTeamNumber, int newTeamNumber)
    {
        if (project.equals(myProject))
        {
            LOG.debug("[FRC] RioLog Service Responding to a change in the Team Number from '" + previousTeamNumber + "' to '" + newTeamNumber + "'.");
            update(); 
        }
    }
    
    
    public void activateUdp()
    {
        udpRioLogConsoleProjectService.activate();
    }

    public void activateTcp()
    {
        tcpRioLogConsoleProjectService.activate();
    }

    public void activateSsh()
    {
        sshRioLogConsoleProjectService.activate();
    }

    public void stopUdp()
    {
        udpRioLogConsoleProjectService.stop();
    }
    
    public void stopTcp()
    {
        tcpRioLogConsoleProjectService.stop();
    }
    
    public void stopSsh()
    {
        sshRioLogConsoleProjectService.stop();
    }
    
    public void stopAll()
    {
        stopSsh();
        stopUdp();
        stopTcp();
    }
    
    
    @Override
    public void dispose()
    {
        try
        {
            stopAll();
        }
        catch (Exception e)
        {
            LOG.info("[FRC] An exception occurred when disposing of " + getClass().getSimpleName() + ": " + e.toString());
        }
    }
}
