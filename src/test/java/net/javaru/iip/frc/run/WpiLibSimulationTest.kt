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

import org.junit.jupiter.api.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertTrue

internal class WpiLibSimulationTest
{
    @Test
    fun `JDK candidates use the full project year first, then the plain year`()
    {
        val candidates = wpiLibJdkHomeCandidates("2027_alpha7").map { it.toString().replace('\\', '/') }
        assertEquals(2, candidates.size)
        assertTrue(candidates[0].endsWith("wpilib/2027_alpha7/jdk"), candidates[0])
        assertTrue(candidates[1].endsWith("wpilib/2027/jdk"), candidates[1])
    }

    @Test
    fun `JDK candidates for a plain year`()
    {
        val candidates = wpiLibJdkHomeCandidates("2026").map { it.toString().replace('\\', '/') }
        assertEquals(1, candidates.size)
        assertTrue(candidates[0].endsWith("wpilib/2026/jdk"), candidates[0])
    }

    @Test
    fun `simulation VM options are added, keeping the user's options`()
    {
        val options = simulationVmOptions(listOf("-Xmx2g", "-Dfoo=bar"), "C:/robot/build/jni/release")
        assertEquals(listOf("-Xmx2g", "-Dfoo=bar"), options.take(2))
        assertTrue(options.containsAll(listOf("--add-opens", "java.base/jdk.internal.vm=ALL-UNNAMED", "java.base/java.lang=ALL-UNNAMED", "--enable-native-access=ALL-UNNAMED")))
        assertEquals("-Djava.library.path=C:/robot/build/jni/release", options.last())
    }

    @Test
    fun `simulation VM options are replaced, not duplicated, on subsequent runs`()
    {
        val firstRun = simulationVmOptions(listOf("-Xmx2g", "--add-opens", "java.base/java.util=ALL-UNNAMED"), "/old/lib")
        val secondRun = simulationVmOptions(firstRun, "/new/lib")
        assertEquals(simulationVmOptions(listOf("-Xmx2g", "--add-opens", "java.base/java.util=ALL-UNNAMED"), "/new/lib"), secondRun)
        // The user's own --add-opens is kept
        assertTrue(secondRun.windowed(2).contains(listOf("--add-opens", "java.base/java.util=ALL-UNNAMED")))
        assertEquals(1, secondRun.count { it.startsWith("-Djava.library.path=") })
        assertEquals(1, secondRun.count { it == "java.base/jdk.internal.vm=ALL-UNNAMED" })
    }

    @Test
    fun `2027 and later projects are not simulated by a Gradle task`()
    {
        assertFalse(isSimulatedByGradleTask("2027_alpha7"))
        assertFalse(isSimulatedByGradleTask("2028"))
    }

    @Test
    fun `2026 and earlier projects are simulated by the simulateJava task`()
    {
        assertTrue(isSimulatedByGradleTask("2026"))
        assertTrue(isSimulatedByGradleTask("Beta2025-2"))
        assertEquals("simulateJava", simulateJavaGradleTask(debug = false))
        assertEquals("simulateJavaDebug", simulateJavaGradleTask(debug = true))
    }

    @Test
    fun `the simulation run configurations run GradleRIO's run task for 2027 and later, and simulateJava before`()
    {
        assertEquals("run", simulationGradleTask("2027_alpha7"))
        assertEquals("run", simulationGradleTask("2028"))
        assertEquals("simulateJava", simulationGradleTask("2026"))
        assertEquals("simulateJava", simulationGradleTask("Beta2025-2"))
    }
}
