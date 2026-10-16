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
package net.javaru.iip.frc

import com.intellij.ide.plugins.IdeaPluginDescriptor
import com.intellij.openapi.diagnostic.Logger
import com.intellij.openapi.extensions.PluginDescriptor
import com.intellij.openapi.extensions.PluginId
import com.intellij.pom.java.LanguageLevel
import com.intellij.util.lang.JavaVersion
import org.apache.commons.lang3.BooleanUtils

object FrcPluginGlobals
{
    /**
     * Gets the string representing the plugin ID.
     * To get a [PluginId] instance, use [net.javaru.iip.frc.util.pluginId].
     * To get [IdeaPluginDescriptor] (a sub-interface of a [PluginDescriptor]) use
     * [net.javaru.iip.frc.util.pluginDescriptor].
     *
     * @see net.javaru.iip.frc.util.pluginId
     * @see net.javaru.iip.frc.util.pluginDescriptor
     */
    const val FRC_PLUGIN_ID_STRING = "net.javaru.idea.frc"
    const val FRC_PLUGIN_NAME = "FRC"
    const val FRC_IN_UNIT_TEST_MODE_KEY = "frc.testing.inUnitTestMode"

    /** A logger name `#net.javaru.iip.frc` for logging plugin level events. It should be used sparingly. */
    @JvmField
    val GENERAL_LOGGER = Logger.getInstance("#net.javaru.iip.frc")
    // A getter rather than a field: LanguageLevel is part of the Java plugin, which is not available in CLion. A field would
    // make initializing this object (which almost everything does) fail there.
    val DEFAULT_MIN_REQUIRED_LANGUAGE_LEVEL: LanguageLevel
        get() = LanguageLevel.JDK_11
    @JvmField
    val DEFAULT_MIN_REQUIRED_JAVA_VERSION: JavaVersion = JavaVersion.compose(11)
    @JvmField
    val IS_IN_FRC_INTERNAL_MODE = BooleanUtils.toBoolean(System.getProperty("frc.is.internal", false.toString()))
    @JvmField
    val IS_IN_FRC_UNIT_TEST_MODE = /*ApplicationManager.getApplication().isUnitTestMode ||*/ BooleanUtils.toBoolean(System.getProperty(FRC_IN_UNIT_TEST_MODE_KEY, false.toString()))
    @JvmField
    val IS_NOT_IN_FRC_UNIT_TEST_MODE = !IS_IN_FRC_UNIT_TEST_MODE
}

fun isUnitTestMode(): Boolean = FrcPluginGlobals.IS_IN_FRC_UNIT_TEST_MODE
fun isNotUnitTestMode(): Boolean = FrcPluginGlobals.IS_NOT_IN_FRC_UNIT_TEST_MODE
fun ifInUnitTestMode(action: () -> Unit) {
    if(isUnitTestMode()) {
        action.invoke()
    }
}
fun ifNotInUnitTestMode(action: () -> Unit) {
    if(isNotUnitTestMode()) {
        action.invoke()
    }
}

/**
 * Runs the provided code block, returning its result, if the system is NOT in unit test mode.
 * If it is in uit test mode, the [whenInUnitTestModeResult] is returned.
 *
 * @param whenInUnitTestModeResult The result to return when IN unit test mode
 */
fun <R>ifNotInUnitTestModeOrElse(whenInUnitTestModeResult: R, action: () -> R): R {
    return if(isNotUnitTestMode()) {
        action.invoke()
    }
    else {
        whenInUnitTestModeResult
    }
}

