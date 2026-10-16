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

package net.javaru.iip.frc.wpilib.services

import com.intellij.notification.Notification
import com.intellij.notification.NotificationAction
import com.intellij.openapi.Disposable
import com.intellij.openapi.actionSystem.AnActionEvent
import com.intellij.openapi.components.PersistentStateComponent
import com.intellij.openapi.components.State
import com.intellij.openapi.components.Storage
import com.intellij.openapi.components.StoragePathMacros
import com.intellij.openapi.components.service
import com.intellij.openapi.diagnostic.debug
import com.intellij.openapi.diagnostic.logger
import com.intellij.openapi.externalSystem.model.DataNode
import com.intellij.openapi.externalSystem.model.project.ProjectData
import com.intellij.openapi.externalSystem.service.project.ExternalProjectRefreshCallback
import com.intellij.openapi.project.Project
import com.intellij.openapi.startup.ProjectActivity
import com.intellij.openapi.startup.StartupManager
import com.intellij.psi.PsiDocumentManager
import com.intellij.psi.PsiElement
import com.intellij.util.DocumentUtil
import net.javaru.iip.frc.facet.isFrcFacetedProject
import net.javaru.iip.frc.i18n.FrcBundle.message
import net.javaru.iip.frc.i18n.FrcMessageKey
import net.javaru.iip.frc.notify.FrcNotifyType
import net.javaru.iip.frc.settings.FrcApplicationSettings
import net.javaru.iip.frc.util.asDate
import net.javaru.iip.frc.util.computeInSmartReadAction
import net.javaru.iip.frc.util.getGradleBuildPsiFile
import net.javaru.iip.frc.util.isGroovyPluginAvailable
import net.javaru.iip.frc.services.GroovyGradleBuildPsi
import net.javaru.iip.frc.util.lastCheckedDateTimeFormatter
import net.javaru.iip.frc.util.reimportGradleProject
import net.javaru.iip.frc.util.runBackgroundTask
import net.javaru.iip.frc.wpilib.getAttachedWpiLibVersion
import net.javaru.iip.frc.wpilib.gradlePluginRepo.GradleRioMavenMetadataState
import net.javaru.iip.frc.wpilib.version.WpiLibVersion
import net.javaru.iip.frc.wpilib.version.WpiLibVersionImpl
import net.javaru.iip.frc.wpilib.version.filterToLatestForYear
import java.time.Duration
import java.time.LocalDateTime
import java.util.*

const val gradleRioId = "edu.wpi.first.GradleRIO"
/** Matches the GradleRIO plugin declaration (e.g. `id "edu.wpi.first.GradleRIO" version "2026.2.1"`), capturing its version. */
private val gradleRioPluginVersionRegex = Regex("""\bid\s*\(?\s*["'](?:edu\.wpi\.first|org\.wpilib)\.GradleRIO["']\s*\)?\s*version\s*\(?\s*["']([^"']+)["']""")

// GitConflictsToolWindowManager is a good example of using the StartupActivity
// AcceptedLanguageLevelsSettings sows a class tha is both a StartupActivity and an application Service

// NOTE: We CANNOT use StartupActivity.Background for this as per the docs, it "should not be used for any work that requires access to indices", which this does
class WpiLibVersionStartupActivity : ProjectActivity
{
    override suspend fun execute(project: Project)
    {
        if (project.isFrcFacetedProject())
        {
            StartupManager.getInstance(project).runAfterOpened {
                // We need to run as a BackgroundTask as it is a slow operation.
                // See Javadoc for com.intellij.util.SlowOperations.assertSlowOperationsAreAllowed
                project.runBackgroundTask("Initializing WPI Lib version service") {
                    val versionService = WpiLibVersionService.getInstance(project)
                    if (FrcApplicationSettings.getInstance().checkWpiLibStatusOnProjectStartup)
                        versionService.checkWpiLibStatusAndAlertIfNeeded()
                    else
                        versionService.scheduleStatusCheck()
                }
            }
        }
    }
}

@State(name = "WpiLibVersionService", storages = [Storage(StoragePathMacros.WORKSPACE_FILE)])
class WpiLibVersionService private constructor(private val project: Project) : PersistentStateComponent<WpiLibVersionServiceState>,
                                                                               Disposable
{
    private val logger = logger<WpiLibVersionService>()

    private var myState: WpiLibVersionServiceState = WpiLibVersionServiceState()

    private val timer = Timer("WpiLibVersionService Check for Update Timer")
    private var timerTask: TimerTask? = null

    var versionStatus: WpiLibVersionStatus? = null
        private set

    /** The FRC year from the attached Wpi Lib Version. May be null if the versionStatus cannot be determined.  */
    val frcYear: Int?
        get() = versionStatus?.attachedVersion?.frcYear


    companion object
    {
        @JvmStatic
        fun getInstance(project: Project) = project.service<WpiLibVersionService>()
    }

    
    fun checkWpiLibStatusAndAlertIfNeededAsBackgroundTask(notifyIfNoUpdateAvailable: Boolean = false,
                                                          maxTimeSinceLastCheck: Duration = Duration.ofSeconds(10), 
                                                          taskName: String = "Checking WPI Lib version status")
    {
        project.runBackgroundTask(taskName, cancellable = true) {
            checkWpiLibStatusAndAlertIfNeeded(notifyIfNoUpdateAvailable, maxTimeSinceLastCheck)
        }
    }
    
    /**
     * Checks if there is a newer version of the WPI Lib available as compared to the one configured for the project, notifying the user
     * is an update is available.
     *
     * @param notifyIfNoUpdateAvailable whether to notify the user if an update is NOT available. Primarily meant for when the user
     *                                  initiates the check via an action. Default is false
     * @param maxTimeSinceLastCheck the maximum time since the last check for an update to allow. If the time since the last
     *                              check is less than this value, no check is performed. The default is 10 seconds, primarily
     *                              to prevent any accidental double checks during project startup or such.
     *                              Use `Duration.ofDays()`, `Duration.ofMinutes()`, etc. to create a value.
     */
    @JvmOverloads
    fun checkWpiLibStatusAndAlertIfNeeded(
        notifyIfNoUpdateAvailable: Boolean = false,
        maxTimeSinceLastCheck: Duration = Duration.ofSeconds(10)
                                         )
    {
        logger.debug {"[FRC] Preparing to check WPI Lib for update. notifyIfNoUpdateAvailable = $notifyIfNoUpdateAvailable  maxTimeSinceLastCheck = $maxTimeSinceLastCheck"}
        val durationSinceLastCheck = myState.durationSinceLastCheck
        if (durationSinceLastCheck < maxTimeSinceLastCheck)
        {
            // TODO: Do we need to call scheduleStatusCheck here?
            logger.debug {"[FRC] time since last check of $durationSinceLastCheck is less than maxTimeSinceLastCheck or $maxTimeSinceLastCheck. No update check will be performed."}
            return
        }

        versionStatus = getWpiLibVersionStatus()
        var updateAvailableNotification: Notification? = null

        if (versionStatus != null)
        {
            if (versionStatus!!.updateAvailableForAttachedYear())
            {
                logger.debug {"[FRC] notifying WPI Lib update is available. WpiLibVersionStatus: $versionStatus"}
                updateAvailableNotification = notifyNewerWpiLibVersionIsAvailable(versionStatus!!)
            }
            else if (notifyIfNoUpdateAvailable)
            {
                logger.debug {"[FRC] notifying WPILib update NOT available. WpiLibVersionStatus: $versionStatus"}
                notifyNoUpdateAvailable(versionStatus!!.attachedVersion.frcYear)
            }
        }
        else if (notifyIfNoUpdateAvailable)
        {
            logger.debug {"[FRC] notifying WPILib update NOT available due to null WpiLibVersionStatus"}
            notifyUnableToCheckVersionStatus()
        }
        else
        {
            logger.debug {"[FRC] WpiLibVersionStatus was null, indicating it could not be determined."}
        }
        // If we've notified an update is available, we do no want to schedule the next check until the user acknowledges the previous check
        if (updateAvailableNotification != null) updateAvailableNotification.whenExpired(::scheduleStatusCheck) else scheduleStatusCheck()
    }


    fun scheduleStatusCheck()
    {
        // NOTE: we don't use timer.scheduleAtFixedRate() because we do not want the next one to be scheduled 
        //       until the user acknowledges the notification of the last one to prevent multiple notifications

        // Cancel any current timer tasks
        cancelTimer()
        val applicationSettings = FrcApplicationSettings.getInstance()
        if (applicationSettings.checkWpiLibStatusPeriodically)
        {
            val last = myState.lastCheckedDateTime
            var next = last.plus(applicationSettings.checkWpiLibStatusInterval)
            val now = LocalDateTime.now()
            if (next.isBefore(now.plus(Duration.ofMinutes(15)))) // we have a small buffer to prevent strange behavior
            {
                next = now.plus(applicationSettings.checkWpiLibStatusInterval)
            }
            timerTask = CheckStatusTimerTask(project)
            timer.schedule(timerTask, next.asDate())
            logger.info("[FRC] next check for WPI Lib update scheduled for $next")
        }
    }

    private fun notifyNewerWpiLibVersionIsAvailable(versionStatus: WpiLibVersionStatus): Notification?
    {
        if (versionStatus.updateAvailableForAttachedYear())
        {
            val availVerString = versionStatus.latestAvailableForSameYear.versionString
            val currVerString = versionStatus.attachedVersion.versionString

            val title = message("frc.notification.wpiLibVersionStatus.updateAvailable.subtitle", availVerString)
            val content = message("frc.notification.wpiLibVersionStatus.updateAvailable.content", availVerString, currVerString)

            val applyAction = object : NotificationAction(message("frc.notification.wpiLibVersionStatus.updateAvailable.upgrade.action.text")) {
                override fun actionPerformed(e: AnActionEvent, notification: Notification)
                {
                    notification.expire()
                    updateWpiLibVersionInGradleBuild(versionStatus.latestAvailableForSameYear)
                }

            }
            val ignoreAction = object : NotificationAction(message("frc.notification.wpiLibVersionStatus.updateAvailable.ignore.action.text")) {
                override fun actionPerformed(e: AnActionEvent, notification: Notification)
                {
                    notification.expire()
                }
            }

            // TODO We need a doNotAskAgain action - but one that adds uses plugin wide functionality so we do not have to always reimplement
            return FrcNotifyType.ACTIONABLE_INFO_WITH_FRC_ICON
                .withContent(content)
                .withFrcPrefixedTitle(title)
                .withNoSubTitle()
                .withActions(applyAction, ignoreAction)
                .notify(project)
        }
        else
        {
            return null
        }

    }

    private fun notifyUnableToCheckVersionStatus()
    {
        FrcNotifyType.ACTIONABLE_INFO.withContentKey("frc.notification.wpiLibVersionStatus.unableToCheck.content").notify(project)
    }

    private fun notifyNoUpdateAvailable(year: Int)
    {
        // we call toString on the year otherwise the resource bundle formats it with a comma: 2,019
        FrcNotifyType.GENERAL_INFO.withContentKey("frc.notification.wpiLibVersionStatus.haveTheLatest.content", year.toString()).notify(project)
    }

    /**
     * Function to update the WPI Lib plugin version in the Gradle build file.
     *
     * @param version the new wpilib version.
     */
    fun updateWpiLibVersionInGradleBuild(version: WpiLibVersion)
    {

        // Keep an eye on:  com.intellij.externalSystem.DependencyModifierService
        // It's experimental, but allows you to modify the build model such as adding a dependency
        // It does not (yet) support modifying a Plugin version. But JetBrains seems to indicate
        // that that is possibly planned:
        // https://intellij-support.jetbrains.com/hc/en-us/community/posts/360010674120-Programatically-Update-Plugin-Version-in-Gradle-Build-File

        DocumentUtil.writeInRunUndoTransparentAction {
            val psiFile = project.getGradleBuildPsiFile()
            if (psiFile == null)
            {
                logger.warn("[FRC] could not find Gradle Build File to update the WPI Lib / GradleRIO plugin")
                FrcNotifyType.ACTIONABLE_WARN
                    .withContent(FrcMessageKey.of("frc.notification.wpiLibVersionStatus.gradle.not.able.to.update", version.versionString))
                    .notify(project)
            }
            else
            {
                if (isGroovyPluginAvailable && GroovyGradleBuildPsi.isGroovyFile(psiFile))
                {
                    /*

                        plugins {
                            id "java"
                            id "edu.wpi.first.GradleRIO" version "2021.2.1"
                        }

                        For now, we are not going to support legacy syntax… there are so many variations given that variables can be used and then can be
                        in turn be used via string concatenation or string replacement/placeholders
                        Legacy syntax:
                                buildscript {
                                  repositories {
                                    maven {
                                      url "https://plugins.gradle.org/m2/"
                                    }
                                  }
                                  dependencies {
                                    classpath "edu.wpi.first:GradleRIO:2020.3.2"
                                  }
                                }

                                apply plugin: "edu.wpi.first.GradleRIO"
                     */
                    if (!GroovyGradleBuildPsi.updateGradleRioVersion(psiFile, gradleRioId, version.versionString) { doGradleReimport() })
                    {
                        logger.warn("[FRC] Could not find GradleRIO plugin Call Expression in order to update the WPI Lib / GradleRIO plugin")
                        FrcNotifyType.ACTIONABLE_WARN
                            .withContent(FrcMessageKey.of("frc.notification.wpiLibVersionStatus.gradle.not.able.to.update", version.versionString))
                            .notify(project)
                    }
                }
                else if (!isGroovyPluginAvailable && psiFile.name.endsWith(".gradle", ignoreCase = true))
                {
                    // e.g. in CLion, where the Groovy plugin is not available, the plugin declaration's version is updated in the file's text
                    val document = PsiDocumentManager.getInstance(project).getDocument(psiFile)
                    val versionRange = document?.let { gradleRioPluginVersionRegex.find(it.text)?.groups?.get(1)?.range }
                    if (versionRange == null)
                    {
                        logger.warn("[FRC] Could not find the GradleRIO plugin declaration in order to update the WPI Lib / GradleRIO plugin")
                        FrcNotifyType.ACTIONABLE_WARN
                            .withContent(FrcMessageKey.of("frc.notification.wpiLibVersionStatus.gradle.not.able.to.update", version.versionString))
                            .notify(project)
                    }
                    else
                    {
                        document.replaceString(versionRange.first, versionRange.last + 1, version.versionString)
                        PsiDocumentManager.getInstance(project).commitDocument(document)
                        doGradleReimport()
                    }
                }
                else if (psiFile.name.endsWith(".kts", ignoreCase = true))
                {
                    FrcNotifyType.ACTIONABLE_INFO
                        .withContent(FrcMessageKey.of("frc.notification.wpiLibVersionStatus.gradle.kotlin.dsl.not.supported.yet", version.versionString))
                        .notify(project)
                }
                else
                {
                    logger.warn("[FRC] Unknown file type for gradle build: ${psiFile.name}")
                    
                    FrcNotifyType.ACTIONABLE_WARN
                        .withContent(FrcMessageKey.of("frc.notification.wpiLibVersionStatus.gradle.not.able.to.update", version.versionString))
                        .notify(project)
                }
            }
        }
    }

    private fun doGradleReimport()
    {
        project.reimportGradleProject(callback = object : ExternalProjectRefreshCallback
                                      {
                                          override fun onSuccess(externalProject: DataNode<ProjectData>?)
                                          {
                                              FrcNotifyType.BUILD__INFO
                                                  .withContent(FrcMessageKey.of("frc.notification.wpiLibVersionStatus.gradle.reimport.success"))
                                                  .withNoTitle() // we generally do not want titles with tool window notifications
                                                  .notify(project)
                                          }

                                          override fun onFailure(errorMessage: String, errorDetails: String?)
                                          {
                                              // The build tool window will automatically open
                                              FrcNotifyType.BUILD__ERROR
                                                  .withContent(FrcMessageKey.of("frc.notification.wpiLibVersionStatus.gradle.reimport.failure"))
                                                  .withNoTitle() // we generally do not want titles with tool window notifications
                                                  .notify(project)
                                          }
                                      })
    }

    private fun getWpiLibVersionStatus(): WpiLibVersionStatus?
    {
        logger.debug {"[FRC] getWpiLibVersionStatus() called. Will perform work in runReadActionInSmartMode"}
        var versionStatus: WpiLibVersionStatus? = null
        // Checking the Gradle plugin repository for newer versions is a network call, which must not be done inside a read action (or on the EDT)
        if (!project.isDisposed && project.isFrcFacetedProject()) GradleRioMavenMetadataState.getInstance(true)
        project.computeInSmartReadAction {
            if (!project.isDisposed && project.isFrcFacetedProject())
            {
                logger.debug {"[FRC] getWpiLibVersionStatus() : runReadActionInSmartMode has started."}
                val state = GradleRioMavenMetadataState.getInstance()
                val latestAvailableVersion = state.wpiLibMavenMetadata.latestAsWpiLibVersion

                val attachedVersion = project.getAttachedWpiLibVersion()
                if (attachedVersion != null)
                {
                    // TODO:  #88 we should check for a conflict between project year in the wpi_lib_preferences and the attached library?
                    //       This should be added as inspection that runs on project startup, and anytime the preferences file changes
                    val projectYear = attachedVersion.frcYear

                    // TODO: if attached is null, we should check the Gradle file and see what is configured

                    val latestAvailableForSameYear = state.wpiLibMavenMetadata.wpiLibVersions.filterToLatestForYear(projectYear)
                    if (latestAvailableForSameYear != null)
                    {
                        versionStatus = WpiLibVersionStatus(attachedVersion, latestAvailableForSameYear, latestAvailableVersion)
                        logger.debug {"[FRC] WpiLibVersionStatus readActionInSmartMode determined to be: $versionStatus"}
                    }
                }
            }
        }
        myState.updateLastCheckedTime()
        logger.debug {"[FRC] getWpiLibVersionStatus() returning WpiLibVersionStatus of:  $versionStatus"}
        return versionStatus
    }

    override fun getState(): WpiLibVersionServiceState = myState

    override fun loadState(state: WpiLibVersionServiceState)
    {
        myState = state
    }

    override fun dispose()
    {
        cancelTimer()
    }

    private fun cancelTimer()
    {
        timerTask?.cancel()
        timer.purge()
    }

    class CheckStatusTimerTask(private val project: Project) : TimerTask()
    {
        override fun run() = project.service<WpiLibVersionService>().checkWpiLibStatusAndAlertIfNeededAsBackgroundTask()
    }
}


data class WpiLibVersionStatus(
    val attachedVersion: WpiLibVersion,
    val latestAvailableForSameYear: WpiLibVersion,
    val latestAvailableVersion: WpiLibVersion?
                              )
{
    fun updateAvailableForAttachedYear(): Boolean = latestAvailableForSameYear.isNewerThan(attachedVersion)

    @Suppress("unused")
    constructor(attachedVersion: String, latestAvailableForSameYear: String, latestAvailableVersion: String) :
        this(
            WpiLibVersionImpl.parse(attachedVersion),
            WpiLibVersionImpl.parse(latestAvailableForSameYear),
            WpiLibVersionImpl.parse(latestAvailableVersion)
            )
}

data class WpiLibVersionServiceState(var lastChecked: String = "20180101000000")
{
    val lastCheckedDateTime: LocalDateTime
        get() = LocalDateTime.parse(lastChecked, lastCheckedDateTimeFormatter)

    val durationSinceLastCheck: Duration
        get() = Duration.between(lastCheckedDateTime, LocalDateTime.now())

    @JvmOverloads
    fun updateLastCheckedTime(checkTime: LocalDateTime = LocalDateTime.now())
    {
        lastChecked = lastCheckedDateTimeFormatter.format(checkTime)
    }

}

