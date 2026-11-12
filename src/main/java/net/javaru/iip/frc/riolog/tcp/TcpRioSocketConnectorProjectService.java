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

package net.javaru.iip.frc.riolog.tcp;

import java.io.BufferedInputStream;
import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.WebSocket;
import java.time.Duration;
import java.util.concurrent.CompletableFuture;
import java.util.concurrent.CompletionStage;
import java.net.Inet4Address;
import java.net.InetAddress;
import java.net.InetSocketAddress;
import java.net.Socket;
import java.net.UnknownHostException;
import java.nio.charset.StandardCharsets;
import java.util.Arrays;
import java.util.HashMap;
import java.util.Map;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.locks.Condition;
import java.util.concurrent.locks.Lock;
import java.util.concurrent.locks.ReentrantLock;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

import org.jetbrains.annotations.NotNull;
import com.intellij.openapi.diagnostic.Logger;
import com.intellij.openapi.project.Project;
import com.intellij.openapi.util.SystemInfo;

import net.javaru.iip.frc.settings.FrcProjectTeamNumberService;
import net.javaru.iip.frc.settings.FrcRoboRioSettings;


/* 
    "Based on" (well mostly directly ported over from) the RioConnector class
    https://github.com/wpilibsuite/riolog/blob/master/src/main/java/netconsole2/RioConnector.java
    https://github.com/wpilibsuite/EclipsePlugins/blob/master/edu.wpi.first.wpilib.plugins.riolog/src/netconsole2/RioConnector.java
*/

public class TcpRioSocketConnectorProjectService
{
    private static final Logger LOG = Logger.getInstance(TcpRioSocketConnectorProjectService.class);

    private static final Pattern dsPattern = Pattern.compile("\"robotIP\"[^:]*:[^0-9]*([0-9]+)");
    
    private final Project project;
    
    private final Lock lock = new ReentrantLock();
    private final Condition cvDone = lock.newCondition();
    private boolean done = false;
    private final Map<String, Thread> attempts = new HashMap<>();
    private Socket socket = null;

    private static final int CONNECTION_TIMEOUT_MS = 2000;
    private static final int MIN_TIMEOUT_MS = 2000;
    private static final int TOTAL_TIMEOUT_SEC = 5;

    /** The port of the netconsole server, on both the SystemCore and the roboRIO. */
    public static final int NETCONSOLE_PORT = 1741;

    /**
     * The SystemCore's USB addresses (the Windows USB network differs from that on other platforms) and its mDNS host name.
     * Matches the WPILib VS Code extension.
     */
    private static final String[] SYSTEMCORE_HOSTS = {SystemInfo.isWindows ? "172.26.0.1" : "172.27.0.1", "172.30.0.1", "robot.local"};

    /** The (2027+) Driver Station's WebSocket, which sends JSON such as {@code {"robotIp": "10.0.0.2"}}. */
    private static final URI DS_WEB_SOCKET_URI = URI.create("ws://localhost:6768/ipws");
    private static final Pattern dsWebSocketPattern = Pattern.compile("\"robotIp\"\\s*:\\s*\"([^\"]*)\"");


    public static TcpRioSocketConnectorProjectService getInstance(@NotNull Project project)
    {
        return project.getService(TcpRioSocketConnectorProjectService.class);
    }


    private TcpRioSocketConnectorProjectService(@NotNull Project project) { this.project = project; }


    public Socket connect() throws InterruptedException
    {
        lock.lock();
        try
        {
            done = false;
            socket = null;
        }
        finally
        {
            lock.unlock();
        }

        final boolean teamNumberIsSet = FrcProjectTeamNumberService.getInstance(project).getTeamNumber() > 0;
        final FrcRoboRioSettings roboRioSettings = FrcRoboRioSettings.getInstance(project);
        // start connection attempts to various address possibilities
        // SystemCore (2027+). The same addresses the WPILib VS Code extension uses. These do not need the team number.
        for (String host : SYSTEMCORE_HOSTS)
        {
            startConnect(host);
        }
        startDsWebSocketConnect();                                              // Driver Station (2027+) provides the robot's address
        // roboRIO (2026 and earlier)
        startConnect(roboRioSettings.getRoboRioHost_USB_asIpByteArray());       // 172.22.11.2                        USB Static IP
        startDsConnect();                                                       // Driver Station (2026 and earlier) provides the robot's address
        if (teamNumberIsSet)
        {
            startConnect(roboRioSettings.getRoboRioHost_IP_asIpByteArray());    // 10.TE.AM.2                         IP (SystemCore and roboRIO)
            startConnect(roboRioSettings.getRoboRioHost_mDNS());                // roboRIO-####-FRC.local             mDNS Host Name
            startConnect(roboRioSettings.getRoboRioHost_DNS());                 // roboRIO-####-FRC.lan               DNS Host Name
            startConnect(roboRioSettings.getRoboRioHost_FieldLocal());          // roboRIO-####-FRC.frc-field.local   FieldLocal
        }
        startTimeDelay(MIN_TIMEOUT_MS);

        // wait for a connection attempt to be successful, or timeout
        lock.lock();
        try
        {
            while (!done && !attempts.isEmpty())
            {
                if (!cvDone.await(TOTAL_TIMEOUT_SEC, TimeUnit.SECONDS))
                {
                    LOG.debug("[FRC] Connection timed out.");
                    return null;
                }
            }

            if (socket == null)
            {
                LOG.debug("[FRC] Not connected to robot");
                return null;
            }

            LOG.debug("[FRC] Connected to robot at " + socket.getInetAddress().getHostAddress());
            return socket;
        }
        finally
        {
            lock.unlock();
        }
    }
    

    private void startDsConnect()
    {
        startAttempt("DS", new Thread(() -> {
            try (Socket socket = new Socket())
            {
                // Try to connect to DS on the local machine
                InetAddress dsAddress = InetAddress.getByAddress(new byte[] {127, 0, 0, 1});
                socket.connect(new InetSocketAddress(dsAddress, 1742), CONNECTION_TIMEOUT_MS);

                // Read JSON "{...}".  This is very limited, does not handle
                // quoted "}" or nested {}, but is sufficient for this purpose.
                InputStream ins = new BufferedInputStream(socket.getInputStream());
                ByteArrayOutputStream buf = new ByteArrayOutputStream();

                int b;
                // Throw away characters until {
                while ((b = ins.read()) >= 0 && b != '{' && !isDone()) {}

                // Read characters until }
                while ((b = ins.read()) >= 0 && b != '}' && !isDone())
                {
                    buf.write(b);
                }

                if (isDone())
                {
                    return;
                }

                String json = buf.toString(StandardCharsets.UTF_8);

                // Look for "robotIP":12345, and get 12345 portion
                Matcher m = dsPattern.matcher(json);
                if (!m.find())
                {
                    LOG.debug("[FRC] DS did not provide robotIP");
                    return;
                }
                long ip = 0;
                try
                {
                    ip = Long.parseLong(m.group(1));
                }
                catch (NumberFormatException e)
                {
                    if (!isDone())
                    {
                        LOG.debug("[FRC] DS provided invalid IP: \"" + m.group(1) + "\"", e);
                    }
                }

                // If zero, the DS isn't connected to the robot
                if (ip == 0)
                {
                    return;
                }

                // Kick off connection to that address
                InetAddress address = InetAddress.getByAddress(new byte[] {
                    (byte) ((ip >> 24) & 0xff),
                    (byte) ((ip >> 16) & 0xff),
                    (byte) ((ip >> 8) & 0xff),
                    (byte) (ip & 0xff)});
                LOG.debug("[FRC] DS provided " + address.getHostAddress());
                startConnect(address);
            }
            catch (Exception e)
            {
                if (!isDone())
                {
                    LOG.debug("[FRC] could not get IP from DS");
                }
            }
            finally
            {
                finishAttempt("DS");
            }
        }));
    }


    /** Gets the robot's address from the (2027+) Driver Station's WebSocket, and connects to it. */
    private void startDsWebSocketConnect()
    {
        startAttempt("DS-WebSocket", new Thread(() -> {
            WebSocket webSocket = null;
            try
            {
                final CompletableFuture<String> robotIp = new CompletableFuture<>();
                webSocket = HttpClient.newHttpClient()
                                      .newWebSocketBuilder()
                                      .connectTimeout(Duration.ofMillis(CONNECTION_TIMEOUT_MS))
                                      .buildAsync(DS_WEB_SOCKET_URI, new WebSocket.Listener()
                                      {
                                          private final StringBuilder text = new StringBuilder();

                                          @Override
                                          public CompletionStage<?> onText(WebSocket ws, CharSequence data, boolean last)
                                          {
                                              text.append(data);
                                              if (last)
                                              {
                                                  final Matcher m = dsWebSocketPattern.matcher(text);
                                                  text.setLength(0);
                                                  final String ip = m.find() ? m.group(1).trim() : "";
                                                  // An empty or zero address means the DS is not connected to the robot
                                                  if (!ip.isEmpty() && !ip.equals("0") && !ip.equals("0.0.0.0"))
                                                  {
                                                      robotIp.complete(ip);
                                                  }
                                              }
                                              ws.request(1);
                                              return null;
                                          }
                                      })
                                      .get(CONNECTION_TIMEOUT_MS, TimeUnit.MILLISECONDS);
                final String ip = robotIp.get(CONNECTION_TIMEOUT_MS, TimeUnit.MILLISECONDS);
                if (!isDone())
                {
                    LOG.debug("[FRC] DS WebSocket provided " + ip);
                    startConnect(ip);
                }
            }
            catch (InterruptedException e)
            {
                Thread.currentThread().interrupt();
            }
            catch (Exception e)
            {
                if (!isDone())
                {
                    LOG.debug("[FRC] could not get the robot IP from the DS WebSocket");
                }
            }
            finally
            {
                if (webSocket != null)
                {
                    webSocket.abort();
                }
                finishAttempt("DS-WebSocket");
            }
        }));
    }


    // Address resolution can take a while, so we do this in a separate
    // thread, and then kick off a connect attempt on every IPv4 that
    // resolves.
    private void startConnect(String host)
    {
        startAttempt(host, new Thread(() -> {
            try
            {
                for (InetAddress current : InetAddress.getAllByName(host))
                {
                    if (!current.isMulticastAddress())
                    {
                        if (current instanceof Inet4Address)
                        {
                            if (isDone())
                            {
                                return;
                            }
                            LOG.debug("[FRC] resolved " + host + " to " + current.getHostAddress());
                            startConnect(current);
                        }
                    }
                }
            }
            catch (Exception e)
            {
                if (!isDone())
                {
                    LOG.debug("[FRC] could not resolve " + host);
                }
            }
            finally
            {
                finishAttempt(host);
            }
        }));
    }


    private void startConnect(InetAddress address)
    {
        startAttempt(address.getHostAddress(), new Thread(() -> {
            try
            {
                tryConnect(address);
            }
            finally
            {
                finishAttempt(address.getHostAddress());
            }
        }));
    }


    private void startConnect(byte[] address)
    {
        try
        {
            startConnect(InetAddress.getByAddress(address));
        }
        catch (UnknownHostException e)
        {
            LOG.debug("[FRC] Error converting address:" + Arrays.toString(address) + ". Cause Summary: " + e.toString(), e);
        }
    }


    private void tryConnect(InetAddress address)
    {
        try
        {
            Socket socket = new Socket();
            socket.connect(new InetSocketAddress(address, NETCONSOLE_PORT), CONNECTION_TIMEOUT_MS);
            putResult(socket);
        }
        catch (Exception e)
        {
            if (!isDone())
            {
                LOG.debug("[FRC] Could not connect to " + address.getHostAddress());
            }
        }
    }


    private void startTimeDelay(int timeout)
    {
        startAttempt("timeout", new Thread(() -> {
            try
            {
                Thread.sleep(timeout);
            }
            catch (InterruptedException e)
            {
                Thread.currentThread().interrupt();
            }
            finally
            {
                finishAttempt("timeout");
            }
        }));
    }


    private void startAttempt(String loc, Thread thr)
    {
        lock.lock();
        try
        {
            // don't start a new attempt if we're already running one against the
            // same address
            if (attempts.containsKey(loc))
            {
                return;
            }
            attempts.put(loc, thr);
        }
        finally
        {
            lock.unlock();
        }
        thr.setDaemon(true);
        thr.start();
    }


    private void finishAttempt(String loc)
    {
        lock.lock();
        try
        {
            attempts.remove(loc);
            if (attempts.isEmpty())
            {
                cvDone.signal();
            }
        }
        finally
        {
            lock.unlock();
        }
    }


    public void stopConnectionAttempts()
    {
        lock.lock();
        try
        {
            done = true;
        }
        finally
        {
            lock.unlock();
        }
    }
    
    
    private boolean isDone()
    {
        lock.lock();
        try
        {
            return done;
        }
        finally
        {
            lock.unlock();
        }
    }


    private void putResult(Socket socket)
    {
        // return result through global and signal
        lock.lock();
        try
        {
            if (!done)
            {
                this.socket = socket;
                done = true;
                cvDone.signal();
                return;
            }
        }
        finally
        {
            lock.unlock();
        }
        // Another address connected first (or the attempts were stopped). Close this connection rather than leaking it, as
        // the robot's netconsole server sends its output to every connected client.
        try
        {
            socket.close();
        }
        catch (IOException ignore) {}
    }
}
