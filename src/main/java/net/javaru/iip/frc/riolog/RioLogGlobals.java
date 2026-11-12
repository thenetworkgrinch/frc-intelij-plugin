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

public class RioLogGlobals
{

    public static final String TCP_TAB_TITLE = "SystemCore Console";
    public static final String UDP_TAB_TITLE = "Legacy Net Console (2017 and older)";
    public static final String SSH_TAB_TITLE = "SSH Log Tailing";

    public static final String DEFAULT_TAIL_COMMAND = "tail -f /home/lvuser/FRC_UserProgram.log";

    /**
     * The standard log message (line) output by the robRIO on startup.
     * <pre>
     * ➔ Launching «'/usr/local/frc/JRE/bin/java' '-jar' '/home/lvuser/FRCUserProgram.jar'»
     * </pre>
     */
    public static final String ROBO_RIO_STARTUP_LOG_MSG = "\u2794 Launching \u00AB'/usr/local/frc/JRE/bin/java' '-jar' '/home/lvuser/FRCUserProgram.jar'\u00BB";
    
}
