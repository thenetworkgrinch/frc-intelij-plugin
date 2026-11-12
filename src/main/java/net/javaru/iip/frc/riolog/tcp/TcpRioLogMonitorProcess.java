/*
 * Copyright 2015-2019 the original author or authors
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

package net.javaru.iip.frc.riolog.tcp;

import java.io.DataInputStream;
import java.io.IOException;
import java.io.OutputStream;
import java.net.Socket;
import java.nio.ByteBuffer;
import java.util.concurrent.ArrayBlockingQueue;
import java.util.concurrent.BlockingQueue;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.atomic.AtomicBoolean;
import java.util.concurrent.locks.Condition;
import java.util.concurrent.locks.Lock;
import java.util.concurrent.locks.ReentrantLock;
import java.util.function.Consumer;

import org.apache.commons.lang3.StringUtils;
import org.jetbrains.annotations.NotNull;
import com.intellij.openapi.diagnostic.Logger;
import com.intellij.openapi.project.Project;

import net.javaru.iip.frc.riolog.AbstractRioLogMonitorProcess;
import net.javaru.iip.frc.riolog.tcp.message.ErrorMessage;
import net.javaru.iip.frc.riolog.tcp.message.InfoMessage;
import net.javaru.iip.frc.riolog.tcp.message.Message;
import net.javaru.iip.frc.riolog.tcp.message.MessageToStringRenderer;
import net.javaru.iip.frc.settings.FrcProjectTeamNumberService;



public class TcpRioLogMonitorProcess extends AbstractRioLogMonitorProcess
{
    private static final Logger LOG = Logger.getInstance(TcpRioLogMonitorProcess.class);

    private static final byte[] emptyFrame = new byte[] {0, 0};
    /** How long to wait after a round of connection attempts fails before trying again. */
    private static final long RECONNECT_DELAY_MS = 3_000;
    
    private final BlockingQueue<String> riologQueue = new ArrayBlockingQueue<>(2_048);

    
    
    /**
     *
     * @param project the project the monitoring process is running for
     * @param clearConsoleRunnable Runnable that programmatically 'clicks' the clear button on the Executor window.
     * @param stopRioLogRunnable   Runnable that programmatically 'clicks' the stop button on the Executor window.
     *
     * @throws IllegalStateException If an initialization issue occurs
     */
    public TcpRioLogMonitorProcess(@NotNull  Project project, @NotNull Runnable clearConsoleRunnable, @NotNull Runnable stopRioLogRunnable) throws IllegalStateException
    {
        super(project, clearConsoleRunnable, stopRioLogRunnable);
    }


    @NotNull
    @Override
    protected RioLogMonitoringRunnable initMonitoringRunnable()
    {
        final RioLogMonitoringRunnable rioLogMonitor = new TcpRioLogMonitoringRunnable();
        final String message = String.format("[FRC] Using '%s' for monitoring.", rioLogMonitor.getClass().getSimpleName());
        LOG.info(message);
        return rioLogMonitor;
    }

    private class TcpRioLogMonitoringRunnable extends AbstractRioLogMonitoringRunnable
    {
        private Thread listenerThread;

        protected TcpRioLogMonitoringRunnable()
        {
            super();
        }

        @Override
        public void run()
        {
            // The SystemCore can be reached (via USB, robot.local, or the Driver Station) without the team number. It is only needed
            // for the team based addresses (e.g. 10.TE.AM.2), so connect either way.
            if (FrcProjectTeamNumberService.getInstance(project).getTeamNumber() <= 0)
            {
                consoleWriter.println("Your team number is not configured, so only the USB, robot.local, and Driver Station addresses will be tried.");
                consoleWriter.println("To also connect via the team based addresses (e.g. 10.TE.AM.2), configure it in Settings > Languages & Frameworks > FRC.");
            }
            {
                logStartingMonitoring();
                isRunning = true;
                final TcpRioLogListener rioLogListener = new TcpRioLogListener();
                listenerThread = new Thread(rioLogListener);
                listenerThread.setDaemon(true);
                listenerThread.setName("SystemCoreConsoleListener");
                listenerThread.start();
                
                while (listenerThread.isAlive() && !listenerThread.isInterrupted()) 
                {
                    try
                    {
                        final String receivedText = riologQueue.poll(1, TimeUnit.SECONDS);
                        if (receivedText != null)
                        {
                            processReceivedText(receivedText);
                        }
                    }
                    catch (InterruptedException e)
                    {
                        LOG.debug("[FRC] InterruptedException in TcpRioLogMonitoringRunnable.run(). Calling 'stop().");
                        // TODO: As noted in AbstractRioLogMonitoringRunnable, we want to get rid of these flags in favor of thread interruption monitoring
                        isRunning = false;
                        enabled = false;
                        try
                        {
                            if (!listenerThread.isInterrupted()) { listenerThread.interrupt(); }
                        }
                        catch (Exception ignore) {}
                        stop();
                    }
                }
            }
        }


        @Override
        protected boolean addLineBreak()
        {
            return true;
        }

        @Override
        public void stop()
        {
            LOG.debug("[FRC] stopping TCP listener");
            super.stop();
            if (listenerThread != null && listenerThread.isAlive() && !listenerThread.isInterrupted())
            {
                listenerThread.interrupt();
            }
        }

        
        @Override
        @NotNull
        protected String getStartingMonitoringMessage() {return "Connecting to the robot...";}

    }


    
    
    class TcpRioLogListener implements Runnable
    {
        /* 
            "Based on" (well mostly directly ported over from) the RioConsole class
            https://github.com/wpilibsuite/riolog/blob/master/src/main/java/netconsole2/RioConsole.java
            https://github.com/wpilibsuite/EclipsePlugins/blob/master/edu.wpi.first.wpilib.plugins.riolog/src/netconsole2/RioConsole.java
        */
        
        private Socket socket;
        private Thread sender;
        private boolean autoReconnect = true;
        private final AtomicBoolean cleanup = new AtomicBoolean(false);
        private final AtomicBoolean reconnect = new AtomicBoolean(false);
        // TODO add capability (i.e. toolbar button) to set verbosity level and thus the showWarning and showInfo booleans
        private final AtomicBoolean showWarning = new AtomicBoolean(true); 
        private final AtomicBoolean showInfo = new AtomicBoolean(true);
        private Consumer<Boolean> connectedCallback = null;
        private final Lock lock = new ReentrantLock();
        private final Condition wakeupListener = lock.newCondition();        
        
        @Override
        public void run()
        {
            try
            {
                ByteBuffer data = ByteBuffer.allocate(65536);
                DataInputStream in = null;

                while (!Thread.currentThread().isInterrupted() && !cleanup.get())
                {
                    if (in == null || reconnect.getAndSet(false))
                    {
                        if (LOG.isTraceEnabled()) { LOG.trace("[FRC] in was null or reconnect was true."); }
                        
                        lock.lock();
                        try
                        {
                            while (!autoReconnect)
                            {
                                wakeupListener.await();
                            }
                        }
                        catch (InterruptedException e)
                        {
                            LOG.debug("[FRC] Received InterruptedException from wakeupListener.await() in TcpRioLogListener.run(). Breaking out of run loop ");
                            Thread.currentThread().interrupt();
                            break;
                        }
                        finally
                        {
                            lock.unlock();
                        }
                        
                        LOG.trace("[FRC] starting TCP reconnect");
                        in = connect();
                        if (in == null)
                        {
                            LOG.trace("[FRC] Did not reconnect.");
                            // Wait before trying again, rather than continuously starting a new round of connection attempts
                            // (each of which resolves host names and starts a thread per address)
                            try
                            {
                                TimeUnit.MILLISECONDS.sleep(RECONNECT_DELAY_MS);
                            }
                            catch (InterruptedException e)
                            {
                                Thread.currentThread().interrupt();
                                break;
                            }
                            continue;
                        }
                    }

                    if (cleanup.get())
                    {
                        break;
                    }

                    @SuppressWarnings("UnusedAssignment")
                    int tag = -1;
                    try
                    {
                        tag = readSegment(data, in);
                    }
                    catch (IOException e)
                    {
                        LOG.warn("[FRC] SystemCore Console TCP socket disconnected (or other IOException) during read: " + e.toString());
                        lock.lock();
                        Consumer<Boolean> connCb;
                        try
                        {
                            connCb = connectedCallback;
                        }
                        finally
                        {
                            lock.unlock(); 
                        }
                        
                        if (connCb != null)
                        {
                            connCb.accept(Boolean.FALSE);
                        }
                        setSocket(null);
                        in = null;
                        continue;
                    }

                    handleSegment(tag, data);
                } 
                LOG.debug("[FRC] exiting TcpRioLogListener.run() loop");
                // closeSocket() called within stop() which is called in finally block
            }
            finally
            {
                stop();
            }
        }

        
        /**
         * Read a tagged segment into a byte buffer.
         * segmentData must have a capacity of at least 65535.
         * Returns tag, or -1 on error.
         */
        private int readSegment(ByteBuffer segmentData, DataInputStream inputStream) throws IOException
        {
            LOG.trace("[FRC] entering readSegment");
            // read 2-byte length.  Ignore zero length frames
            int len;
            do
            {
                // TODO: We can remove these wrapping logging calls once the read issue is resolved
                LOG.trace("[FRC] reading from the inputStream");
                len = inputStream.readUnsignedShort();
                LOG.trace("[FRC] inputStream read has completed len = " + len);
            } while (len == 0);

            // read 1-byte tag
            int tag = inputStream.readUnsignedByte();
            LOG.trace("[FRC] got segment len=" + len + " tag=" + tag);

            // subtract 1 for tag
            len -= 1;

            segmentData.clear();
            segmentData.limit(len);
            byte[] data = segmentData.array();

            int bytesRead = 0;
            while (bytesRead < len)
            {
                int nRead = inputStream.read(data, bytesRead, len - bytesRead);
                if (nRead < 0)
                {
                    return -1;
                }
                bytesRead += nRead;
            }
            LOG.trace("[FRC] finished reading segment. returning with tag=" + tag);
            return tag;
        }
        
        private void handleSegment(int tag, ByteBuffer data)
        {
            // The data sent is not direct Strings to display as is, but "Messages" that need to be (for the lat of a better term) 
            // parsed. Then those Messages need to be rendered to get the actual content to display on the console.
            try
            {
                if (LOG.isTraceEnabled())
                { LOG.trace("[FRC] handleSegment called: tag=" + tag); }

                Message message;
                if (tag == 11)
                {  // Error or warning
                    message = new ErrorMessage(data);
                    if (message.getType() == Message.Type.kWarning && !showWarning.get())
                    {
                        return;
                    }
                }
                else if (tag == 12 && showInfo.get())
                {  // Console
                    message = new InfoMessage(data);
                }
                else
                {
                    LOG.trace("Ignoring tag " + tag);
                    return;  // Ignore other tags
                }


                try
                {
                    // The data sent is not direct Strings to display as is, but "Messages" that need to be (for the lat of a better term) 
                    // parsed. Then those Messages need to be rendered to get the actual content to display on the console.
                    // TODO: let's use the renderToString(Message, Message.RenderOptions()) overload to allow us to pass in custom renderOptions in order to turn on and off the timestamp, errorCode, errorLocation, errorCallstack, warningLocation, warningCallstack
                    final String messageContent = MessageToStringRenderer.renderToString(message);
                    riologQueue.put(messageContent);
                }
                catch (InterruptedException e)
                {
                    LOG.debug("[FRC] InterruptedException during riologQueue.put(). Interrupting listener thread");
                    Thread.currentThread().interrupt();
                }
            }
            catch (Exception e)
            {
                LOG.warn("[FRC] An exception occurred when handling segment. Cause Summary: " + e.toString(), e);
                Thread.currentThread().interrupt();
            }


//            // tag == 11    Error or warning
//            // tag == 12    Standard message
//            // other tags are ignored
//            if (tag == 11 || tag == 12)
//            {
//                try
//                {
//                    final String value = StandardCharsets.UTF_8.decode(data).toString();
//                    if (LOG.isTraceEnabled()) { LOG.trace("[FRC] Queueing Console data: " + value); }
//                    riologQueue.put(value);
//                }
//                catch (InterruptedException e)
//                {
//                    LOG.debug("[FRC] InterruptedException during riologQueue.put(). Interrupting listener thread");
//                    Thread.currentThread().interrupt();
//                }
//                catch (Exception e)
//                {
//                    LOG.warn("[FRC] An exception occurred when handling segment. Cause Summary: " + e.toString(), e);
//                    Thread.currentThread().interrupt();
//                }
//            }
//            else
//            {
//                LOG.debug("[FRC] ignoring tag of '" + tag);
//            }
            
        }
        
        private void setSocket(Socket socket)
        {
            lock.lock();
            try
            {
                this.socket = socket;
            }
            finally
            {
                lock.unlock();
            }
        }

        private boolean isCurrentSocket(Socket s)
        {
            lock.lock();
            try
            {
                return socket == s;
            }
            finally
            {
                lock.unlock();
            }
        }

        private DataInputStream connect()
        {
            LOG.debug("[FRC] Connecting to TCP RioLog Monitoring");
            Socket mySocket;
            try
            {
                mySocket = TcpRioSocketConnectorProjectService.getInstance(project).connect();
            }
            catch (InterruptedException e)
            {
                Thread.currentThread().interrupt();
                return null;
            }

            if (mySocket == null)
            {
                return null;
            }
            final Socket connectedSocket = mySocket;
            setSocket(mySocket);
            DataInputStream in;
            OutputStream out;
            try
            {
                mySocket.setTcpNoDelay(true);  // for keep alives
                in = new DataInputStream(mySocket.getInputStream());
                out = mySocket.getOutputStream();
            }
            catch (IOException e)
            {
                closeSocket();
                return null;
            }
            lock.lock();
            Consumer<Boolean> connCb;
            try
            {
                connCb = connectedCallback;
            }
            finally
            {
                lock.unlock(); 
            }
            
            if (connCb != null)
            {
                connCb.accept(Boolean.TRUE);
            }
            try
            {
                String connectionInfo = "";
                try
                {
                    String host = mySocket.getInetAddress().toString();
                    if (host.startsWith("/")) { host = StringUtils.removeStartIgnoreCase(host, "/"); }
                    connectionInfo = " via " + host + " on port " + mySocket.getPort();
                }
                catch (Exception ignore) {}
                    
                riologQueue.put(">>>Connected to the robot" + connectionInfo + "<<<");
                riologQueue.put("");
            }
            catch (InterruptedException ignore) {}
            LOG.info("[FRC] SystemCore Console TCP socket connected");

            // Kick off a keep alive thread for this connection. A previous connection's thread exits once its socket is closed (it
            // previously was only created for the first connection, so keep alives were not sent, and a lost connection was not
            // detected, after a reconnect).
            if (sender != null)
            {
                sender.interrupt();
            }
            {
                sender = new Thread(() -> {
                    while (!Thread.currentThread().isInterrupted() && !cleanup.get())
                    {
                        try
                        {
                            TimeUnit.SECONDS.sleep(2);
                            out.write(emptyFrame);
                            out.flush();
                        }
                        catch (InterruptedException e)
                        {
                            Thread.currentThread().interrupt();
                            break;
                        }
                        catch (IOException e)
                        {
                            // Only reconnect if this is still the current connection (and not one that has already been replaced)
                            if (isCurrentSocket(connectedSocket))
                            {
                                LOG.debug("[FRC] failed to send keep alive, reconnecting");
                                reconnect();
                            }
                            break;
                        }
                    }
                }, "SystemCoreConsoleSender");
                sender.setDaemon(true);
                sender.start();
            }
            return in;
        }


        public void stop()
        {
            cleanup.set(true);
            TcpRioSocketConnectorProjectService.getInstance(project).stopConnectionAttempts();
            if (sender != null)
            {
                sender.interrupt();
            }
            closeSocket();
            Thread.currentThread().interrupt();
        }


        public void reconnect()
        {
            reconnect.set(true);
            closeSocket();
        }

        public void closeSocket()
        {
            LOG.info("[FRC] Closing SystemCore Console TCP socket");
            lock.lock();
            Socket s;
            try
            {
                s = socket;
                socket = null;
            }
            finally
            {
                lock.unlock();
            }
            
            try
            {
                if (s != null)
                {
                    s.close();
                }
            }
            catch (IOException ignore) {}
        }
    }
}
