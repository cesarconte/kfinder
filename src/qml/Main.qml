import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt.labs.platform as Platform
import CachyOS.UI
import org.cesar.kfinder

CachyWindow {
    id: root

    title: fileModel.currentUrl ? (fileModel.currentUrl.toString().split("/").filter(Boolean).pop() || CachyI18n.i18n("Finder")) : CachyI18n.i18n("Finder")
    width: CachyTheme.windowWidthSettings
    height: CachyTheme.windowHeightSettings
    minimumWidth: 620
    minimumHeight: 420

    showTrafficLights: true
    showTitleBarDivider: false
    showWindowFrame: true
    contentPadded: false
    sidebarCollapsible: true
    sidebarWidthExpanded: 200

    readonly property bool isSearching: fileModel.isSearching
    property bool showTerminalPanel: false
    property bool showInformationPanel: false
    property bool isSplitView: false
    property int activePane: 0
    property int gridIconSize: 64
    property var selectedItems: []
    property var selectedUrls: []
    property var activeItem: selectedItems.length > 0 ? selectedItems[0] : null

    function toggleSplitView() {
        root.isSplitView = !root.isSplitView;
        if (root.isSplitView && (!fileModelSplit.currentUrl || fileModelSplit.currentUrl.toString().length === 0)) {
            fileModelSplit.setUrl(fileModel.currentUrl);
        }
    }

    function openSplitView(url) {
        root.isSplitView = true;
        fileModelSplit.setUrl(url);
        root.activePane = 1;
    }

    // Tabs state (macOS Golden Gate Finder Tabs)
    property var tabsList: [
        {
            url: typeof initialUrl !== "undefined" && initialUrl ? initialUrl : "file:///home/cesar",
            title: CachyI18n.i18n("Inicio"),
            iconName: "inode-directory",
            closable: true
        }
    ]
    property int currentTabIndex: 0

    function addNewTab(url) {
        var u = url ? url.toString() : "file:///home/cesar";
        var segs = u.split("/").filter(Boolean);
        var folderName = segs.length > 0 ? decodeURIComponent(segs[segs.length - 1]) : "/";
        if (u === "file:///home/cesar") folderName = CachyI18n.i18n("Inicio");
        var list = [...root.tabsList];
        list.push({
            url: u,
            title: folderName,
            iconName: "inode-directory",
            closable: true
        });
        root.tabsList = list;
        root.currentTabIndex = list.length - 1;
        fileModel.setUrl(u);
    }

    function closeTab(index) {
        if (root.tabsList.length <= 1) {
            root.close();
            return;
        }
        var list = [...root.tabsList];
        list.splice(index, 1);
        root.tabsList = list;
        if (root.currentTabIndex >= list.length) {
            root.currentTabIndex = list.length - 1;
        }
        fileModel.setUrl(root.tabsList[root.currentTabIndex].url);
    }

    function switchTab(index) {
        if (index >= 0 && index < root.tabsList.length) {
            root.currentTabIndex = index;
            fileModel.setUrl(root.tabsList[index].url);
        }
    }

    // History state (Back / Forward)
    property var historyBack: []
    property var historyForward: []
    property bool isHistoryNavigation: false

    function navigateToUrl(urlStr) {
        if (!urlStr || urlStr.length === 0) return;
        var current = fileModel.currentUrl ? fileModel.currentUrl.toString() : "";
        if (urlStr !== current) {
            if (!isHistoryNavigation && current.length > 0) {
                historyBack.push(current);
                historyForward = [];
            }
            fileModel.setUrl(urlStr);
        }
        root.requestActivate();
    }

    function goBack() {
        if (historyBack.length === 0) return;
        var current = fileModel.currentUrl ? fileModel.currentUrl.toString() : "";
        isHistoryNavigation = true;
        historyForward.push(current);
        var prev = historyBack.pop();
        fileModel.setUrl(prev);
        isHistoryNavigation = false;
    }

    function goForward() {
        if (historyForward.length === 0) return;
        var current = fileModel.currentUrl ? fileModel.currentUrl.toString() : "";
        isHistoryNavigation = true;
        historyBack.push(current);
        var next = historyForward.pop();
        fileModel.setUrl(next);
        isHistoryNavigation = false;
    }

    function getUrls(items) {
        var list = [];
        if (items && items.length > 0) {
            for (var i = 0; i < items.length; ++i) {
                if (items[i] && items[i].url) list.push(items[i].url);
            }
        }
        return list;
    }

    function selectAllCurrentView() {
        if (viewSwitcher.currentIndex === 0 && fileGrid) {
            fileGrid.selectAll();
        } else if (viewSwitcher.currentIndex === 1 && fileList) {
            fileList.selectAll();
        }
    }

    function handleFilesDropped(urls, destUrl, mouseX, mouseY) {
        if (!urls || urls.length === 0 || !destUrl) return;
        dropMenu.sourceUrls = urls;
        dropMenu.targetUrl = destUrl;
        dropMenu.popup(mapToItem(root.contentItem, mouseX, mouseY));
    }

    Shortcut {
        sequence: "F4"
        onActivated: root.showTerminalPanel = !root.showTerminalPanel
    }

    Shortcut {
        sequence: "F11"
        onActivated: root.showInformationPanel = !root.showInformationPanel
    }

    Shortcut {
        sequence: "Alt+Ctrl+P"
        onActivated: root.showInformationPanel = !root.showInformationPanel
    }

    Shortcut {
        sequence: "F3"
        onActivated: root.toggleSplitView()
    }

    Shortcut {
        sequence: "Shift+F4"
        onActivated: fileOps.openTerminal(fileModel.currentUrl)
    }

    Shortcut {
        sequence: "Ctrl+N"
        onActivated: fileOps.newWindow(fileModel.currentUrl)
    }

    Shortcut {
        sequence: "Ctrl+Shift+N"
        onActivated: fileOps.createNewFolder(fileModel.currentUrl)
    }

    Shortcut {
        sequence: "Ctrl+C"
        onActivated: {
            var urls = getUrls(root.selectedItems);
            if (urls.length === 0 && root.activeItem && root.activeItem.url) urls = [root.activeItem.url];
            if (urls.length > 0) fileOps.copy(urls);
        }
    }

    Shortcut {
        sequence: "Ctrl+V"
        onActivated: fileOps.paste(fileModel.currentUrl)
    }

    Shortcut {
        sequence: "Ctrl+D"
        onActivated: {
            if (root.activeItem && root.activeItem.url) fileOps.duplicate(root.activeItem.url);
        }
    }

    Shortcut {
        sequence: "Ctrl+Backspace"
        onActivated: {
            var urls = getUrls(root.selectedItems);
            if (urls.length === 0 && root.activeItem && root.activeItem.url) urls = [root.activeItem.url];
            if (urls.length > 0) fileOps.moveToTrash(urls);
        }
    }

    Shortcut {
        sequence: "Delete"
        onActivated: {
            var urls = getUrls(root.selectedItems);
            if (urls.length === 0 && root.activeItem && root.activeItem.url) urls = [root.activeItem.url];
            if (urls.length > 0) fileOps.moveToTrash(urls);
        }
    }

    Shortcut {
        sequence: "Shift+Delete"
        onActivated: {
            var urls = getUrls(root.selectedItems);
            if (urls.length === 0 && root.activeItem && root.activeItem.url) urls = [root.activeItem.url];
            if (urls.length > 0) fileOps.deletePermanently(urls);
        }
    }

    Shortcut {
        sequence: "Alt+Up"
        onActivated: fileModel.goUp()
    }

    Shortcut {
        sequence: "Ctrl+Up"
        onActivated: fileModel.goUp()
    }

    Shortcut {
        sequence: "Space"
        onActivated: {
            if (root.activeItem && root.activeItem.url) fileOps.quickLook(root.activeItem.url);
        }
    }

    Shortcut {
        sequence: "Return"
        onActivated: {
            if (!root.activeItem) return;
            if (settingsManager.keyboardProfile === 0) {
                // Finder profile: Return renames
                renameDialog.targetUrl = root.activeItem.url;
                renameDialog.currentName = root.activeItem.name || "";
                renameDialog.open();
            } else {
                // Dolphin profile: Return opens
                if (root.activeItem.isDirectory) fileModel.setUrl(root.activeItem.url);
                else fileOps.openUrl(root.activeItem.url);
            }
        }
    }

    Shortcut {
        sequence: "F2"
        onActivated: {
            if (root.activeItem && root.activeItem.url) {
                renameDialog.targetUrl = root.activeItem.url;
                renameDialog.currentName = root.activeItem.name || "";
                renameDialog.open();
            }
        }
    }

    Shortcut {
        sequence: "Ctrl+Down"
        onActivated: {
            if (root.activeItem) {
                if (root.activeItem.isDirectory) fileModel.setUrl(root.activeItem.url);
                else fileOps.openUrl(root.activeItem.url);
            }
        }
    }

    Shortcut {
        sequence: "Ctrl+O"
        onActivated: {
            if (root.activeItem) {
                if (root.activeItem.isDirectory) fileModel.setUrl(root.activeItem.url);
                else fileOps.openUrl(root.activeItem.url);
            }
        }
    }

    Shortcut {
        sequence: "Ctrl+T"
        onActivated: root.addNewTab(fileModel.currentUrl)
    }

    Shortcut {
        sequence: "Ctrl+W"
        onActivated: root.closeTab(root.currentTabIndex)
    }

    Shortcut {
        sequence: "Ctrl+Shift+W"
        onActivated: root.close()
    }

    Shortcut {
        sequence: "Ctrl+Tab"
        onActivated: root.switchTab((root.currentTabIndex + 1) % root.tabsList.length)
    }

    Shortcut {
        sequence: "Ctrl+Shift+Tab"
        onActivated: root.switchTab((root.currentTabIndex - 1 + root.tabsList.length) % root.tabsList.length)
    }

    Shortcut {
        sequence: "Alt+Left"
        onActivated: root.goBack()
    }

    Shortcut {
        sequence: "Ctrl+["
        onActivated: root.goBack()
    }

    Shortcut {
        sequence: "Alt+Right"
        onActivated: root.goForward()
    }

    Shortcut {
        sequence: "Ctrl+]"
        onActivated: root.goForward()
    }

    Shortcut {
        sequence: "Ctrl+A"
        onActivated: selectAllCurrentView()
    }

    Shortcut {
        sequence: "Ctrl+I"
        onActivated: {
            var item = root.activeItem || contextMenu.targetItem;
            if (item) {
                getInfoDialog.targetItem = item;
                getInfoDialog.open();
            }
        }
    }

    Shortcut {
        sequence: "Ctrl+,"
        onActivated: settingsDialog.open()
    }

    SettingsManager {
        id: settingsManager
    }

    FileListModel {
        id: fileModel
        showHiddenFiles: settingsManager.showHiddenFiles
        Component.onCompleted: {
            fileModel.setUrl(typeof initialUrl !== "undefined" && initialUrl ? initialUrl : "file:///home/cesar")
        }
    }

    FileListModel {
        id: fileModelSplit
        showHiddenFiles: settingsManager.showHiddenFiles
    }

    Connections {
        target: fileModel
        function onCurrentUrlChanged() {
            if (root.tabsList.length > 0 && root.currentTabIndex >= 0 && root.currentTabIndex < root.tabsList.length) {
                var u = fileModel.currentUrl ? fileModel.currentUrl.toString() : "";
                var segs = u.split("/").filter(Boolean);
                var folderName = segs.length > 0 ? decodeURIComponent(segs[segs.length - 1]) : "/";
                if (u === "file:///home/cesar") folderName = CachyI18n.i18n("Inicio");
                var list = [...root.tabsList];
                list[root.currentTabIndex] = {
                    url: u,
                    title: folderName,
                    iconName: "inode-directory",
                    closable: true
                };
                root.tabsList = list;
            }
        }
    }

    PlacesModel {
        id: placesModel
    }

    FileOperations {
        id: fileOps
    }

    Connections {
        target: fileOps
        function onNewTabRequested(url) {
            root.addNewTab(url)
        }
        function onNewWindowRequested(url) {
            fileOps.newWindow(url)
        }
        function onSplitViewRequested(url) {
            root.openSplitView(url)
        }
        function onRenameRequested(url) {
            var name = (root.activeItem && root.activeItem.name) ? root.activeItem.name : ""
            renameDialog.targetUrl = url
            renameDialog.currentName = name
            renameDialog.open()
        }
    }

    FileContextMenu {
        id: contextMenu
        onOpenRequested: (item) => {
            if (item && item.url) {
                if (item.isDirectory) {
                    fileModel.setUrl(item.url)
                } else {
                    fileOps.openUrl(item.url)
                }
            }
        }
        onOpenWithRequested: (item) => {
            if (item && item.url) fileOps.openWith(item.url)
        }
        onQuickLookRequested: (item) => {
            if (item && item.url) fileOps.quickLook(item.url)
        }
        onGetInfoRequested: (item) => {
            if (item && item.url) {
                getInfoDialog.targetItem = item
                getInfoDialog.open()
            }
        }
        onRenameRequested: (item) => {
            if (item && item.url) {
                renameDialog.targetUrl = item.url
                renameDialog.currentName = item.name || ""
                renameDialog.open()
            }
        }
        onDuplicateRequested: (item) => {
            if (item && item.url) fileOps.duplicate(item.url)
        }
        onCompressRequested: (item) => {
            if (item && item.url) fileOps.compressItems([item.url])
        }
        onCopyRequested: (item) => {
            if (item && item.url) fileOps.copy([item.url])
        }
        onCopyPathRequested: (item) => {
            if (item && item.url) fileOps.copyPath([item.url])
        }
        onOpenTerminalRequested: (item) => {
            if (item && item.url) fileOps.openTerminal(item.isDirectory ? item.url : fileModel.currentUrl)
        }
        onMoveToTrashRequested: (item) => {
            if (item && item.url) fileOps.moveToTrash([item.url])
        }
        onDeletePermanentlyRequested: (item) => {
            if (item && item.url) fileOps.deletePermanently([item.url])
        }
        onTagRequested: (item, color) => {
            if (item && item.url) {
                fileOps.setTag(item.url, color)
                fileModel.refresh()
            }
        }
    }

    DropActionMenu {
        id: dropMenu
        onCopyRequested: (sources, dest) => fileOps.copyItems(sources, dest)
        onMoveRequested: (sources, dest) => fileOps.moveItems(sources, dest)
        onLinkRequested: (sources, dest) => fileOps.linkItems(sources, dest)
    }

    RenameDialog {
        id: renameDialog
        onRenameConfirmed: (target, newName) => fileOps.rename(target, newName)
    }

    SettingsDialog {
        id: settingsDialog
        settings: settingsManager
    }

    EmptyTrashAlert {
        id: emptyTrashDialog
        onConfirmed: fileOps.moveToTrash([]) // empty trash trigger
    }

    GetInfoDialog {
        id: getInfoDialog
        onTagChanged: (color) => {
            if (targetItem && targetItem.url) {
                fileOps.setTag(targetItem.url, color)
                fileModel.refresh()
            }
        }
    }

    GoToFolderDialog {
        id: goToDialog
        onFolderSelected: (path) => {
            var finalUrl = path
            if (path.startsWith("~")) {
                finalUrl = "file:///home/cesar" + path.substring(1)
            } else if (!path.startsWith("file://")) {
                finalUrl = "file://" + path
            }
            fileModel.setUrl(finalUrl)
        }
    }

    Platform.MenuBar {
        id: globalMenuBar

        Platform.Menu {
            title: CachyI18n.i18n("Finder")
            Platform.MenuItem {
                text: CachyI18n.i18n("Acerca de Finder")
                onTriggered: {}
            }
            Platform.MenuSeparator {}
            Platform.MenuItem {
                text: CachyI18n.i18n("Ajustes...")
                shortcut: "Ctrl+,"
                onTriggered: settingsDialog.open()
            }
            Platform.MenuSeparator {}
            Platform.MenuItem {
                text: CachyI18n.i18n("Vaciar papelera...")
                shortcut: "Ctrl+Shift+Backspace"
                onTriggered: {
                    if (settingsManager.confirmEmptyTrash) {
                        emptyTrashDialog.open()
                    } else {
                        fileOps.moveToTrash([])
                    }
                }
            }
        }

        Platform.Menu {
            title: CachyI18n.i18n("Archivo")
            Platform.MenuItem {
                text: CachyI18n.i18n("Nueva pestaña")
                shortcut: "Ctrl+T"
                onTriggered: root.addNewTab(fileModel.currentUrl)
            }
            Platform.MenuItem {
                text: CachyI18n.i18n("Nueva ventana")
                shortcut: "Ctrl+N"
                onTriggered: fileOps.newWindow(fileModel.currentUrl)
            }
            Platform.MenuItem {
                text: CachyI18n.i18n("Nueva carpeta")
                shortcut: "Ctrl+Shift+N"
                onTriggered: fileOps.createNewFolder(fileModel.currentUrl)
            }
            Platform.MenuItem {
                text: CachyI18n.i18n("Nuevo archivo de texto")
                onTriggered: fileOps.createNewFile(fileModel.currentUrl)
            }
            Platform.MenuSeparator {}
            Platform.MenuItem {
                text: CachyI18n.i18n("Obtener información")
                shortcut: "Ctrl+I"
                onTriggered: {
                    var it = root.activeItem || contextMenu.targetItem;
                    if (it) {
                        getInfoDialog.targetItem = it;
                        getInfoDialog.open();
                    }
                }
            }
            Platform.MenuItem {
                text: CachyI18n.i18n("Duplicar")
                shortcut: "Ctrl+D"
                onTriggered: {
                    if (root.activeItem && root.activeItem.url) fileOps.duplicate(root.activeItem.url);
                }
            }
            Platform.MenuSeparator {}
            Platform.MenuItem {
                text: CachyI18n.i18n("Cerrar pestaña")
                shortcut: "Ctrl+W"
                onTriggered: root.closeTab(root.currentTabIndex)
            }
            Platform.MenuItem {
                text: CachyI18n.i18n("Cerrar ventana")
                shortcut: "Ctrl+Shift+W"
                onTriggered: root.close()
            }
        }

        Platform.Menu {
            title: CachyI18n.i18n("Edición")
            Platform.MenuItem {
                text: CachyI18n.i18n("Deshacer")
                shortcut: "Ctrl+Z"
            }
            Platform.MenuItem {
                text: CachyI18n.i18n("Rehacer")
                shortcut: "Ctrl+Shift+Z"
            }
            Platform.MenuSeparator {}
            Platform.MenuItem {
                text: CachyI18n.i18n("Copiar")
                shortcut: "Ctrl+C"
                onTriggered: {
                    var urls = getUrls(root.selectedItems);
                    if (urls.length === 0 && root.activeItem && root.activeItem.url) urls = [root.activeItem.url];
                    if (urls.length > 0) fileOps.copy(urls);
                }
            }
            Platform.MenuItem {
                text: CachyI18n.i18n("Copiar ruta")
                onTriggered: {
                    var urls = getUrls(root.selectedItems);
                    if (urls.length === 0 && root.activeItem && root.activeItem.url) urls = [root.activeItem.url];
                    if (urls.length > 0) fileOps.copyPath(urls);
                }
            }
            Platform.MenuItem {
                text: CachyI18n.i18n("Pegar")
                shortcut: "Ctrl+V"
                onTriggered: fileOps.paste(fileModel.currentUrl)
            }
            Platform.MenuItem {
                text: CachyI18n.i18n("Seleccionar todo")
                shortcut: "Ctrl+A"
                onTriggered: selectAllCurrentView()
            }
        }

        Platform.Menu {
            title: CachyI18n.i18n("Visualización")
            Platform.MenuItem {
                text: CachyI18n.i18n("Como iconos")
                shortcut: "Ctrl+1"
                onTriggered: viewSwitcher.currentIndex = 0
            }
            Platform.MenuItem {
                text: CachyI18n.i18n("Como lista")
                shortcut: "Ctrl+2"
                onTriggered: viewSwitcher.currentIndex = 1
            }
            Platform.MenuItem {
                text: CachyI18n.i18n("Como columnas")
                shortcut: "Ctrl+3"
                onTriggered: viewSwitcher.currentIndex = 2
            }
            Platform.MenuItem {
                text: CachyI18n.i18n("Como galería")
                shortcut: "Ctrl+4"
                onTriggered: viewSwitcher.currentIndex = 3
            }
            Platform.MenuSeparator {}
            Platform.MenuItem {
                text: CachyI18n.i18n("Panel de terminal")
                shortcut: "F4"
                checkable: true
                checked: root.showTerminalPanel
                onTriggered: root.showTerminalPanel = !root.showTerminalPanel
            }
            Platform.MenuItem {
                text: CachyI18n.i18n("Abrir en Konsole")
                shortcut: "Shift+F4"
                onTriggered: fileOps.openTerminal(fileModel.currentUrl)
            }
        }

        Platform.Menu {
            title: CachyI18n.i18n("Ir")
            Platform.MenuItem {
                text: CachyI18n.i18n("Atrás")
                shortcut: "Alt+Left"
                enabled: root.historyBack.length > 0
                onTriggered: root.goBack()
            }
            Platform.MenuItem {
                text: CachyI18n.i18n("Adelante")
                shortcut: "Alt+Right"
                enabled: root.historyForward.length > 0
                onTriggered: root.goForward()
            }
            Platform.MenuItem {
                text: CachyI18n.i18n("Carpeta superior")
                shortcut: "Alt+Up"
                onTriggered: fileModel.goUp()
            }
            Platform.MenuSeparator {}
            Platform.MenuItem {
                text: CachyI18n.i18n("Inicio")
                shortcut: "Ctrl+Shift+H"
                onTriggered: root.navigateToUrl("file:///home/cesar")
            }
            Platform.MenuItem {
                text: CachyI18n.i18n("Descargas")
                shortcut: "Ctrl+Shift+L"
                onTriggered: root.navigateToUrl("file:///home/cesar/Descargas")
            }
            Platform.MenuItem {
                text: CachyI18n.i18n("Documentos")
                shortcut: "Ctrl+Shift+O"
                onTriggered: root.navigateToUrl("file:///home/cesar/Documentos")
            }
            Platform.MenuSeparator {}
            Platform.MenuItem {
                text: CachyI18n.i18n("Ir a la carpeta...")
                shortcut: "Ctrl+Shift+G"
                onTriggered: goToDialog.open()
            }
        }
    }

    sidebar: Flickable {
        anchors.fill: parent
        contentWidth: width
        contentHeight: sidebarColumn.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        ScrollBar.vertical: ScrollBar {
            policy: ScrollBar.AsNeeded
        }

        Column {
            id: sidebarColumn
            width: parent.width
            spacing: 2
            topPadding: 8
            bottomPadding: 16

            ListView {
                id: placesList
                width: parent.width
                implicitHeight: contentHeight
                interactive: false
                model: placesModel

                section.property: "group"
                section.criteria: ViewSection.FullString
                section.delegate: Item {
                    width: placesList.width
                    height: 24
                    visible: section && section.length > 0
                    CachySectionHeader {
                        anchors.left: parent.left
                        anchors.leftMargin: 12
                        anchors.verticalCenter: parent.verticalCenter
                        text: section
                    }
                }

                delegate: Item {
                    width: placesList.width
                    height: 32

                    DropArea {
                        anchors.fill: parent
                        onDropped: (drop) => {
                            if (drop.hasUrls && model.url) {
                                handleFilesDropped(drop.urls, model.url, drop.x, drop.y)
                                drop.acceptProposedAction()
                            }
                        }
                    }

                    CachySidebarItem {
                        anchors.fill: parent
                        anchors.leftMargin: 6
                        anchors.rightMargin: 6
                        text: model.text || ""
                        iconName: model.iconName || "folder"
                        selected: fileModel.currentUrl.toString() === model.url
                        accentSelected: false
                        onClicked: {
                            if (model.url && model.url.length > 0) {
                                root.navigateToUrl(model.url)
                            }
                        }
                    }
                }
            }

            Item {
                width: parent.width
                height: 22
                CachySectionHeader {
                    anchors.left: parent.left
                    anchors.leftMargin: 12
                    anchors.verticalCenter: parent.verticalCenter
                    text: CachyI18n.i18n("Etiquetas")
                }
            }

            ListView {
                id: tagsList
                width: parent.width
                implicitHeight: 7 * 28
                interactive: false
                boundsBehavior: Flickable.StopAtBounds
                model: [
                    { name: CachyI18n.i18n("Rojo"), color: "#ff453a", tag: "red" },
                    { name: CachyI18n.i18n("Naranja"), color: "#ff9f0a", tag: "orange" },
                    { name: CachyI18n.i18n("Amarillo"), color: "#ffd60a", tag: "yellow" },
                    { name: CachyI18n.i18n("Verde"), color: "#30d158", tag: "green" },
                    { name: CachyI18n.i18n("Azul"), color: "#0a84ff", tag: "blue" },
                    { name: CachyI18n.i18n("Púrpura"), color: "#bf5af2", tag: "purple" },
                    { name: CachyI18n.i18n("Gris"), color: "#8e8e93", tag: "gray" }
                ]

                delegate: Rectangle {
                    width: tagsList.width - 12
                    height: 26
                    anchors.horizontalCenter: parent ? parent.horizontalCenter : undefined
                    radius: 6
                    color: tagHover.hovered ? (CachyPalette.isDark ? Qt.rgba(1, 1, 1, 0.08) : Qt.rgba(0, 0, 0, 0.05)) : "transparent"

                    HoverHandler {
                        id: tagHover
                        cursorShape: Qt.PointingHandCursor
                    }

                    TapHandler {
                        onTapped: fileModel.setFilterText(modelData.tag)
                    }

                    Row {
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: parent.left
                        anchors.leftMargin: 8
                        spacing: 10

                        Rectangle {
                            anchors.verticalCenter: parent.verticalCenter
                            width: 10
                            height: 10
                            radius: 5
                            color: modelData.color
                            border.width: 0.5
                            border.color: Qt.rgba(0, 0, 0, 0.20)
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: modelData.name
                            font.pixelSize: 13
                            color: CachyPalette.text
                        }
                    }
                }
            }
        }
    }

    headerLeading: Row {
        spacing: 12
        anchors.verticalCenter: parent.verticalCenter

        CachyNavigationButtons {
            anchors.verticalCenter: parent.verticalCenter
            canGoBack: root.historyBack.length > 0
            canGoForward: root.historyForward.length > 0
            onBackClicked: root.goBack()
            onForwardClicked: root.goForward()
        }

        Row {
            spacing: 6
            anchors.verticalCenter: parent.verticalCenter

            CachyIcon {
                anchors.verticalCenter: parent.verticalCenter
                name: "inode-directory"
                size: 16
                colored: false
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: fileModel.currentUrl ? (fileModel.currentUrl.toString().split("/").filter(Boolean).pop() || "/") : "/"
                font.pixelSize: 13
                font.weight: Font.DemiBold
                color: CachyPalette.text
            }
        }
    }

    headerCenter: Item {
        anchors.centerIn: parent
        width: viewSwitcher.width
        height: viewSwitcher.height

        CachySegmentedControl {
            id: viewSwitcher
            anchors.centerIn: parent
            model: [
                { icon: "grid", text: "", tooltip: CachyI18n.i18n("Como iconos") },
                { icon: "list", text: "", tooltip: CachyI18n.i18n("Como lista") },
                { icon: "table", text: "", tooltip: CachyI18n.i18n("Como columnas") },
                { icon: "eye", text: "", tooltip: CachyI18n.i18n("Como galería") }
            ]
            currentIndex: settingsManager.defaultViewMode
            pillStyle: true
            onCurrentIndexChanged: settingsManager.defaultViewMode = currentIndex
        }
    }

    headerActions: Row {
        spacing: 8
        anchors.verticalCenter: parent.verticalCenter

        CachyToolbarGroup {
            anchors.verticalCenter: parent.verticalCenter
            CachyToolbarButton {
                iconName: "eye"
                tooltipText: CachyI18n.i18n("Panel de información (F11)")
                pillStyle: false
                onClicked: root.showInformationPanel = !root.showInformationPanel
            }
            CachyToolbarButton {
                iconName: "view-split-left-right"
                tooltipText: CachyI18n.i18n("Vista dividida (F3)")
                pillStyle: false
                onClicked: root.toggleSplitView()
            }
            CachyToolbarButton {
                iconName: "share"
                tooltipText: CachyI18n.i18n("Compartir")
                pillStyle: false
                onClicked: {
                    if (root.activeItem && root.activeItem.url) fileOps.openWith(root.activeItem.url)
                }
            }
            CachyToolbarButton {
                iconName: "tag"
                tooltipText: CachyI18n.i18n("Etiquetas")
                pillStyle: false
                onClicked: {
                    if (root.activeItem && root.activeItem.url) {
                        getInfoDialog.targetItem = root.activeItem
                        getInfoDialog.open()
                    }
                }
            }
            CachyToolbarButton {
                iconName: "more-horizontal"
                tooltipText: CachyI18n.i18n("Acciones")
                pillStyle: false
                onClicked: {
                    var urls = root.selectedUrls.length > 0 ? root.selectedUrls : (root.activeItem && root.activeItem.url ? [root.activeItem.url] : [])
                    fileOps.showContextMenu(urls, 100, 100, fileModel.currentUrl)
                }
            }
        }

        CachySearchField {
            id: searchField
            anchors.verticalCenter: parent.verticalCenter
            placeholderText: CachyI18n.i18n("Buscar")
            pillStyle: true
            width: 170
            text: fileModel.filterText
            onTextChanged: fileModel.setFilterText(text)
            onAccepted: fileModel.triggerDeepSearch()
        }
    }

    // Main Content Area with ScopeBar and PathBar
    Rectangle {
        anchors.fill: parent
        color: CachyPalette.contentBackground

        ColumnLayout {
            anchors.fill: parent
            spacing: 0

            // Tabs Bar (macOS Golden Gate Finder Tabs)
            CachyTabBar {
                id: finderTabBar
                Layout.fillWidth: true
                visible: root.tabsList.length > 1
                tabs: root.tabsList
                currentIndex: root.currentTabIndex
                showAddButton: true
                onTabClicked: (index) => root.switchTab(index)
                onTabCloseRequested: (index) => root.closeTab(index)
                onAddTabRequested: root.addNewTab(fileModel.currentUrl)
            }

            // Scope Bar (visible when search is active)
            ScopeBar {
                Layout.fillWidth: true
                visible: fileModel.isSearching || (searchField.text && searchField.text.length > 0)
                currentFolderName: fileModel.currentUrl ? (fileModel.currentUrl.toString().split("/").filter(Boolean).pop() || "/") : "/"
                scopeIndex: fileModel.searchScope
                onScopeChanged: (index) => fileModel.setSearchScope(index)
            }

            // View containers with Split View & Information Panel
            RowLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 0

                // Central Views Container (Supports Split View F3)
                RowLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: 0

                    // Primary Pane
                    Item {
                        Layout.fillWidth: true
                        Layout.fillHeight: true

                        FileGridView {
                            id: fileGrid
                            anchors.fill: parent
                            model: fileModel
                            iconSize: root.gridIconSize
                            currentUrl: fileModel.currentUrl
                            visible: viewSwitcher.currentIndex === 0 && fileModel.count > 0

                            onItemClicked: (item) => {
                                root.activeItem = item
                                root.selectedItems = fileGrid.selectedItems
                                root.selectedUrls = fileGrid.selectedUrls
                            }
                            onItemDoubleClicked: (item) => {
                                if (item.isDirectory) root.navigateToUrl(item.url)
                                else fileOps.openUrl(item.url)
                            }
                            onItemContextMenuRequested: (item, gx, gy) => {
                                root.activeItem = item
                                var urls = root.selectedUrls.length > 0 ? root.selectedUrls : (item && item.url ? [item.url] : [])
                                fileOps.showContextMenu(urls, gx, gy, fileModel.currentUrl)
                            }
                            onBackgroundContextMenuRequested: (gx, gy) => {
                                fileOps.showContextMenu([], gx, gy, fileModel.currentUrl)
                            }
                            onFilesDropped: (urls, destination, x, y) => {
                                handleFilesDropped(urls, destination, x, y)
                            }
                        }

                        FileListView {
                            id: fileList
                            anchors.fill: parent
                            model: fileModel
                            currentUrl: fileModel.currentUrl
                            visible: viewSwitcher.currentIndex === 1 && fileModel.count > 0

                            onItemClicked: (item) => {
                                root.activeItem = item
                                root.selectedItems = fileList.selectedItems
                                root.selectedUrls = fileList.selectedUrls
                            }
                            onItemDoubleClicked: (item) => {
                                if (item.isDirectory) root.navigateToUrl(item.url)
                                else fileOps.openUrl(item.url)
                            }
                            onItemContextMenuRequested: (item, gx, gy) => {
                                root.activeItem = item
                                var urls = root.selectedUrls.length > 0 ? root.selectedUrls : (item && item.url ? [item.url] : [])
                                fileOps.showContextMenu(urls, gx, gy, fileModel.currentUrl)
                            }
                            onBackgroundContextMenuRequested: (gx, gy) => {
                                fileOps.showContextMenu([], gx, gy, fileModel.currentUrl)
                            }
                            onFilesDropped: (urls, destination, x, y) => {
                                handleFilesDropped(urls, destination, x, y)
                            }
                        }

                        FileColumnView {
                            anchors.fill: parent
                            rootUrl: fileModel.currentUrl ? fileModel.currentUrl.toString() : ""
                            visible: viewSwitcher.currentIndex === 2 && fileModel.count > 0

                            onItemDoubleClicked: (item) => {
                                if (item.isDirectory) root.navigateToUrl(item.url)
                                else fileOps.openUrl(item.url)
                            }

                            onItemContextMenuRequested: (item, x, y) => {
                                root.activeItem = item
                                var urls = root.selectedUrls.length > 0 ? root.selectedUrls : (item && item.url ? [item.url] : [])
                                var gp = mapToGlobal(x, y)
                                fileOps.showContextMenu(urls, gp.x, gp.y, fileModel.currentUrl)
                            }
                        }

                        FileGalleryView {
                            anchors.fill: parent
                            model: fileModel
                            visible: viewSwitcher.currentIndex === 3 && fileModel.count > 0

                            onItemDoubleClicked: (item) => {
                                if (item.isDirectory) root.navigateToUrl(item.url)
                                else fileOps.openUrl(item.url)
                            }

                            onQuickLookRequested: (item) => {
                                if (item && item.url) fileOps.quickLook(item.url)
                            }
                        }

                        CachyBusyIndicator {
                            anchors.centerIn: parent
                            running: fileModel.loading
                            visible: running
                        }

                        CachyPlaceholderMessage {
                            anchors.centerIn: parent
                            visible: !fileModel.loading && fileModel.count === 0
                            iconName: "folder"
                            text: CachyI18n.i18n("Carpeta vacía")
                        }
                    }

                    // Split View Divider
                    Rectangle {
                        Layout.fillHeight: true
                        width: 1
                        visible: root.isSplitView
                        color: CachyPalette.divider
                    }

                    // Secondary Pane (Split View F3)
                    Item {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        visible: root.isSplitView

                        FileGridView {
                            id: fileGridSplit
                            anchors.fill: parent
                            model: fileModelSplit
                            iconSize: root.gridIconSize
                            currentUrl: fileModelSplit.currentUrl
                            visible: viewSwitcher.currentIndex === 0 && fileModelSplit.count > 0

                            onItemDoubleClicked: (item) => {
                                if (item.isDirectory) fileModelSplit.setUrl(item.url)
                                else fileOps.openUrl(item.url)
                            }
                            onItemContextMenuRequested: (item, gx, gy) => {
                                fileOps.showContextMenu([item.url], gx, gy, fileModelSplit.currentUrl)
                            }
                            onBackgroundContextMenuRequested: (gx, gy) => {
                                fileOps.showContextMenu([], gx, gy, fileModelSplit.currentUrl)
                            }
                        }

                        FileListView {
                            id: fileListSplit
                            anchors.fill: parent
                            model: fileModelSplit
                            currentUrl: fileModelSplit.currentUrl
                            visible: viewSwitcher.currentIndex === 1 && fileModelSplit.count > 0

                            onItemDoubleClicked: (item) => {
                                if (item.isDirectory) fileModelSplit.setUrl(item.url)
                                else fileOps.openUrl(item.url)
                            }
                            onItemContextMenuRequested: (item, gx, gy) => {
                                fileOps.showContextMenu([item.url], gx, gy, fileModelSplit.currentUrl)
                            }
                        }
                    }
                }

                // Right Side: Information Panel / Inspector (F11 / macOS Preview Pane)
                InformationPanel {
                    id: infoPanel
                    Layout.fillHeight: true
                    visible: root.showInformationPanel
                    targetItem: root.activeItem ? root.activeItem : ({
                        url: fileModel.currentUrl,
                        name: fileModel.currentUrl ? (fileModel.currentUrl.toString().split("/").filter(Boolean).pop() || "/") : "/",
                        isDirectory: true,
                        iconName: "inode-directory"
                    })
                    fileOps: fileOps
                    onCloseRequested: root.showInformationPanel = false
                    onQuickLookRequested: (item) => fileOps.quickLook(item.url)
                    onOpenWithRequested: (item) => fileOps.openWith(item.url)
                    onPropertiesRequested: (item) => fileOps.showProperties(item.url)
                    onTagChanged: (color) => fileModel.refresh()
                }
            }

            // Embedded Terminal Panel (F4)
            TerminalPanel {
                id: terminalPanel
                Layout.fillWidth: true
                visible: root.showTerminalPanel
                workingDirectory: (fileModel.currentUrl && fileModel.currentUrl.toString().startsWith("file://"))
                                  ? fileModel.currentUrl.toString().replace("file://", "")
                                  : ""
                onCloseRequested: root.showTerminalPanel = false
                onOpenExternalRequested: fileOps.openTerminal(fileModel.currentUrl)
            }

            // Bottom Status Bar (Storage & Zoom Slider)
            StatusBar {
                id: bottomStatusBar
                Layout.fillWidth: true
                totalCount: fileModel.count
                selectedCount: root.selectedUrls.length
                storageInfo: fileOps.getStorageInfo(fileModel.currentUrl)
                onZoomChanged: (val) => {
                    root.gridIconSize = val
                }
            }

            // Bottom PathBar
            PathBar {
                Layout.fillWidth: true
                pathUrl: fileModel.currentUrl ? fileModel.currentUrl.toString() : ""
                onSegmentClicked: (url) => fileModel.setUrl(url)
            }
        }
    }
}
