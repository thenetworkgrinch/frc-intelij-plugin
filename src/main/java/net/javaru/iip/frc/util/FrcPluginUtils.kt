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

package net.javaru.iip.frc.util

import com.intellij.ide.plugins.IdeaPluginDescriptor
import com.intellij.ide.plugins.PluginManagerCore
import com.intellij.openapi.Disposable
import com.intellij.openapi.application.Application
import com.intellij.openapi.application.ApplicationManager
import com.intellij.openapi.application.ModalityState
import com.intellij.openapi.diagnostic.logger
import com.intellij.openapi.extensions.PluginId
import com.intellij.openapi.project.Project
import com.intellij.openapi.util.Condition
import com.intellij.openapi.vfs.VfsUtil
import com.intellij.openapi.vfs.VirtualFile
import icons.FrcIcons
import net.javaru.iip.frc.FrcPluginGlobals.FRC_PLUGIN_ID_STRING
import net.javaru.iip.frc.services.FrcPluginProjectDisposable
import org.apache.commons.io.FilenameUtils
import java.io.InputStream
import java.net.URL
import java.nio.file.Path

private object FrcPluginUtils
private val LOG = logger<FrcPluginUtils>()

val pluginId: PluginId = PluginId.getId(FRC_PLUGIN_ID_STRING)
val pluginDescriptor: IdeaPluginDescriptor = PluginManagerCore.getPlugin(pluginId)!!
val frcPluginVersion: String? = pluginDescriptor.version
val frcPluginPrimaryVersion : String? = run {
    // remove IDEA version and any -eap or - S N A P S H O T  or such designator
    val index = frcPluginVersion?.indexOf('-') ?: -1
    if (index == -1) frcPluginVersion else frcPluginVersion?.substring(0, index)
}

/** For details, see [Application.invokeLater] */
inline fun invokeLater(crossinline func: () -> Unit)
{
    if (ApplicationManager.getApplication().isDispatchThread)
    {
        func()
    }
    else
    {
        ApplicationManager.getApplication().invokeLater({ func() }, ModalityState.defaultModalityState())
    }
}

/**
 * Example:
 * ```
 * invokeLater({ project.getMainModule() != null }) {
 *      // do work here
 * }
 * ```
 * */
inline fun invokeLater(condition: Condition<*>, crossinline func: () -> Unit)
{
    ApplicationManager.getApplication().invokeLater({ func() }, ModalityState.defaultModalityState(), condition)
}

/** For details, see [Application.invokeAndWait] */
inline fun invokeLaterWait(crossinline func: () -> Unit)
{
    if (ApplicationManager.getApplication().isDispatchThread)
    {
        func()
    }
    else
    {
        ApplicationManager.getApplication().invokeAndWait({ func() }, ModalityState.defaultModalityState())
    }
}

//inline fun invokeLaterOnWriteThread(crossinline func: () -> Unit)
//{
//    if (ApplicationManager.getApplication().isDispatchThread)
//    {
//        func()
//    }
//    else
//    {
//        ApplicationManager.getApplication().invokeLaterOnWriteThread({ func() }, ModalityState.defaultModalityState())
//    }
//}

/**
 * Returns whether a class is available on the classpath, using [Class.forName].
 *
 * @param name the fully qualified name of the class, as returned by [Class.getName]. For example `java.lang.String`
 */
fun classIsAvailable(name: String): Boolean
{
    return try
    {
        Class.forName(name, false, getPluginClassloader())
        true
    }
    catch (ignore: Throwable)
    {
        false
    }
}

/**
 * Whether the (optional) Java plugin is available. It is not in CLion, so code that uses the Java plugin's APIs (such as Java run
 * configurations or JDKs) must only be called when this is true.
 */
val isJavaPluginAvailable: Boolean by lazy { classIsAvailable("com.intellij.openapi.projectRoots.JavaSdk") }

/** Whether the (optional) Groovy plugin is available. It is not in CLion, so Groovy PSI must only be used when this is true. */
val isGroovyPluginAvailable: Boolean by lazy { classIsAvailable("org.jetbrains.plugins.groovy.lang.psi.GroovyFile") }

@JvmOverloads
fun getPluginClassloader(clazz: Class<*> = FrcIcons::class.java): ClassLoader = clazz.classLoader

/**
 *  Gets the URL for a plugin classpath resource path.
 *
 * @receiver the relative path of the classpath resource
 *
 * @return the URL to the resource, or `null` if not found
 *
 * @see getPluginResource
 */
@WillNotThrowException
fun Path?.asPluginResourceUrl(): URL? = if (this == null) null else getPluginResource(toString())

/**
 * Gets the URL for a plugin classpath resource path. For an equivalent
 * `Path` object extension, see [asPluginResourceUrl].
 *
 * @param path the relative path of the classpath resource
 *
 * @return the URL to the resource, or `null` if not found
 *
 * @see asPluginResourceUrl
 */
@WillNotThrowException
fun getPluginResource(path: String?): URL?
{
    return if (path == null)
    {
        null
    }
    else try
    {
        getPluginClassloader().getResource(FilenameUtils.separatorsToUnix(path))
    }
    catch (e: Exception)
    {
        LOG.warn("Could not getPluginResource (as URL) for '$path' due to an exception: $e", e)
        null
    }
}

/**
 *  Gets the VirtualFile for a plugin classpath resource path.
 *
 * @receiver the relative path of the classpath resource
 *
 * @return the URL to the resource, or `null` if not found
 *
 * @see getPluginResource
 */
@WillNotThrowException
fun Path?.asPluginResourceVF(): VirtualFile?
{
    return if (this == null)
    {
        null
    }
    else try
    {
        this.asPluginResourceUrl().toVirtualFile()
    } catch (e: Exception)
    {
        LOG.warn("Could not find Virtual File for path '$this' due to an exception: $e", e)
        null
    }
}

@Suppress("RemoveRedundantQualifierName")
fun java.net.URL?.toVirtualFile(): VirtualFile?
{
    return if (this == null)
    {
        null
    }
    else try
    {
        VfsUtil.findFileByURL(this)
    }
    catch (e: Exception)
    {
        LOG.warn("Could not find URL as a virtual file for URL '$this' due to an exception: $e", e)
        null
    }
}


@WillNotThrowException
fun Path?.asPluginResourceStream(): InputStream? = if (this == null) null else getPluginResourceAsStream(toString())

@WillNotThrowException
fun getPluginResourceAsStream(path: String?): InputStream?
{
    return if (path == null)
    {
        null
    }
    else try
    {
        getPluginClassloader().getResourceAsStream(FilenameUtils.separatorsToUnix(path))
    }
    catch (e: Exception)
    {
        LOG.warn("Could not getPluginResourceAsStream for '$path' due to an exception: $e", e)
        null
    }
}

@WillNotThrowException
fun getPluginResourceAsText(resourcePath: String, logWarnIfNotExist: Boolean = true): String?
{
    val inputStream = getPluginResourceAsStream(resourcePath)
    return if (inputStream == null)
    {
        if (logWarnIfNotExist) LOG.warn("[FRC] Could not find resource: $resourcePath")
        null
    }
    else
    {
        try
        {
            inputStream.bufferedReader().use { it.readText() }
        }
        catch (t: Throwable)
        {
            LOG.warn("[FRC] An exception occurred when trying to read resource '$resourcePath'. Cause Summary: $t", t)
            null
        }
    }
}

/**
 * Returns a project level Disposable iff the project receiver is not null.
 * Otherwise, it returns an application level disposable.
 * @see getProjectParentDisposable
 * @see getApplicationParentDisposable
 *
 */
fun Project?.getParentDisposable(): Disposable = this?.getProjectParentDisposable() ?: ApplicationManager.getApplication()

/**
 * Returns the Application as an application level disposable. In general,
 * we should use project based disposables whenever possible.
 *
 * @see getProjectParentDisposable
 * @see getParentDisposable
 *
 */
fun getApplicationParentDisposable(): Disposable = ApplicationManager.getApplication()

/**
 * Returns a project level disposable.
 * @see getParentDisposable
 *
 */
fun Project.getProjectParentDisposable(): Disposable = FrcPluginProjectDisposable.getInstance(this)

/**
 * Returns the full Semantic Version, including the IntelliJ IDEA Version, of the running FRC plugin. For example: `1.4.0-2020.3`.
 * If you need just the "base"/"core" version, for example 1.4.0, use the `normalVersion` property: `getFrcPlugVersion()?.normalVersion`
 * In the rare event the Plugin Version cannot be determined, or an exception occur during parsing, `null` is returned.
 */
//fun getFrcPluginVersion(): SemVer?
//{
//
//
//    val version =  pluginDescriptor?.version
//    // We're using SemVer from com.asarkar:jsemver but it should be noted IDEA has a built in SemVer in com.intellij.util.text - but it's less robust than the library one
//    return try
//    {
//        if (version == null) null else SemVer.parse(version)
//    } catch (e: Exception)
//    {
//        LOG.warn("[FRC] Could not parse '$version' to a Semantic Version. Cause Summary: $e", e)
//        null
//    }
//}