/*
 * Copyright 2015-2022 the original author or authors.
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


import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.io.OutputStreamWriter;
import java.io.PipedInputStream;
import java.io.PipedOutputStream;
import java.io.PrintWriter;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.text.DateFormat;
import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

import org.apache.commons.io.output.NullOutputStream;
import org.jetbrains.annotations.NotNull;
import org.jetbrains.annotations.Nullable;
import com.intellij.openapi.diagnostic.Logger;
import com.intellij.openapi.progress.ProcessCanceledException;
import com.intellij.openapi.project.Project;
import com.intellij.util.concurrency.Semaphore;

import net.javaru.iip.frc.i18n.FrcMessageKey;
import net.javaru.iip.frc.notify.FrcNotifyType;
import net.javaru.iip.frc.settings.FrcApplicationSettings;



@SuppressWarnings("WeakerAccess")
public abstract class AbstractRioLogMonitorProcess extends Process
{
    private static final Logger LOG = Logger.getInstance(AbstractRioLogMonitorProcess.class);

    public final static int MAX_PACKET_SIZE = 65507;

    /**
     * Set this System property to 'on' or 'true' to turn on the testing server that will send a constant output of
     * mock log messages to the rioLog port. Used for testing without being attached to a RoboRIO.
     */
    public static final String SIMULATED_LOG_SERVICE_PROP_KEY_BASE = "frc.simulated.log.service";
    public static final String SIMULATED_LOG_SERVICE_ENABLED_PROP_KEY = SIMULATED_LOG_SERVICE_PROP_KEY_BASE + ".enabled";
    public static final String SIMULATED_LOG_SERVICE_PORT_PROP_KEY = SIMULATED_LOG_SERVICE_PROP_KEY_BASE + ".port";
    public static final String SIMULATED_LOG_SERVICE_USE_CONFIGURED_PORT_PROP_KEY = SIMULATED_LOG_SERVICE_PROP_KEY_BASE + ".use.configured.port";
    public static final int SIMULATED_LOG_SERVICE_PORT_DEFAULT = 4248; //arbitrarily chosen port not listed at https://en.wikipedia.org/wiki/List_of_TCP_and_UDP_port_numbers
    private static final Pattern TIME_REGEX = Pattern.compile("\\$\\{time}", Pattern.LITERAL);
    
    //TODO: need to handle a change to the base pattern when we make it configurable
    public static Pattern restartRegex = Pattern.compile(FrcApplicationSettings.getInstance().getRioRestartRegexString());
    
    private final Semaphore myWaitSemaphore;


    protected boolean enabled = true;

    private PipedInputStream in;
    protected PrintWriter consoleWriter;
    protected PrintWriter fileWriter;
    private RioLogMonitoringRunnable rioLogMonitor;
    @NotNull
    protected  final Project project;
    
    /**
     * Runnable that programmatically 'clicks' the clear button on the Executor window.
     */
    protected final Runnable clearConsoleRunnable;
    /**
     * Runnable that programmatically 'clicks' the stop button on the Executor window.
     * This runnable should <strong>not</strong> be called from within this class' 
     * {@link #stop()} method as that would cause an infinite loop since the 
     * stopRioLogRunnable calls this class's {@code stop()} method.
     */
    protected final Runnable stopRioLogRunnable;

    private DateFormat dateFormat = new SimpleDateFormat("yyyy-MM-dd_HH-mm-ss");


    /**
     * 
     *
     * @param project the project the monitoring process is running for
     * @param clearConsoleRunnable Runnable that programmatically 'clicks' the clear button on the Executor window.
     * @param stopRioLogRunnable Runnable that programmatically 'clicks' the stop button on the Executor window.
     *                           
     * @throws IllegalStateException  If an initialization issue occurs
     */
    protected AbstractRioLogMonitorProcess(@NotNull Project project,
                                           @NotNull Runnable clearConsoleRunnable,
                                           @NotNull Runnable stopRioLogRunnable) throws IllegalStateException
    {
        this.project = project;
        this.clearConsoleRunnable = clearConsoleRunnable;
        this.stopRioLogRunnable = stopRioLogRunnable;
        myWaitSemaphore = new Semaphore();
        myWaitSemaphore.down();
    }


    protected static FrcApplicationSettings getSettings() {return FrcApplicationSettings.getInstance(); }
    

    public void start()
    {
        try
        {
            in = new PipedInputStream();
            consoleWriter = new PrintWriter(new OutputStreamWriter(new PipedOutputStream(in), StandardCharsets.UTF_8), /*AutoFlush*/ true);

            if (getSettings().getLogNetConsoleToFile())
            {
                fileWriter = createFilePrintWriter();
            }

        }
        catch (Exception e)
        {
            throw new IllegalStateException("Could not create necessary io streams.", e);
        }

        try
        {
            enabled = true;
            rioLogMonitor = initMonitoringRunnable();
        }
        catch (Exception e)
        {
            enabled = false;
            myWaitSemaphore.up();
            LOG.warn("[FRC] Could not initialize riolog monitor. Cause Summary: " + e.toString(), e);
            FrcNotifyType.ACTIONABLE_ERROR
                .withContent(FrcMessageKey.of("frc.riolog.init.failure.content"))
                .withFrcPrefixedTitle(FrcMessageKey.of("frc.riolog.init.failure.title"))
                .notify(project);
        }


        if (enabled && rioLogMonitor != null)
        {
            Thread thread = new Thread(rioLogMonitor);
            thread.setName("RioLogMonitorProcess");
            thread.start();
        }
    }


    @NotNull
    protected abstract RioLogMonitoringRunnable initMonitoringRunnable();


    public void stop()
    {
        // Do not call the stopRioLogRunnable from the stop method. That runnable calls this stop method. 
        // So we'd get into an endless loop.
        destroy();
    }


    @SuppressWarnings("unused")
    public void restart()
    {
        stop();
        start();
    }


    public int getMonitoredPort()
    {
        return rioLogMonitor == null || rioLogMonitor.getPort() == null ? -1 : rioLogMonitor.getPort();
    }


    private PrintWriter createFilePrintWriter()
    {
        try
        {
            final boolean append = getSettings().getLogNetConsoleToFileAppend();
            Path outputFile = determineOutputFilePath();
            Files.createDirectories(outputFile.getParent());
            return new PrintWriter(new OutputStreamWriter(new FileOutputStream(outputFile.toFile(), append), StandardCharsets.UTF_8), /*AutoFlush*/ true);
        }
        catch (Exception e)
        {
            LOG.info("[FRC] Could not create PrintWriter for writing RiLog to file. Cause Summary: " + e.toString(), e);
            FrcNotifyType.GENERAL_WARN.withContent(
                FrcMessageKey.of("frc.riolog.file.writer.init.failure.content", e.toString()))
                .withFrcPrefixedTitle(FrcMessageKey.of("frc.riolog.file.writer.init.failure.title"))
                .notify(project);
            return new PrintWriter(NullOutputStream.NULL_OUTPUT_STREAM);
        }
    }


    private Path determineOutputFilePath()
    {
        final Path directory = Paths.get(getSettings().getLogNetConsoleToFilePath());
        final String baseName = getSettings().getLogNetConsoleToFileBaseName();
        final String name = TIME_REGEX.matcher(baseName).replaceAll(Matcher.quoteReplacement(dateFormat.format(new Date())));
        return directory.resolve(name);
    }


    protected void rollFileWriter()
    {
        if (fileWriter != null)
        {
            fileWriter.flush();
            fileWriter.close();
            fileWriter = createFilePrintWriter();
        }
    }


    protected void monitoringStopped()
    {
        // no op by default
    }


    @Override
    public InputStream getInputStream() { return in; }


    @Override
    public OutputStream getOutputStream() { return OutputStream.nullOutputStream(); }


    /**
     * There is no error output; everything is written to the {@link #getInputStream() input stream}. This must be an empty
     * stream that is at its end. The process handler reads it on its own thread, in blocking mode by default (the
     * 'output.reader.blocking.mode' property). A stream whose read() returned 0, rather than -1, made that thread spin
     * forever, using a full CPU core and flooding the console with NUL characters.
     */
    @Override
    public InputStream getErrorStream() { return InputStream.nullInputStream(); }


    @Override
    public int waitFor() throws InterruptedException
    {
        try
        {
            myWaitSemaphore.waitFor();
            return 0;
        }
        catch (ProcessCanceledException e)
        {
            return -1;
        }
    }


    @Override
    public int exitValue()
    {
        return 0;
    }


    @Override
    public void destroy()
    {
        enabled = false;
        try
        {
            if (rioLogMonitor != null)
            {
                rioLogMonitor.stop();
            }
        }
        catch (Exception ignore) {}
        finally
        {
            myWaitSemaphore.up();
        }
        try { if (in != null) {in.close();} } catch (Exception ignore) {}
        try { if (consoleWriter != null) {consoleWriter.close();} } catch (Exception ignore) {}
        try { if (fileWriter != null) {fileWriter.close();} } catch (Exception ignore) {}
    }


    public boolean isEnabled() { return enabled; }


    protected interface RioLogMonitoringRunnable extends Runnable
    {
        @Nullable
        @Deprecated
        Integer getPort();

        boolean isRunning();

        void stop();
        
        void logMessage(CharSequence message);
    }

    protected abstract class AbstractRioLogMonitoringRunnable implements RioLogMonitoringRunnable
    {
        @Deprecated // TODO - Let's get rid of this since it no longer has bearing and is not a user configurable item
        @Nullable
        protected final Integer port;
        // TODO - Let's deprecate this favor of thread interruption monitoring
        protected boolean isRunning = true;


        protected AbstractRioLogMonitoringRunnable() {this.port = null;}
        protected AbstractRioLogMonitoringRunnable(@Nullable Integer port) {this.port = port;}


        protected void processReceivedText(String received)
        {
            if (getSettings().getClearRioLogOnRobotRestart() && isRestartNotification(received))
            {
                clearConsoleRunnable.run();
                rollFileWriter();
                logStartingMonitoring();
            }
            
            if (received.contains("Listening for transport dt_socket at address:"))
            {
                if (addLineBreak())
                {
                    consoleWriter.println();
                }
                consoleWriter.println("The robot is waiting for the debugger to be attached.");
            }
    
            consoleWriter.print(received);
            
            if (addLineBreak())
            {
                consoleWriter.println();
            }
            consoleWriter.flush();
            if (fileWriter != null)
            {
                fileWriter.print(received);
                if (addLineBreak())
                {
                    fileWriter.println();
                }
                fileWriter.flush();
            }
        }


        @Override
        public boolean isRunning() { return isRunning; }


        @Override
        @Nullable
        @Deprecated
        public Integer getPort() { return port; }


        protected void logStartingMonitoring()
        {
            consoleWriter.println(getStartingMonitoringMessage());
            consoleWriter.println();
            consoleWriter.flush();
            if (fileWriter != null)
            {
                fileWriter.println(getStartingMonitoringMessage());
                fileWriter.println();
                fileWriter.flush();
            }
        }

        @Override
        public void logMessage(@NotNull CharSequence message)
        {
            final String msg = message.toString();
            consoleWriter.println(msg);
            consoleWriter.println();
            consoleWriter.flush();
            if (fileWriter != null)
            {
                fileWriter.println(msg);
                fileWriter.println();
                fileWriter.flush();
            }
        }


        @NotNull
        protected abstract String getStartingMonitoringMessage();


        protected boolean addLineBreak()
        {
            //TODO: add to settings
            return false;
        }


        protected boolean isRestartNotification(String text)
        {
            // TODO: It'd be nice if the line is the debugger attachment, it clears for it, but NOT for the next line which is the "Robot program starting" to prevent a flash like effect
            if (getSettings().getUseRegexForRestartCheck())
            {
                return restartRegex.matcher(text).find();
            }
            else
            {
                return text.contains("*** Robot program starting ***") || 
                       text.contains("Listening for transport dt_socket at address:"); // ||
                       // (text.contains("Launching") && text.contains("-jar") && text.contains("FRCUserProgram.jar"));
            }
        }


        @Override
        public void stop()
        {
            isRunning = false;
        }
    }
}
