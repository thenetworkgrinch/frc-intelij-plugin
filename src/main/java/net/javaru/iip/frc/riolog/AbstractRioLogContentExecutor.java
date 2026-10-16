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

import java.awt.*;
import java.nio.charset.StandardCharsets;
import javax.swing.*;

import org.jetbrains.annotations.NotNull;
import org.jetbrains.annotations.Nullable;
import com.intellij.compiler.server.BuildManager;
import com.intellij.execution.ExecutionBundle;
import com.intellij.execution.Executor;
import com.intellij.execution.executors.DefaultRunExecutor;
import com.intellij.execution.filters.TextConsoleBuilder;
import com.intellij.execution.filters.TextConsoleBuilderFactory;
import com.intellij.execution.process.BaseOSProcessHandler;
import com.intellij.execution.process.ProcessAdapter;
import com.intellij.execution.process.ProcessEvent;
import com.intellij.execution.process.ProcessHandler;
import com.intellij.execution.ui.ConsoleView;
import com.intellij.execution.ui.RunContentDescriptor;
import com.intellij.execution.ui.RunContentManager;
import com.intellij.icons.AllIcons;
import com.intellij.ide.CommonActionsManager;
import com.intellij.ide.OccurenceNavigator;
import com.intellij.openapi.Disposable;
import com.intellij.openapi.actionSystem.ActionGroup;
import com.intellij.openapi.actionSystem.ActionManager;
import com.intellij.openapi.actionSystem.ActionPlaces;
import com.intellij.openapi.actionSystem.ActionToolbar;
import com.intellij.openapi.actionSystem.ActionUpdateThread;
import com.intellij.openapi.actionSystem.AnAction;
import com.intellij.openapi.actionSystem.AnActionEvent;
import com.intellij.openapi.actionSystem.CommonDataKeys;
import com.intellij.openapi.actionSystem.CommonShortcuts;
import com.intellij.openapi.actionSystem.DataContext;
import com.intellij.openapi.actionSystem.DefaultActionGroup;
import com.intellij.openapi.actionSystem.LangDataKeys;
import com.intellij.openapi.actionSystem.Presentation;
import com.intellij.openapi.actionSystem.Separator;
import com.intellij.openapi.actionSystem.ToggleAction;
import com.intellij.openapi.actionSystem.ex.ActionUtil;
import com.intellij.openapi.application.ApplicationManager;
import com.intellij.openapi.application.ReadAction;
import com.intellij.openapi.application.WriteAction;
import com.intellij.openapi.diagnostic.Logger;
import com.intellij.openapi.editor.Editor;
import com.intellij.openapi.editor.actions.ScrollToTheEndToolbarAction;
import com.intellij.openapi.editor.actions.ToggleUseSoftWrapsToolbarAction;
import com.intellij.openapi.fileEditor.FileDocumentManager;
import com.intellij.openapi.project.DumbAware;
import com.intellij.openapi.project.DumbAwareAction;
import com.intellij.openapi.project.Project;
import com.intellij.openapi.util.Computable;
import com.intellij.openapi.util.Disposer;
import com.intellij.openapi.wm.ToolWindow;
import com.intellij.openapi.wm.ToolWindowManager;
import com.intellij.ui.content.Content;
import com.intellij.ui.content.ContentManager;

import icons.FrcIcons;
import net.javaru.iip.frc.i18n.FrcBundle;
import net.javaru.iip.frc.riolog.ui.FrcRioLogToolWindowExecutor;
import net.javaru.iip.frc.services.FrcGradleService;
import net.javaru.iip.frc.settings.FrcApplicationSettings;
import net.javaru.iip.frc.util.FrcPluginUtilsKt;



//Based on the IntelliJ IDEA com.intellij.execution.RunContentExecutor class
public abstract class AbstractRioLogContentExecutor implements Disposable
{
    private static final Logger LOG = Logger.getInstance(AbstractRioLogContentExecutor.class);
    private static final Icon AUTO_CLEAR_ICON = AllIcons.Ide.OutgoingChangesOn;
    private static final Icon START_ICON = AllIcons.Actions.Execute;
    private static final Icon RESTART_ICON = AllIcons.Actions.Restart;
    protected final String toStringValue;
    protected final Project myProject;

    private JComponent consolePanel;

    protected ProcessHandler myProcessHandler;
    private ConsoleView myConsoleView;
    @Nullable
    private final Runnable myAfterCompletionRunnable;
    private Computable<Boolean> myStopEnabled;

    //private final String myHelpId = null;
    private final boolean myActivateToolWindow;
    private Executor myExecutor;
    private RunContentDescriptor myRunContentDescriptor;
    private AbstractRioLogMonitorProcess rioLogMonitorProcess;
    private ActionToolbar actionToolbar;
    private RioLogStopAction rioLogStopAction;

    
    /*
        The com.intellij.execution.ExecutionHelper may be useful
    */


    protected AbstractRioLogContentExecutor(@NotNull Project project, boolean activateToolWindow, @Nullable Runnable afterCompletionRunnable)
    {
        myProject = project;
        myActivateToolWindow = activateToolWindow;
        this.myAfterCompletionRunnable = afterCompletionRunnable;
        toStringValue = getClass().getSimpleName() + " Tool Windows ID: " + getToolWindowId() + "  Tab Title: " + getTabTitle();
    }


    private ConsoleView createConsole(@NotNull Project project, @NotNull ProcessHandler processHandler)
    {
        TextConsoleBuilder consoleBuilder = TextConsoleBuilderFactory.getInstance().createBuilder(project);
        ConsoleView console = consoleBuilder.getConsole();
        console.attachToProcess(processHandler);


        return console;
    }


    private JComponent createConsolePanel(ConsoleView view, ActionGroup actions)
    {
        JPanel panel = new JPanel(); 
        panel.setLayout(new BorderLayout());
        ApplicationManager.getApplication().invokeAndWait(() -> {
            WriteAction.run(() -> {
                panel.add(view.getComponent(), BorderLayout.CENTER);
                actionToolbar = createToolbar(actions);
                actionToolbar.setTargetComponent(panel);
                panel.add(actionToolbar.getComponent(), BorderLayout.WEST);
            });
        } );
        return panel;
    }


    private static ActionToolbar createToolbar(ActionGroup actions)
    {
        return ActionManager.getInstance().createActionToolbar(FrcRioLogToolWindowExecutor.FRC_RIO_LOG_TOOL_WINDOW_ID, actions, false);
    }


    @Nullable
    public AbstractRioLogMonitorProcess getRioLogMonitorProcess() { return rioLogMonitorProcess; }


    public void reRun()
    {
        ApplicationManager.getApplication().invokeLater(() ->
                                                        {
                                                            if (myProcessHandler != null) {
                                                                myProcessHandler.destroyProcess();  
                                                            }
                                                            invokeClearAll();
                                                            if (myProcessHandler != null) {
                                                                myProcessHandler.waitFor(2000L);
                                                            }
                                                            run(false);
                                                            // Commenting out for now as it is causing issues
                                                            //ensureContentIsPinned();
                                                        });
    }


    public void run(boolean isFreshActivation)
    {
        // Implementation based on com.intellij.execution.RunContentExecutor
        // When reworking, look at com.intellij.build.BuildContentManagerImpl which is a more up to date ContentExecutor implementation  
        
        ApplicationManager.getApplication().invokeLater(() -> {
            WriteAction.run(() -> FileDocumentManager.getInstance().saveAllDocuments());
        } );
        

        rioLogMonitorProcess = isFreshActivation ? createAnnouncementRioLogMonitoringProcess() : createRioLogMonitoringProcess();

        //   Regarding the commandLine parameter; the example from an IDEA bundled plugin I originally used used a null value
        //   for it as it was nullable. But a change was made in Nov 2015 that BaseOSProcessHandler now logs an exception if 
        //   commandLine is null or empty. We are not actually running a command, just using the handler to monitor a network
        //   connection. What ever we put, gets output on the screen, so for we are just putting a basic message which works ok. 
        myProcessHandler = new BaseOSProcessHandler(rioLogMonitorProcess, getTabTitle(), StandardCharsets.UTF_8)
        {
            @Override
            public boolean isSilentlyDestroyOnClose()
            {
                return true;
            }
        };

        // BuildManager is part of the Java plugin, which is not available in CLion
        if (FrcPluginUtilsKt.isJavaPluginAvailable())
        {
            myProcessHandler.putUserDataIfAbsent(BuildManager.ALLOW_AUTOMAKE, true);
        }

        myConsoleView = createConsole(myProject, myProcessHandler);
        // There is the possibility that myProcessHandler is null when the lambda gets called
        myStopEnabled = () -> myProcessHandler != null && !myProcessHandler.isProcessTerminated();

//        if (myHelpId != null)
//        {
//            myConsoleView.setHelpId(myHelpId);
//        }

        //Executor executor = DefaultRunExecutor.getRunExecutorInstance(); //Gets the Run Window I believe
        myExecutor = createExecutor();

        // TODO: let's improve this by using a lock or synchronization instead of this ugly hack
        // This is a bit of overkill... and a messy hack... but there is a bug that sometimes multiple content tabs are added to the run window. 
        //    The bug should not happen in real world use as it seems to occur after repeatedly removing and re-adding the facet during testing.
        //    As near as I can tell, this is what happens...
        //    For some reason, sometimes the FrcFacetManagerListener.facetAdded() gets called twice (I *think* on separate threads, but have not 100% confirmed yet)
        //    This results in the RioLogProjectService.update method getting called twice, the second time before the first one has completed
        //    This results in this run method getting called twice. So two different RunContentDescriptor instances get created.
        //    The RunContentManager.removeRunContent(myExecutor, myRunContentDescriptor) method appears to use instance equality
        //    specifically, the runDescriptor does not match in com.intellij.execution.ui.RunContentManagerImpl#getRunContentByDescriptor does not find a match
        //    so the content is not properly removed.
        //    This following removeAllContent iterates over all RunDescriptors and removes any with the myTitle value.
        removeAllContent(myExecutor, myProject);
        removeAllContent(DefaultRunExecutor.getRunExecutorInstance(), myProject);


        DefaultActionGroup actions = new DefaultActionGroup();

        consolePanel = createConsolePanel(myConsoleView, actions);
        myRunContentDescriptor = new RunContentDescriptor(myConsoleView, myProcessHandler, consolePanel, getTabTitle(), FrcIcons.RioLog.RIOLOG);

        Disposer.register(myProject.getService(RioLogProjectService.class), this);
        Disposer.register(this, myRunContentDescriptor);
        addActionsToActionGroup(actions);
    
    
        // Capture the instances created by this invocation. If run() is called again before this lambda executes,
        // the fields will point at the newer instances; reading the fields here would cause startNotify() to be
        // called twice on the same handler ("startNotify called already") and leave this invocation's handler orphaned.
        final ProcessHandler processHandler = myProcessHandler;
        final AbstractRioLogMonitorProcess monitorProcess = rioLogMonitorProcess;
        final RunContentDescriptor runContentDescriptor = myRunContentDescriptor;
        final Executor executor = myExecutor;

        ApplicationManager.getApplication().invokeLater(() -> {
            if (processHandler != myProcessHandler)
            {
                // Superseded by a later run() call; that call will show its own content and start its own process
                LOG.debug("[FRC] RioLog run superseded before it was started; discarding stale process handler");
                processHandler.destroyProcess();
                return;
            }

            WriteAction.run(() -> {
                RunContentManager.getInstance(myProject).showRunContent(executor, runContentDescriptor);
                
                if (myActivateToolWindow)
                {
                    activateRioLogConsole();
                }
                
                if (myAfterCompletionRunnable != null)
                {
                    processHandler.addProcessListener(new ProcessAdapter()
                    {
                        @Override
                        public void processTerminated(@NotNull ProcessEvent event)
                        {
                            ApplicationManager.getApplication().invokeLater(myAfterCompletionRunnable);
                        }
                    });
                }
                
                monitorProcess.start();
                processHandler.startNotify();
            });
            
        });
        
    }


    @NotNull
    protected abstract AbstractRioLogMonitorProcess createRioLogMonitoringProcess();

    @NotNull
    protected abstract AbstractRioLogMonitorProcess createAnnouncementRioLogMonitoringProcess();


    private void addActionsToActionGroup(DefaultActionGroup actions)
    {
        // We need to grab some actions that are created in the ConsoleView itself.
        // This is a bit hackish but works. 

        AnAction softWrapAction = null;
        AnAction scrollToEndAction = null;
        AnAction grepConsoleAction = null;
//        AnAction printAction = null;
        
        for (AnAction action : myConsoleView.createConsoleActions())
        {
            final Class<? extends AnAction> actionClass = action.getClass();

            if (LOG.isDebugEnabled())
            {
                LOG.debug(String.format("[FRC] Available console action: Text='%s'; Desc='%s'; class='%s'; enclosingClass='%s'; declaringClass='%s'",
                                        action.getTemplatePresentation().getText(),
                                        action.getTemplatePresentation().getDescription(),
                                        actionClass,
                                        actionClass.getEnclosingClass(),
                                        actionClass.getDeclaringClass()));
            }
    
            //We use the string equals (rather than instanceof) for this action to prevent an import error if the Grep Console Plugin is not available
            if (actionClass.getName().equals("krasa.grepconsole.action.OpenConsoleSettingsAction"))
            {
                grepConsoleAction = action;
            }
            else if (action instanceof ToggleUseSoftWrapsToolbarAction)
            {
                softWrapAction = action;
            }
            else if (action instanceof ScrollToTheEndToolbarAction)
            {
                scrollToEndAction = action;
            }
//            else if (action instanceof PrintAction)
//            {
//                printAction = action;
//            }
        }

        // See com.intellij.execution.impl.ConsoleViewImpl.createConsoleActions for example 
        actions.add(new RioLogRerunAction(consolePanel));
        rioLogStopAction = new RioLogStopAction();
        actions.add(rioLogStopAction);
        actions.add(new RioLogPauseOutputAction(myConsoleView, myProcessHandler));
        actions.add(new Separator());

        if (softWrapAction != null)
        {
            actions.add(softWrapAction);
        }
        if (scrollToEndAction != null)
        {
            actions.add(scrollToEndAction);
        }
//        if (printAction != null)
//        {
//            actions.add(printAction);
//        }

        actions.add(new RioLogClearAllAction());
        actions.add(new RioLogToggleAutoClearAction());
    
        actions.add(new Separator());
        if (myConsoleView instanceof OccurenceNavigator)
        {
            final CommonActionsManager commonActionsManager = CommonActionsManager.getInstance();
            OccurenceNavigator occurenceNavigator = (OccurenceNavigator) myConsoleView;
            final AnAction prevAction = commonActionsManager.createPrevOccurenceAction(occurenceNavigator);
            prevAction.getTemplatePresentation().setText(occurenceNavigator.getPreviousOccurenceActionName());
            actions.add(prevAction);
            final AnAction nextAction = commonActionsManager.createNextOccurenceAction(occurenceNavigator);
            nextAction.getTemplatePresentation().setText(occurenceNavigator.getNextOccurenceActionName());
            actions.add(nextAction);
        }
    
        if (grepConsoleAction != null)
        {
            actions.add(new Separator());
            actions.add(grepConsoleAction);
        }
    
    
        // We no longer provide a close button. As long as a FRC Facet is present, we want a RioLog console. 
        // The 'work' of the close action was moved to myCloseRunnable and closing is managed by the RioLogProjectService
        // Leaving this line of code here commented out in case in the future we need to remember how we did include a close button.
        //actions.add(new com.intellij.execution.ui.actions.CloseAction(myExecutor, descriptor, myProject));
    }


    protected abstract Executor createExecutor();


    public void activateRioLogConsole()
    {
        if (myProject.isInitialized() && myProject.isOpen())
        {
            ApplicationManager.getApplication().invokeLater(new ActivateRioLogConsoleRunnable());
        }
        else 
        {
            ApplicationManager.getApplication().invokeLater(new ActivateRioLogConsoleRunnable(), o -> myProject.isInitialized() && myProject.isOpen());
        }
    }


    public void ensureContentIsPinned()
    {
        if (myProject != null && !myProject.isDisposed())
        {
            final ToolWindow toolWindow = ToolWindowManager.getInstance(myProject)
                                                           .getToolWindow(getToolWindowId());
            if (toolWindow != null)
            {
                final ContentManager contentManager = toolWindow.getContentManager();
                ensureContentIsPinned(contentManager);
            }
        }
    }


    public void ensureContentIsPinned(@NotNull ContentManager contentManager)
    {
        final Content content = contentManager.findContent(getTabTitle());
        ensureContentIsPinned(content);
    }


    public static void ensureContentIsPinned(@Nullable Content content)
    {
        if (content != null)
        {
            content.setPinnable(true);
            content.setPinned(true);
        }
    }


    private class ActivateRioLogConsoleRunnable implements Runnable
    {
        @Override
        public void run()
        {
            LOG.debug("[FRC] ActivateRioLogConsoleRunnable is executing for " + toString());
            if (!myProject.isDisposed())
            {
                final ToolWindow toolWindow = ToolWindowManager.getInstance(myProject)
                                                               .getToolWindow(getToolWindowId());
                if (toolWindow == null)
                {
                    LOG.warn("[FRC] Could get instance of FRC Tool Window");
                    return;
                }
                toolWindow.activate(null);
                final ContentManager contentManager = toolWindow.getContentManager();
                final Content content = contentManager.findContent(getTabTitle());
                if (content != null)
                {
                    LOG.debug("[FRC] requesting focus for " + content.getDescription());
                    contentManager.setSelectedContent(content, true);
                    ensureContentIsPinned(content);
                }
                else
                {
                    LOG.debug("[FRC] content was null and cannot be activated/given-focus for " + toString());
                }
            }
            else 
            {
                LOG.debug("[FRC] Project '" + myProject + "' is disposed. Will NOT activate RioLog Console.");
            }
        }
    }


    public void invokeClearAll()
    {
        myConsoleView.clear();
    }


    /**
     * Programmatically invokes (i.e. clicks) the Stop Action Button.
     */
    public void invokeStop()
    {
        if (actionToolbar != null && rioLogStopAction != null)
        {
            ApplicationManager.getApplication().invokeLater(() -> {
                final DataContext dataContext = actionToolbar.getToolbarDataContext();
                ActionUtil.invokeAction(rioLogStopAction, dataContext, ActionPlaces.UNKNOWN, null, null);
            });
        }
        else
        {
            LOG.debug("[FRC] Could not programmatically invoke the RioLog stop action as either the actionToolbar or the rioLogStopAction is null.");
        }
    }

    public abstract String getToolWindowId();

    public abstract String getTabTitle();


    @Override
    public String toString()
    {
        return toStringValue;
    }


    public void close()
    {
        LOG.debug("[FRC] Executing " + getClass().getSimpleName() + ".close()");

        try
        {
            if (myProcessHandler != null)
            {
                myProcessHandler.detachProcess();
            }
        }
        catch (Exception e)
        {
            LOG.debug("[FRC] An exception occurred when detaching processHandler. Cause Summary: " + e);
        }
        
        try
        {
            if (myProcessHandler != null)
            {
                myProcessHandler.destroyProcess();
            }
        }
        catch (Exception e)
        {
            LOG.debug("[FRC] An exception occurred when destroying processHandler. Cause Summary: " + e);
        }


        if (myRunContentDescriptor != null)
        {
            final boolean removedOk = RunContentManager.getInstance(myProject).removeRunContent(myExecutor, myRunContentDescriptor);

            // This is a bit of overkill... but there is a bug that sometimes multiple content tabs are added to the run window. 
            //    The bug should not happen in real world use as it seems to occur after repeatedly removing and re-adding the facet during testing.
            //    As near as I can tell, this is what happens...
            //    For some reason, sometimes the FrcFacetManagerListener.facetAdded() gets called twice (I *think* on separate threads, but have not 100% confirmed yet)
            //    This results in the RioLogProjectService.update method getting called twice, the second time before the first one has completed
            //    This results in this class' run method getting called twice. So two different RunContentDescriptor instances get created.
            //    The RunContentManager.removeRunContent(myExecutor, myRunContentDescriptor) method appears to use instance equality
            //    specifically, the runDescriptor does not match in com.intellij.execution.ui.RunContentManagerImpl#getRunContentByDescriptor does not find a match
            //    so the content is not properly removed.
            //    This following removeAllContent iterates over all RunDescriptors and removes any with the myTitle value.
            removeAllContent(myExecutor, myProject);


            if (removedOk)
            {
                LOG.debug("[FRC] RioLogContentExecutor was removed OK");
                myRunContentDescriptor.dispose();
                myRunContentDescriptor = null;
                myExecutor = null;
                myProcessHandler = null;
            }
            else
            {
                LOG.warn("[FRC] RioLogContentExecutor was NOT removed");

            }
        }
    }


    private void removeAllContent(Executor executor, @SuppressWarnings("unused") Project project)
    {
        if (executor != null)
        {
            try
            {
                final RunContentManager contentManager = RunContentManager.getInstance(myProject);
                final java.util.List<RunContentDescriptor> allDescriptors = contentManager.getAllDescriptors();
                for (RunContentDescriptor runContentDescriptor : allDescriptors)
                {
                    if (getTabTitle().equals(runContentDescriptor.getDisplayName()))
                    {
                        try
                        {
                            contentManager.removeRunContent(executor, runContentDescriptor);
                        }
                        catch (Exception e)
                        {
                            LOG.debug("[FRC] Could not dispose of RunContentDescriptor. Cause Summary: " + e.toString(), e);
                        }
                    }
                }
            }
            catch (Exception e)
            {
                LOG.warn("[FRC] An exception occurred when cleaning up content windows. Cause Summary: " + e.toString(), e);
            }
        }
    }


    @Override
    public void dispose()
    {
        try
        {
            invokeStop();
        }
        catch (Exception e)
        {
            LOG.info("[FRC] An exception occurred when disposing of RioLogContentExecutor: " + e.toString());
        }
        Disposer.dispose(this);
        LOG.debug("[FRC] Disposing of " + getClass().getSimpleName() + " complete.");
    }
    
    
    @NotNull
    protected StringBuffer createRioLogMessage()
    {
        StringBuffer message =
            new StringBuffer("\n")
                .append(FrcBundle.message("frc.riolog.first.start.message.tcp.line1"))
                .append("\n")
                .append(FrcBundle.message("frc.riolog.first.start.message.tcp.line2"))
                .append("\n");
        @Nullable
        Boolean includeDesktopSupport = ReadAction.compute( () -> FrcGradleService.Companion.getInstance(myProject).isIncludeDesktopSupport());
        if (includeDesktopSupport != null && includeDesktopSupport)
        {
            message.append(FrcBundle.message("frc.riolog.first.start.message.tcp.line3")).append("\n");
        }
        return message;
    }


    //Taken from com.intellij.execution.configurations.CommandLineState - need to modify to use in this class
    protected static class RioLogPauseOutputAction extends ToggleAction implements DumbAware
    {
        private final ConsoleView myConsole;
        private final ProcessHandler myProcessHandler;


        public RioLogPauseOutputAction(final ConsoleView console, final ProcessHandler processHandler)
        {
            super(ExecutionBundle.message("run.configuration.pause.output.action.name"),
                  "Pauses the output which will be buffered and then displayed when the output is un-paused. Note that scrolling up will pause scrolling.",
                  AllIcons.Actions.Pause);
            myConsole = console;
            myProcessHandler = processHandler;
        }


        @Override
        public boolean isSelected(final @NotNull AnActionEvent event)
        {
            return myConsole.isOutputPaused();
        }


        @Override
        public void setSelected(final @NotNull AnActionEvent event, final boolean flag)
        {
            myConsole.setOutputPaused(flag);
            ApplicationManager.getApplication().invokeLater(() -> update(event));
        }


        @Override
        public void update(@NotNull final AnActionEvent event)
        {
            super.update(event);
            final Presentation presentation = event.getPresentation();
            final boolean isRunning = myProcessHandler != null && !myProcessHandler.isProcessTerminated();
            if (isRunning)
            {
                presentation.setEnabled(true);
            }
            else
            {
                if (!myConsole.canPause())
                {
                    presentation.setEnabled(false);
                    return;
                }
                if (!myConsole.hasDeferredOutput())
                {
                    presentation.setEnabled(false);
                }
                else
                {
                    presentation.setEnabled(true);
                    ApplicationManager.getApplication().invokeLater(() -> {
                        WriteAction.run(() -> {
                            myConsole.performWhenNoDeferredOutput(() -> update(event));
                        });
                        
                    });
                }
            }
        }
    
    
        @Override
        public @NotNull ActionUpdateThread getActionUpdateThread()
        {
            return ActionUpdateThread.BGT;
        }
    }


    private class RioLogStopAction extends DumbAwareAction
    {
        public RioLogStopAction()
        {
            super(ExecutionBundle.message("run.configuration.stop.action.name"), "Stops the monitoring of the roboRIO log output.", AllIcons.Actions.Suspend);
        }


        @Override
        public void actionPerformed(@NotNull AnActionEvent event)
        {
            ApplicationManager.getApplication().invokeLater(() ->
                                                            {
                                                                // There's a corner case of at least the myProcessHandler being null when
                                                                // the dynamic plugin is unloaded/disabled while an FRC project is open
                                                                if (rioLogMonitorProcess != null)
                                                                {
                                                                    rioLogMonitorProcess.stop();
                                                                }
                                                                
                                                                if (myProcessHandler != null)
                                                                {
                                                                    myProcessHandler.destroyProcess();
                                                                }
                                                                
                                                                if (getRioLogMonitorProcess() != null)
                                                                {
                                                                    getRioLogMonitorProcess().monitoringStopped();
                                                                }
                                                                update(event);
                                                                // Commenting out for now as it is causing issues
                                                                //ensureContentIsPinned();
                                                            });
        }


        @Override
        public void update(AnActionEvent event)
        {
            final Presentation presentation = event.getPresentation();
            if (presentation.isTemplate()) {
                LOG.info("[FRC] Can not preform update as presentation is a template");
            } else {
                presentation.setVisible(true);
                presentation.setEnabled(myStopEnabled != null && myStopEnabled.compute());
            }
        }
    
    
        @Override
        public @NotNull ActionUpdateThread getActionUpdateThread()
        {
            return ActionUpdateThread.BGT;
        }
    }

    private class RioLogRerunAction extends DumbAwareAction
    {

        private static final String startText = "Start Monitoring RioLog";
        private static final String startDescription = "Starts the roboRIO Log monitoring";
        private static final String restartText = "Restart";
        private static final String restartDescription = "Clears the console and restarts the roboRIO Log monitoring";


        public RioLogRerunAction(JComponent consolePanel)
        {
            super(restartText, restartDescription, RESTART_ICON);
            registerCustomShortcutSet(CommonShortcuts.getRerun(), consolePanel);
        }


        @Override
        public void actionPerformed(@NotNull AnActionEvent event)
        {
            reRun();
        }


        @Override
        public void update(AnActionEvent event)
        {
            final Presentation presentation = event.getPresentation();
            if (myStopEnabled.compute())
            {
                presentation.setIcon(RESTART_ICON);
                presentation.setText(restartText);
                presentation.setDescription(restartDescription);
            }
            else
            {
                presentation.setIcon(START_ICON);
                presentation.setText(startText);
                presentation.setDescription(startDescription);
            }
        }
    
    
        @Override
        public @NotNull ActionUpdateThread getActionUpdateThread()
        {
            return ActionUpdateThread.BGT;
        }
    }


    private class RioLogClearAllAction extends DumbAwareAction
    {
        public RioLogClearAllAction()
        {
            super("Clear All", "Clears the content of the roboRIO Log console.", AllIcons.Actions.GC);
        }


        @Override
        public void actionPerformed(@NotNull AnActionEvent anActionEvent)
        {
            myConsoleView.clear();
        }


        @Override
        public void update(@NotNull AnActionEvent e)
        {
            boolean enabled = myConsoleView.getContentSize() > 0;
            if (!enabled)
            {
                enabled = e.getData(LangDataKeys.CONSOLE_VIEW) != null;
                Editor editor = e.getData(CommonDataKeys.EDITOR);
                if (editor != null && editor.getDocument().getTextLength() == 0)
                {
                    enabled = false;
                }
            }
            e.getPresentation().setEnabled(enabled);
        }
    
    
        @Override
        public @NotNull ActionUpdateThread getActionUpdateThread()
        {
            return ActionUpdateThread.BGT;
        }
    }


    private static class RioLogToggleAutoClearAction extends ToggleAction
    {
        public RioLogToggleAutoClearAction()
        {
            super("Toggle Auto Clear",
                  "Toggles whether the console output is automatically cleared upon detecting roboRIO startup/restart.",
                  AUTO_CLEAR_ICON);
        }


        @Override
        public boolean isSelected(@NotNull AnActionEvent e)
        {
            return FrcApplicationSettings.getInstance().getClearRioLogOnRobotRestart();
        }


        @Override
        public void setSelected(@NotNull AnActionEvent event, boolean state)
        {
            try
            {
                FrcApplicationSettings.getInstance().setClearRioLogOnRobotRestart(state);
            }
            catch (Exception ex)
            {
                LOG.warn("[FRC] An Exception occurred when toggling the AutoClear option. Cause Summary: " + ex.toString(), ex);
            }
        }
    
    
        @Override
        public @NotNull ActionUpdateThread getActionUpdateThread()
        {
            return ActionUpdateThread.BGT;
        }
    }
}
