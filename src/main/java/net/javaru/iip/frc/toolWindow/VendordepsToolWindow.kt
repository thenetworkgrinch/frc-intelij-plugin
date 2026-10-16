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

package net.javaru.iip.frc.toolWindow

import com.github.michaelbull.result.onFailure
import com.github.michaelbull.result.onSuccess
import com.intellij.icons.AllIcons
import com.intellij.ide.BrowserUtil
import com.intellij.openapi.Disposable
import com.intellij.openapi.actionSystem.ActionUpdateThread
import com.intellij.openapi.actionSystem.AnActionEvent
import com.intellij.openapi.actionSystem.DefaultActionGroup
import com.intellij.openapi.actionSystem.Separator
import com.intellij.openapi.actionSystem.ToggleAction
import com.intellij.ide.util.PropertiesComponent
import com.intellij.openapi.progress.ProcessCanceledException
import com.intellij.openapi.progress.ProgressIndicator
import com.intellij.openapi.ui.InputValidator
import com.intellij.ui.JBColor
import com.github.michaelbull.result.getOrElse
import net.javaru.iip.frc.wpilib.vendordeps.VendordepsDownload
import net.javaru.iip.frc.wpilib.vendordeps.Vendordeps
import net.javaru.iip.frc.wpilib.vendordeps.likelySeasonYear
import net.javaru.iip.frc.wpilib.extractProjectYear
import java.util.UUID
import com.intellij.openapi.application.ApplicationManager
import com.intellij.openapi.application.ModalityState
import com.intellij.openapi.command.WriteCommandAction
import com.intellij.openapi.diagnostic.logger
import com.intellij.openapi.project.DumbAware
import com.intellij.openapi.project.DumbAwareAction
import com.intellij.openapi.project.Project
import com.intellij.openapi.project.guessProjectDir
import com.intellij.openapi.ui.Messages
import com.intellij.openapi.ui.SimpleToolWindowPanel
import com.intellij.openapi.vfs.VfsUtil
import com.intellij.openapi.vfs.VirtualFile
import com.intellij.openapi.vfs.VirtualFileManager
import com.intellij.openapi.vfs.newvfs.BulkFileListener
import com.intellij.openapi.vfs.newvfs.events.VFileEvent
import com.intellij.openapi.wm.ToolWindow
import com.intellij.openapi.wm.ToolWindowFactory
import com.intellij.openapi.wm.ToolWindowManager
import com.intellij.ui.PopupHandler
import com.intellij.json.JsonFileType
import com.intellij.openapi.fileEditor.FileEditorManager
import com.intellij.testFramework.LightVirtualFile
import com.intellij.ui.TitledSeparator
import java.awt.FlowLayout
import javax.swing.JButton
import javax.swing.SwingUtilities
import com.intellij.ui.ScrollPaneFactory
import com.intellij.ui.SimpleColoredComponent
import com.intellij.ui.SimpleTextAttributes
import com.intellij.ui.components.JBLabel
import com.intellij.ui.components.JBList
import com.intellij.util.io.HttpRequests
import com.intellij.util.ui.JBUI
import com.intellij.util.ui.UIUtil
import net.javaru.iip.frc.wpilib.isWpiLibProject
import net.javaru.iip.frc.util.runBackgroundTask
import net.javaru.iip.frc.wpilib.findWpiLibProjectRootDirs
import net.javaru.iip.frc.cpp.findGradleRioYear
import net.javaru.iip.frc.wpilib.getConfiguredProjectYear
import net.javaru.iip.frc.wpilib.wpiLibDirName
import net.javaru.iip.frc.wpilib.wpiLibPreferencesFileName
import net.javaru.iip.frc.wpilib.vendordeps.VendorJsonRepoService
import net.javaru.iip.frc.wpilib.vendordeps.VendorRepoLibrary
import net.javaru.iip.frc.wpilib.vendordeps.VendordepsListingListener
import net.javaru.iip.frc.wpilib.vendordeps.VendordepsProjectFile
import net.javaru.iip.frc.wpilib.vendordeps.VendordepsProjectFilesListing
import net.javaru.iip.frc.wpilib.vendordeps.VendordepsService
import net.javaru.iip.frc.wpilib.vendordeps.compareVersionText
import net.javaru.iip.frc.wpilib.vendordeps.hasCommandsVersionConflict
import net.javaru.iip.frc.wpilib.vendordeps.vendordepsDirName
import java.awt.BorderLayout
import java.awt.Component
import java.awt.event.MouseAdapter
import java.awt.event.MouseEvent
import javax.swing.DefaultListModel
import javax.swing.JList
import javax.swing.JPanel
import javax.swing.ListCellRenderer
import javax.swing.ListSelectionModel

/**
 * Factory for the "Vendordeps" tool window, which lists the vendor libraries available for the project's year from
 * the [WPILib Vendor JSON Repository](https://github.com/wpilibsuite/vendor-json-repo) and allows them to be
 * installed, updated, and removed.
 */
class VendordepsToolWindowFactory : ToolWindowFactory, DumbAware
{
    companion object
    {
        const val VENDORDEPS_TOOL_WINDOW_ID = "Vendordeps"

        /**
         * Updates if the tool window is available (i.e. shown on the tool window bar) based on if the project is a WPILib project.
         * Used for cases where a project becomes a WPILib project after it was opened, such as when the Gradle import adds the FRC facet.
         */
        @JvmStatic
        fun updateAvailability(project: Project)
        {
            ApplicationManager.getApplication().invokeLater({
                ToolWindowManager.getInstance(project).getToolWindow(VENDORDEPS_TOOL_WINDOW_ID)?.setAvailable(project.isWpiLibProject())
            }, ModalityState.nonModal(), project.disposed)
        }
    }

    override fun createToolWindowContent(project: Project, toolWindow: ToolWindow)
    {
        val panel = VendordepsToolWindowPanel(project)
        val content = toolWindow.contentManager.factory.createContent(panel, null, false)
        content.setDisposer(panel)
        toolWindow.contentManager.addContent(content)
        toolWindow.setAdditionalGearActions(panel.optionsActions)
    }

    override fun shouldBeAvailable(project: Project): Boolean = project.isWpiLibProject()
}

/**
 * A row in the vendordeps list. Either [library] or [installed] (or both) will be present. The [beta] is a newer version,
 * than is available from the vendor repo, served by the vendor's `jsonUrl`; it is only present when betas are being shown.
 */
private data class VendordepsRow(val library: VendorRepoLibrary?, val installed: List<VendordepsProjectFile>, val beta: VendordepsDownload?)
{
    val name: String get() = library?.name ?: installed.first().vendordeps.name
    val installedVersionText: String? get() = installed.map { it.vendordeps.version.asText }.maxWithOrNull(::compareVersionText)
    val isInstalled: Boolean get() = installed.isNotEmpty()
    val isUpdateAvailable: Boolean
        get() = library != null && installedVersionText != null && compareVersionText(installedVersionText!!, library.latestVersion.asText) < 0
    /** If there is a beta that is newer than the installed version (if installed). */
    val isBetaAvailable: Boolean
        get() = beta != null && (installedVersionText == null || compareVersionText(installedVersionText!!, beta.vendordeps.version.asText) < 0)
    /** If the installed version is newer than the latest version in the vendor repo, i.e. a beta has been installed. */
    val isBetaInstalled: Boolean
        get() = library != null && installedVersionText != null && compareVersionText(installedVersionText!!, library.latestVersion.asText) > 0
}

class VendordepsToolWindowPanel(private val project: Project) : SimpleToolWindowPanel(true, true), Disposable
{
    private val logger = logger<VendordepsToolWindowPanel>()
    private val listModel = DefaultListModel<VendordepsRow>()
    private val list = JBList(listModel)
    private val headerLabel = JBLabel()
    private val commandsConflictLabel = JBLabel(
        "<html>Commands v2 and Commands v3 are both installed. Remove one of them; the build will fail until you do.</html>",
        AllIcons.General.Warning, JBLabel.LEFT)
    /** Shown when the `projectYear` in `wpilib_preferences.json` is not the year of the project's GradleRIO version, so the libraries listed are for the wrong season. */
    private val projectYearMismatchLabel = JBLabel("", AllIcons.General.Warning, JBLabel.LEFT)
    private val installButton = JButton("Install", AllIcons.Actions.Download)
    private val updateButton = JButton("Update", AllIcons.Actions.Refresh)
    private val removeButton = JButton("Remove", AllIcons.General.Remove)

    /** The libraries available from the vendor repo for the project's year; `null` until loaded or if loading failed. */
    @Volatile
    private var repoLibraries: List<VendorRepoLibrary>? = null
    @Volatile
    private var isLoading = false
    /** Betas (i.e. versions newer than in the vendor repo) served by the vendors' `jsonUrl`s, keyed by library UUID. */
    @Volatile
    private var betasByUuid: Map<UUID, VendordepsDownload> = emptyMap()
    @Volatile
    private var isLoadingBetas = false
    /** The year, as an Int, of the project's configured `projectYear`; `null` until loaded or if it could not be determined. */
    @Volatile
    private var projectYearNumber: Int? = null
    /** The configured `projectYear` the libraries were (last) loaded for, so they are reloaded when it changes (e.g. when the project is updated to a new WPILib version). */
    @Volatile
    private var loadedProjectYear: String? = null
    /** Whether the libraries are to be reloaded once the current load completes. */
    @Volatile
    private var reloadRequested = false
    private var showBetas: Boolean
        get() = PropertiesComponent.getInstance().getBoolean(showBetasPropertyKey, false)
        set(value) = PropertiesComponent.getInstance().setValue(showBetasPropertyKey, value, false)

    companion object
    {
        private const val showBetasPropertyKey = "FRC.vendordeps.toolWindow.showBetas"
    }

    init
    {
        list.selectionMode = ListSelectionModel.SINGLE_SELECTION
        list.cellRenderer = VendordepsRowRenderer()
        list.addMouseListener(object : MouseAdapter()
                              {
                                  override fun mouseClicked(e: MouseEvent)
                                  {
                                      if (e.clickCount == 2 && SwingUtilities.isLeftMouseButton(e))
                                          selectedRow()?.let { openVendordepsJson(it) }
                                  }

                                  override fun mousePressed(e: MouseEvent)
                                  {
                                      // Select the row that is right-clicked, so the context menu acts on it
                                      if (SwingUtilities.isRightMouseButton(e))
                                      {
                                          val index = list.locationToIndex(e.point)
                                          if (index >= 0 && list.getCellBounds(index, index)?.contains(e.point) == true) list.selectedIndex = index
                                      }
                                  }
                              })
        PopupHandler.installPopupMenu(list, DefaultActionGroup(InstallAction(), UpdateAction(), InstallBetaAction(), RemoveAction(), Separator.getInstance(), OpenWebsiteAction()),
                                      "FRC.VendordepsToolWindow.Popup")

        val installFromUrlButton = JButton("Install from URL", AllIcons.Actions.AddFile)
        installFromUrlButton.toolTipText = "Install a vendordeps JSON file from a URL into the vendordeps directory"
        installFromUrlButton.addActionListener { installFromUrl() }
        val toolbarPanel = JPanel(FlowLayout(FlowLayout.LEFT, JBUI.scale(6), JBUI.scale(4)))
        toolbarPanel.add(installFromUrlButton)
        setToolbar(toolbarPanel)

        headerLabel.border = JBUI.Borders.empty(4, 6)
        headerLabel.foreground = UIUtil.getContextHelpForeground()
        commandsConflictLabel.border = JBUI.Borders.empty(2, 6, 4, 6)
        commandsConflictLabel.foreground = JBColor.RED
        commandsConflictLabel.isVisible = false
        projectYearMismatchLabel.border = JBUI.Borders.empty(2, 6, 4, 6)
        projectYearMismatchLabel.isVisible = false
        val headerPanel = JPanel(BorderLayout())
        headerPanel.add(headerLabel, BorderLayout.NORTH)
        headerPanel.add(commandsConflictLabel, BorderLayout.CENTER)
        headerPanel.add(projectYearMismatchLabel, BorderLayout.SOUTH)
        val contentPanel = JPanel(BorderLayout())
        contentPanel.add(headerPanel, BorderLayout.NORTH)
        contentPanel.add(ScrollPaneFactory.createScrollPane(list, true), BorderLayout.CENTER)
        contentPanel.add(createButtonsPanel(), BorderLayout.SOUTH)
        setContent(contentPanel)
        list.addListSelectionListener { updateButtons() }

        project.messageBus.connect(this).subscribe(VendordepsService.LISTING_UPDATED_TOPIC, VendordepsListingListener {
            rebuildRows(it)
            // Only newly installed vendordeps' jsonUrls are fetched since the results are cached
            if (showBetas) loadBetas(forceRefresh = false)
        })
        listenForProjectYearChanges()

        loadRepoLibraries(forceRefresh = false)
    }

    /** Reloads the libraries when the project year in the `wpilib_preferences.json` file changes, as the available libraries are for the year. */
    private fun listenForProjectYearChanges()
    {
        project.messageBus.connect(this).subscribe(VirtualFileManager.VFS_CHANGES, object : BulkFileListener
        {
            override fun after(events: List<VFileEvent>)
            {
                if (events.none { it.path.endsWith("/$wpiLibDirName/$wpiLibPreferencesFileName") }) return
                ApplicationManager.getApplication().executeOnPooledThread {
                    if (project.isDisposed) return@executeOnPooledThread
                    val projectYear = project.getConfiguredProjectYear()
                    if (projectYear != loadedProjectYear)
                    {
                        logger.info("[FRC] The project year changed from '$loadedProjectYear' to '$projectYear'. Reloading the vendor libraries.")
                        invokeLater { loadRepoLibraries(forceRefresh = false) }
                    }
                }
            }
        })
    }

    /** Actions for the tool window's options (i.e. "gear" or "more") menu. */
    val optionsActions = DefaultActionGroup(RefreshAction(), ShowBetasToggleAction())

    private fun selectedRow(): VendordepsRow? = list.selectedValue

    private fun createButtonsPanel(): JPanel
    {
        installButton.toolTipText = "Install the latest version of the selected vendor library"
        installButton.addActionListener { selectedRow()?.let { installOrUpdate(it) } }
        updateButton.addActionListener { selectedRow()?.let { installOrUpdate(it) } }
        removeButton.toolTipText = "Remove the selected vendor library from the project"
        removeButton.addActionListener { selectedRow()?.let { remove(it) } }
        val panel = JPanel(FlowLayout(FlowLayout.LEFT, JBUI.scale(6), JBUI.scale(4)))
        panel.border = JBUI.Borders.customLineTop(JBColor.border())
        panel.add(installButton)
        panel.add(updateButton)
        panel.add(removeButton)
        updateButtons()
        return panel
    }

    /** Updates the enabled state of the buttons for the selected row. Update is only enabled when an update is available. */
    private fun updateButtons()
    {
        val row = selectedRow()
        installButton.isEnabled = row.canInstall()
        updateButton.isEnabled = row?.isUpdateAvailable == true
        updateButton.toolTipText = if (row?.isUpdateAvailable == true) "Update to ${row.library!!.latestVersion.asText}" else "No update available"
        removeButton.isEnabled = row?.isInstalled == true
    }

    private fun VendordepsRow?.canInstall(): Boolean = this?.library != null && !this.isInstalled

    private fun loadRepoLibraries(forceRefresh: Boolean)
    {
        if (isLoading)
        {
            reloadRequested = true
            return
        }
        isLoading = true
        list.emptyText.text = "Loading vendor libraries…"
        project.runBackgroundTask("Loading FRC vendor libraries", cancellable = true) { indicator ->
            try
            {
                indicator.text = "Reading project year from wpilib_preferences.json"
                val projectYear = project.getConfiguredProjectYear()
                loadedProjectYear = projectYear
                projectYearNumber = extractProjectYear(projectYear)
                val gradleRioYear = project.findWpiLibProjectRootDirs().firstOrNull()?.let { findGradleRioYear(it.toNioPath()) }
                val yearNumber = projectYearNumber
                invokeLater {
                    projectYearMismatchLabel.isVisible = gradleRioYear != null && yearNumber != null && gradleRioYear != yearNumber
                    projectYearMismatchLabel.text = "<html>This project uses GradleRIO $gradleRioYear, but its projectYear in .wpilib/wpilib_preferences.json " +
                                                    "is '$projectYear', so these are the $yearNumber libraries. Set projectYear to match.</html>"
                }
                if (projectYear == null)
                {
                    invokeLater {
                        repoLibraries = null
                        headerLabel.text = "Project year not found"
                        list.emptyText.text = "Could not determine the project year from .wpilib/wpilib_preferences.json"
                        rebuildRows(VendordepsService.getInstance(project).vendordepsProjectFilesListing)
                    }
                    return@runBackgroundTask
                }
                VendorJsonRepoService.getInstance().getLibraries(projectYear, forceRefresh, indicator)
                    .onSuccess { bundle ->
                        invokeLater {
                            repoLibraries = bundle.libraries
                            headerLabel.text = "Vendor libraries for ${bundle.bundleName}"
                            list.emptyText.text = "No vendor libraries found for ${bundle.bundleName}"
                            rebuildRows(VendordepsService.getInstance(project).vendordepsProjectFilesListing)
                        }
                    }
                    .onFailure { e ->
                        val reason = if (e is HttpRequests.HttpStatusException && e.statusCode == 404) "No vendor libraries are published for '$projectYear'" else "Could not load vendor libraries: ${e.message}"
                        invokeLater {
                            repoLibraries = null
                            headerLabel.text = reason
                            list.emptyText.text = reason
                            rebuildRows(VendordepsService.getInstance(project).vendordepsProjectFilesListing)
                        }
                    }
            }
            finally
            {
                isLoading = false
                if (reloadRequested)
                {
                    reloadRequested = false
                    invokeLater { loadRepoLibraries(forceRefresh = false) }
                }
                else if (showBetas) invokeLater { loadBetas(forceRefresh) }
            }
        }
    }

    /**
     * Loads the betas by fetching the vendordeps from the `jsonUrl` of the installed vendordeps and of the repo libraries. A version
     * is considered a beta if it is newer than the latest version in the vendor repo (or the installed version for libraries not in the repo).
     */
    private fun loadBetas(forceRefresh: Boolean)
    {
        if (isLoadingBetas) return
        // The jsonUrls to check, along with the UUID of the library they are for. Installed vendordeps' jsonUrls take precedence since they
        // may point to a vendor's pre-release channel, but we check the repo library's jsonUrl as well so betas can be seen for libraries not installed
        val urlsToUuid = mutableMapOf<String, UUID>()
        VendordepsService.getInstance(project).vendordepsProjectFilesListing.vendordepsProjectFileList.forEach { installed ->
            installed.vendordeps.jsonUrl?.toString()?.ifBlank { null }?.let { urlsToUuid.putIfAbsent(it, installed.vendordeps.uuid) }
        }
        repoLibraries?.forEach { library -> library.jsonUrl?.let { urlsToUuid.putIfAbsent(it, library.uuid) } }
        if (urlsToUuid.isEmpty()) return

        isLoadingBetas = true
        project.runBackgroundTask("Checking for FRC vendor library betas", cancellable = true) { indicator ->
            try
            {
                indicator.text = "Checking vendors' JSON URLs for beta versions"
                val downloads = VendorJsonRepoService.getInstance().getVendordepsFromJsonUrls(urlsToUuid.keys, forceRefresh, indicator)
                invokeLater {
                    val repoVersions = repoLibraries?.associate { it.uuid to it.latestVersion.asText } ?: emptyMap()
                    val installedVersions = VendordepsService.getInstance(project).vendordepsProjectFilesListing.vendordepsProjectFileMap
                        .mapValues { (_, files) -> files.map { it.vendordeps.version.asText }.maxWith(::compareVersionText) }
                    betasByUuid = downloads.values
                        // Guard against a jsonUrl that serves a different library than the one it was listed for
                        .filter { urlsToUuid[it.url] == it.vendordeps.uuid }
                        // Vendors' "latest" jsonUrls may already serve the next season's (alpha) release, which is not compatible with the project
                        .filter { download -> !isForLaterSeason(download.vendordeps) }
                        .filter { download ->
                            val baseline = repoVersions[download.vendordeps.uuid] ?: installedVersions[download.vendordeps.uuid]
                            baseline == null || compareVersionText(download.vendordeps.version.asText, baseline) > 0
                        }
                        .groupBy { it.vendordeps.uuid }
                        .mapValues { (_, betas) -> betas.maxWith { a, b -> compareVersionText(a.vendordeps.version.asText, b.vendordeps.version.asText) } }
                    rebuildRows(VendordepsService.getInstance(project).vendordepsProjectFilesListing)
                }
            }
            finally
            {
                isLoadingBetas = false
            }
        }
    }

    /** Rebuilds the rows by combining the repo libraries with the vendordeps currently installed in the project. Must be called on the EDT. */
    private fun rebuildRows(listing: VendordepsProjectFilesListing)
    {
        commandsConflictLabel.isVisible = listing.hasCommandsVersionConflict()
        val selectedName = selectedRow()?.name
        val installedByUuid = listing.vendordepsProjectFileMap
        val libraries = repoLibraries ?: emptyList()
        val libraryUuids = libraries.map { it.uuid }.toSet()

        val betas = if (showBetas) betasByUuid else emptyMap()

        val rows = libraries.map { VendordepsRow(it, installedByUuid[it.uuid] ?: emptyList(), betas[it.uuid]) } +
            // Installed vendordeps that are not in the repo, such as WPILibNewCommands, so they can still be seen and removed
            installedByUuid.filterKeys { it !in libraryUuids }.map { (uuid, installed) -> VendordepsRow(null, installed, betas[uuid]) }

        listModel.clear()
        rows.sortedWith(compareBy<VendordepsRow> { !it.isInstalled }.thenBy { it.name.lowercase() }).forEach { listModel.addElement(it) }
        selectedName?.let { name -> (0 until listModel.size()).firstOrNull { listModel[it].name == name }?.let { list.selectedIndex = it } }
        updateButtons()
    }

    /** Finds the project's vendordeps directory, which GradleRIO expects to be alongside the `.wpilib` directory. Must be run in the background. */
    private fun findOrDetermineVendordepsParentDir(): VirtualFile?
    {
        val installedDir = VendordepsService.getInstance(project).vendordepsProjectFilesListing.vendordepsProjectFileList.firstOrNull()?.virtualFile?.parent?.parent
        return installedDir ?: project.findWpiLibProjectRootDirs().firstOrNull() ?: project.guessProjectDir()
    }

    private fun installOrUpdate(row: VendordepsRow)
    {
        val library = row.library ?: return
        installVendordeps("Installing ${library.name} ${library.latestVersion.asText}") { indicator ->
            VendorJsonRepoService.getInstance().downloadVendordeps(library.downloadUrl, indicator).getOrElse { throw it }
        }
    }

    private fun installBeta(row: VendordepsRow)
    {
        val beta = row.beta ?: return
        installVendordeps("Installing ${row.name} ${beta.vendordeps.version.asText}") { beta }
    }

    private fun installFromUrl()
    {
        val url = Messages.showInputDialog(project, "URL of the vendordeps JSON file to install into the '$vendordepsDirName' directory:",
                                           "Install Vendordeps from URL", null, "", object : InputValidator
                                           {
                                               override fun checkInput(inputString: String?): Boolean =
                                                   inputString?.trim()?.let { it.startsWith("https://", ignoreCase = true) || it.startsWith("http://", ignoreCase = true) } == true

                                               override fun canClose(inputString: String?): Boolean = checkInput(inputString)
                                           })?.trim() ?: return
        installVendordeps("Installing vendordeps from $url") { indicator ->
            VendorJsonRepoService.getInstance().downloadVendordeps(url, indicator).getOrElse { throw it }
        }
    }

    /**
     * Obtains, in the background, a vendordeps file via the [download] function, then writes it to the vendordeps directory,
     * replacing any installed version(s) of the same library (i.e. with the same UUID) so there are not duplicates.
     */
    private fun installVendordeps(taskTitle: String, download: (ProgressIndicator) -> VendordepsDownload)
    {
        project.runBackgroundTask(taskTitle, cancellable = true) { indicator ->
            val parentDir = findOrDetermineVendordepsParentDir()
            if (parentDir == null)
            {
                invokeLater { Messages.showErrorDialog(project, "Could not determine the project's root directory.", "Install Vendordeps") }
                return@runBackgroundTask
            }
            val vendordepsDownload = try
            {
                download(indicator)
            }
            catch (e: Exception)
            {
                if (e is ProcessCanceledException) throw e
                logger.info("[FRC] Could not download vendordeps. Cause: $e", e)
                invokeLater { Messages.showErrorDialog(project, "Could not download the vendordeps file: ${e.message}", "Install Vendordeps") }
                return@runBackgroundTask
            }
            val vendordeps = vendordepsDownload.vendordeps
            invokeLater {
                val seasonYear = vendordeps.likelySeasonYear()
                val projectYear = projectYearNumber
                if (seasonYear != null && projectYear != null && seasonYear != projectYear)
                {
                    val answer = Messages.showYesNoDialog(project,
                                                          "${vendordeps.name} ${vendordeps.version.asText} appears to be for the $seasonYear season, but this project is for $projectYear. " +
                                                              "Installing it may break the build. Install anyway?",
                                                          "Install Vendordeps", Messages.getWarningIcon())
                    if (answer != Messages.YES) return@invokeLater
                }
                val fileName = vendordepsDownload.fileName
                val previouslyInstalled = VendordepsService.getInstance(project).vendordepsProjectFilesListing.vendordepsProjectFileMap[vendordeps.uuid] ?: emptyList()
                WriteCommandAction.writeCommandAction(project).withName("Install ${vendordeps.name}").run<Exception> {
                    previouslyInstalled.filter { it.virtualFile.isValid && it.virtualFile.name != fileName }.forEach { it.virtualFile.delete(this) }
                    val vendordepsDir = parentDir.findChild(vendordepsDirName) ?: parentDir.createChildDirectory(this, vendordepsDirName)
                    val file = vendordepsDir.findChild(fileName) ?: vendordepsDir.createChildData(this, fileName)
                    VfsUtil.saveText(file, vendordepsDownload.content)
                }
            }
        }
    }

    /**
     * Opens the vendordeps JSON for the row in an editor: the installed file for an installed library, otherwise
     * a read-only preview of the latest version's JSON from the vendor repository.
     */
    private fun openVendordepsJson(row: VendordepsRow)
    {
        val installedFile = row.installed.maxWithOrNull { a, b -> compareVersionText(a.vendordeps.version.asText, b.vendordeps.version.asText) }?.virtualFile
        if (installedFile != null && installedFile.isValid)
        {
            FileEditorManager.getInstance(project).openFile(installedFile, true)
            return
        }
        val library = row.library ?: return
        project.runBackgroundTask("Downloading ${library.name} vendordeps JSON", cancellable = true) { indicator ->
            VendorJsonRepoService.getInstance().downloadVendordeps(library.downloadUrl, indicator)
                .onSuccess { download ->
                    invokeLater {
                        val previewFile = LightVirtualFile(download.fileName, JsonFileType.INSTANCE, download.content)
                        previewFile.isWritable = false
                        FileEditorManager.getInstance(project).openFile(previewFile, true)
                    }
                }
                .onFailure { e -> invokeLater { Messages.showErrorDialog(project, "Could not download ${library.name}: ${e.message}", "Vendordeps") } }
        }
    }

    private fun remove(row: VendordepsRow)
    {
        if (!row.isInstalled) return
        val answer = Messages.showYesNoDialog(project, "Remove ${row.name} from the project's vendordeps?", "Remove Vendordeps", Messages.getQuestionIcon())
        if (answer != Messages.YES) return
        WriteCommandAction.writeCommandAction(project).withName("Remove ${row.name}").run<Exception> {
            row.installed.filter { it.virtualFile.isValid }.forEach { it.virtualFile.delete(this) }
        }
    }

    private fun isForLaterSeason(vendordeps: Vendordeps): Boolean
    {
        val seasonYear = vendordeps.likelySeasonYear() ?: return false
        val projectYear = projectYearNumber ?: return false
        return seasonYear > projectYear
    }

    private fun invokeLater(action: () -> Unit) =
        ApplicationManager.getApplication().invokeLater({ if (!project.isDisposed) action() }, ModalityState.nonModal())

    override fun dispose() {}

    private inner class RefreshAction : DumbAwareAction("Refresh", "Reload the vendor libraries from the WPILib vendor JSON repository", AllIcons.Actions.Refresh)
    {
        override fun actionPerformed(e: AnActionEvent)
        {
            loadRepoLibraries(forceRefresh = true)
            VendordepsService.getInstance(project).updateVendordepsListing(notifyOnDuplicates = false)
        }

        override fun update(e: AnActionEvent) { e.presentation.isEnabled = !isLoading }
        override fun getActionUpdateThread() = ActionUpdateThread.EDT
    }

    private inner class InstallAction : DumbAwareAction("Install", "Install the latest version of the selected vendor library", AllIcons.Actions.Download)
    {
        override fun actionPerformed(e: AnActionEvent) { selectedRow()?.let { installOrUpdate(it) } }
        override fun update(e: AnActionEvent) { e.presentation.isEnabled = selectedRow().canInstall() }
        override fun getActionUpdateThread() = ActionUpdateThread.EDT
    }

    private inner class UpdateAction : DumbAwareAction("Update", "Update the selected vendor library to the latest version", AllIcons.Actions.Refresh)
    {
        override fun actionPerformed(e: AnActionEvent) { selectedRow()?.let { installOrUpdate(it) } }

        override fun update(e: AnActionEvent)
        {
            val row = selectedRow()
            e.presentation.isEnabled = row?.isUpdateAvailable == true
            e.presentation.text = if (row?.isUpdateAvailable == true) "Update to ${row.library!!.latestVersion.asText}" else "Update"
        }

        override fun getActionUpdateThread() = ActionUpdateThread.EDT
    }

    private inner class InstallBetaAction : DumbAwareAction("Install Beta", "Install the beta (pre-release) version, from the vendor's JSON URL, of the selected vendor library", AllIcons.Actions.Lightning)
    {
        override fun actionPerformed(e: AnActionEvent) { selectedRow()?.let { installBeta(it) } }

        override fun update(e: AnActionEvent)
        {
            val row = selectedRow()
            e.presentation.isEnabledAndVisible = showBetas && row?.isBetaAvailable == true
            e.presentation.text = if (row?.isBetaAvailable == true) "Install Beta ${row.beta!!.vendordeps.version.asText}" else "Install Beta"
        }

        override fun getActionUpdateThread() = ActionUpdateThread.EDT
    }

    private inner class ShowBetasToggleAction : ToggleAction("Show Beta Versions", "Show beta (pre-release) versions available from the vendors' JSON URLs that are newer than in the vendor repository", AllIcons.General.Beta), DumbAware
    {
        override fun isSelected(e: AnActionEvent): Boolean = showBetas

        override fun setSelected(e: AnActionEvent, state: Boolean)
        {
            showBetas = state
            rebuildRows(VendordepsService.getInstance(project).vendordepsProjectFilesListing)
            if (state) loadBetas(forceRefresh = false)
        }

        override fun getActionUpdateThread() = ActionUpdateThread.EDT
    }

    private inner class RemoveAction : DumbAwareAction("Remove", "Remove the selected vendor library from the project", AllIcons.General.Remove)
    {
        override fun actionPerformed(e: AnActionEvent) { selectedRow()?.let { remove(it) } }
        override fun update(e: AnActionEvent) { e.presentation.isEnabled = selectedRow()?.isInstalled == true }
        override fun getActionUpdateThread() = ActionUpdateThread.EDT
    }

    private inner class OpenWebsiteAction : DumbAwareAction("Open Website", "Open the website of the selected vendor library", AllIcons.General.Web)
    {
        override fun actionPerformed(e: AnActionEvent) { selectedRow()?.library?.website?.let { BrowserUtil.browse(it) } }
        override fun update(e: AnActionEvent) { e.presentation.isEnabled = selectedRow()?.library?.website != null }
        override fun getActionUpdateThread() = ActionUpdateThread.EDT
    }
}

private class VendordepsRowRenderer : ListCellRenderer<VendordepsRow>
{
    private val betaAttributes = SimpleTextAttributes(SimpleTextAttributes.STYLE_ITALIC, JBColor(0xB35C00, 0xE6A04C))
    private val rootPanel = JPanel(BorderLayout())
    private val sectionHeader = TitledSeparator()
    private val panel = JPanel(BorderLayout())
    private val title = SimpleColoredComponent()
    private val description = JBLabel()

    init
    {
        rootPanel.add(sectionHeader, BorderLayout.NORTH)
        rootPanel.add(panel, BorderLayout.CENTER)
        panel.border = JBUI.Borders.empty(4, 6)
        title.isOpaque = false
        title.ipad = JBUI.emptyInsets()
        description.font = JBUI.Fonts.smallFont()
        panel.add(title, BorderLayout.NORTH)
        panel.add(description, BorderLayout.CENTER)
    }

    override fun getListCellRendererComponent(list: JList<out VendordepsRow>, value: VendordepsRow, index: Int, isSelected: Boolean, cellHasFocus: Boolean): Component
    {
        // Show a section header above the first row of the installed, and the available, libraries
        val isFirstOfSection = index == 0 || list.model.getElementAt(index - 1).isInstalled != value.isInstalled
        sectionHeader.isVisible = isFirstOfSection
        sectionHeader.text = if (value.isInstalled) "Installed" else "Available"
        rootPanel.background = list.background
        panel.background = UIUtil.getListBackground(isSelected, cellHasFocus)
        val foreground = UIUtil.getListForeground(isSelected, cellHasFocus)
        title.clear()
        title.foreground = foreground
        title.icon = when
        {
            value.isUpdateAvailable -> AllIcons.General.Warning
            value.isInstalled       -> AllIcons.Actions.Checked
            else                    -> AllIcons.Nodes.PpLib
        }
        title.append(value.name, SimpleTextAttributes.REGULAR_BOLD_ATTRIBUTES)
        val library = value.library
        val status = when
        {
            value.isUpdateAvailable -> "  ${value.installedVersionText} → ${library!!.latestVersion.asText}"
            value.isInstalled && library == null -> "  ${value.installedVersionText} (not in vendor repository)"
            value.isBetaInstalled   -> "  ${value.installedVersionText} (beta)"
            value.isInstalled       -> "  ${value.installedVersionText}"
            else                    -> "  ${library!!.latestVersion.asText}"
        }
        title.append(status, if (isSelected) SimpleTextAttributes.REGULAR_ATTRIBUTES else SimpleTextAttributes.GRAYED_ATTRIBUTES)
        if (value.isBetaAvailable)
        {
            title.append("  beta ${value.beta!!.vendordeps.version.asText}", if (isSelected) SimpleTextAttributes.REGULAR_ITALIC_ATTRIBUTES else betaAttributes)
        }

        description.text = library?.description ?: ""
        description.isVisible = description.text.isNotEmpty()
        description.foreground = if (isSelected) foreground else UIUtil.getContextHelpForeground()
        val betaTip = value.beta?.takeIf { value.isBetaAvailable }?.let { "<br><i>Beta ${it.vendordeps.version.asText} available from ${it.url}</i>" } ?: ""
        panel.toolTipText = library?.let { "<html><b>${it.name}</b><br>${it.description}${it.website?.let { w -> "<br>$w" } ?: ""}$betaTip</html>" }
            ?: betaTip.takeIf { it.isNotEmpty() }?.let { "<html><b>${value.name}</b>$it</html>" }
        rootPanel.toolTipText = panel.toolTipText
        return rootPanel
    }
}
