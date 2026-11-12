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

package net.javaru.iip.frc.riolog

import org.junit.jupiter.api.Assertions.assertFalse
import org.junit.jupiter.api.Assertions.assertTrue
import org.junit.jupiter.api.Test

class StartConsoleOnDeployListenerTest
{
    @Test
    fun deployTasksAreDetected()
    {
        assertTrue(StartConsoleOnDeployListener.isDeploy(listOf("deploy")))
        assertTrue(StartConsoleOnDeployListener.isDeploy(listOf(":deploy")))
        assertTrue(StartConsoleOnDeployListener.isDeploy(listOf("clean", "deploy")))
        assertTrue(StartConsoleOnDeployListener.isDeploy(listOf(":robot:deploy")))
    }

    @Test
    fun otherTasksAreNotDetected()
    {
        assertFalse(StartConsoleOnDeployListener.isDeploy(emptyList()))
        assertFalse(StartConsoleOnDeployListener.isDeploy(listOf("build")))
        assertFalse(StartConsoleOnDeployListener.isDeploy(listOf("simulateJava")))
        assertFalse(StartConsoleOnDeployListener.isDeploy(listOf("deployJava", "undeploy")))
    }
}
