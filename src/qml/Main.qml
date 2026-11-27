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

    Shortcut {
        sequence: "F4"
        onActivated: root.showTerminalPanel = !root.showTerminalPanel
    }

    Shortcut {
        sequence: "Shift+F4"
        onActivated: fileOps.openTerminal(fileModel.currentUrl)
    }

    Shortcut {
        sequence: "Ctrl+I"
        onActivated: {
            if (contextMenu.targetItem) {
                getInfoDialog.targetItem = contextMenu.targetItem
                getInfoDialog.open()
            }
        }
    }

    FileListModel {
        id: fileModel
        Component.onCompleted: {
            fileModel.setUrl(typeof initialUrl !== "undefined" && initialUrl ? initialUrl : "file:///home/cesar")
        }
    }

    function navigateToUrl(urlStr) {
        if (urlStr && urlStr.length > 0) {
            fileModel.setUrl(urlStr)
            root.requestActivate()
        }
    }

    PlacesModel {
        id: placesModel
    }

    FileOperations {
        id: fileOps
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
        onQuickLookRequested: (item) => {
            if (item && item.url) fileOps.quickLook(item.url)
        }
        onGetInfoRequested: (item) => {
            if (item && item.url) {
                getInfoDialog.targetItem = item
                getInfoDialog.open()
            }
        }
        onMoveToTrashRequested: (item) => {
            if (item && item.url) fileOps.moveToTrash([item.url])
        }
        onCopyRequested: (item) => {
            if (item && item.url) fileOps.copy([item.url])
        }
        onDuplicateRequested: (item) => {
            if (item && item.url) fileOps.duplicate(item.url)
        }
    }

    SettingsDialog {
        id: settingsDialog
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
                onTriggered: {}
            }
            Platform.MenuSeparator {}
            Platform.MenuItem {
                text: CachyI18n.i18n("Vaciar papelera...")
                shortcut: "Ctrl+Shift+Backspace"
                onTriggered: {}
            }
        }

        Platform.Menu {
            title: CachyI18n.i18n("Archivo")
            Platform.MenuItem {
                text: CachyI18n.i18n("Nueva ventana")
                shortcut: "Ctrl+N"
                onTriggered: {}
            }
            Platform.MenuItem {
                text: CachyI18n.i18n("Nueva carpeta")
                shortcut: "Ctrl+Shift+N"
                onTriggered: {}
            }
            Platform.MenuSeparator {}
            Platform.MenuItem {
                text: CachyI18n.i18n("Cerrar ventana")
                shortcut: "Ctrl+W"
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
            }
            Platform.MenuItem {
                text: CachyI18n.i18n("Pegar")
                shortcut: "Ctrl+V"
                onTriggered: fileOps.paste(fileModel.currentUrl)
            }
            Platform.MenuItem {
                text: CachyI18n.i18n("Seleccionar todo")
                shortcut: "Ctrl+A"
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
                text: CachyI18n.i18n("Carpeta superior")
                shortcut: "Ctrl+Up"
                onTriggered: fileModel.goUp()
            }
            Platform.MenuItem {
                text: CachyI18n.i18n("Inicio")
                shortcut: "Ctrl+Shift+H"
                onTriggered: fileModel.setUrl("file:///home/cesar")
            }
            Platform.MenuItem {
                text: CachyI18n.i18n("Descargas")
                shortcut: "Ctrl+Shift+L"
                onTriggered: fileModel.setUrl("file:///home/cesar/Descargas")
            }
            Platform.MenuItem {
                text: CachyI18n.i18n("Documentos")
                shortcut: "Ctrl+Shift+O"
                onTriggered: fileModel.setUrl("file:///home/cesar/Documentos")
            }
            Platform.MenuSeparator {}
            Platform.MenuItem {
                text: CachyI18n.i18n("Ir a la carpeta...")
                shortcut: "Ctrl+Shift+G"
                onTriggered: goToDialog.open()
            }
        }
    }

    sidebar: ColumnLayout {
        spacing: 0
        anchors.fill: parent

        ListView {
            id: placesList
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            model: placesModel
            boundsBehavior: Flickable.StopAtBounds

            section.property: "group"
            section.criteria: ViewSection.FullString
            section.delegate: Item {
                width: placesList.width
                height: 28
                visible: section && section.length > 0
                CachySectionHeader {
                    anchors.left: parent.left
                    anchors.leftMargin: 12
                    anchors.verticalCenter: parent.verticalCenter
                    text: section
                }
            }

            delegate: CachySidebarItem {
                width: placesList.width
                text: model.text || ""
                iconName: model.iconName || "folder"
                selected: fileModel.currentUrl.toString() === model.url
                accentSelected: false
                onClicked: {
                    if (model.url && model.url.length > 0) {
                        fileModel.setUrl(model.url)
                    }
                }
            }
        }

        Item {
            Layout.fillWidth: true
            height: 24
            CachySectionHeader {
                anchors.left: parent.left
                anchors.leftMargin: 12
                anchors.verticalCenter: parent.verticalCenter
                text: CachyI18n.i18n("Etiquetas")
            }
        }

        ListView {
            id: tagsList
            Layout.fillWidth: true
            implicitHeight: 7 * 32
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

            delegate: CachySidebarItem {
                width: tagsList.width
                text: modelData.name
                circularIconBadge: true
                iconColor: modelData.color
                iconGlyph: "●"
                selected: false
                onClicked: {
                    fileModel.setFilterText(modelData.tag)
                }
            }
        }
    }

    headerLeading: RowLayout {
        spacing: CachyTheme.spacingSmall

        CachyNavigationButtons {
            canGoBack: true
            canGoForward: false
            onBackClicked: fileModel.goUp()
        }

        CachyHeading {
            text: fileModel.currentUrl ? (fileModel.currentUrl.toString().split("/").filter(Boolean).pop() || "/") : "/"
            level: 4
            color: CachyPalette.text
            Layout.minimumWidth: 0
        }
    }

    headerCenter: RowLayout {
        spacing: CachyTheme.spacingSmall

        CachySegmentedControl {
            id: viewSwitcher
            model: [
                { icon: "grid", text: "" },
                { icon: "list", text: "" },
                { icon: "table", text: "" },
                { icon: "eye", text: "" }
            ]
            currentIndex: 0
            pillStyle: true
        }
    }

    headerActions: RowLayout {
        spacing: CachyTheme.spacingSmall

        CachyToolbarGroup {
            CachyToolbarButton {
                iconName: "share"
                tooltipText: CachyI18n.i18n("Share")
                pillStyle: false
            }
            CachyToolbarButton {
                iconName: "tag"
                tooltipText: CachyI18n.i18n("Edit tags")
                pillStyle: false
            }
            CachyToolbarButton {
                iconName: "more-horizontal"
                tooltipText: CachyI18n.i18n("Action")
                pillStyle: false
            }
        }

        CachySearchField {
            id: searchField
            placeholderText: CachyI18n.i18n("Search")
            pillStyle: true
            Layout.preferredWidth: 160
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

            // Scope Bar (visible when search is active)
            ScopeBar {
                Layout.fillWidth: true
                visible: fileModel.isSearching || (searchField.text && searchField.text.length > 0)
                currentFolderName: fileModel.currentUrl ? (fileModel.currentUrl.toString().split("/").filter(Boolean).pop() || "/") : "/"
                scopeIndex: fileModel.searchScope
                onScopeChanged: (index) => fileModel.setSearchScope(index)
            }

            // View containers
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true

                // 1. Icon Grid View
                GridView {
                    id: fileGrid
                    anchors.fill: parent
                    anchors.margins: CachyTheme.spacingMedium
                    clip: true
                    cellWidth: 110
                    cellHeight: 120
                    model: fileModel
                    visible: viewSwitcher.currentIndex === 0 && fileModel.count > 0

                    delegate: CachyGridItem {
                        width: fileGrid.cellWidth - 10
                        height: fileGrid.cellHeight - 10
                        title: model.name || ""
                        iconName: model.iconName || "unknown"
                        badgeText: model.isDirectory ? "" : (model.sizeString || "")
                        selected: false

                        onDoubleClicked: {
                            if (model.isDirectory) {
                                fileModel.setUrl(model.url)
                            } else {
                                fileOps.openUrl(model.url)
                            }
                        }

                        onContextMenuRequested: (x, y) => {
                            contextMenu.targetItem = {
                                name: model.name,
                                url: model.url,
                                isDirectory: model.isDirectory
                            }
                            contextMenu.popup(mapToItem(root.contentItem, x, y))
                        }
                    }
                }

                // 2. Details List View
                FileListView {
                    anchors.fill: parent
                    model: fileModel
                    visible: viewSwitcher.currentIndex === 1 && fileModel.count > 0

                    onItemDoubleClicked: (item) => {
                        if (item.isDirectory) {
                            fileModel.setUrl(item.url)
                        } else {
                            fileOps.openUrl(item.url)
                        }
                    }

                    onItemContextMenuRequested: (item, x, y) => {
                        contextMenu.targetItem = item
                        contextMenu.popup(mapToItem(root.contentItem, x, y))
                    }
                }

                // 3. Columns View (Miller Columns)
                FileColumnView {
                    anchors.fill: parent
                    rootUrl: fileModel.currentUrl ? fileModel.currentUrl.toString() : ""
                    visible: viewSwitcher.currentIndex === 2 && fileModel.count > 0

                    onItemDoubleClicked: (item) => {
                        if (item.isDirectory) {
                            fileModel.setUrl(item.url)
                        } else {
                            fileOps.openUrl(item.url)
                        }
                    }

                    onItemContextMenuRequested: (item, x, y) => {
                        contextMenu.targetItem = item
                        contextMenu.popup(mapToItem(root.contentItem, x, y))
                    }
                }

                // 4. Gallery View
                FileGalleryView {
                    anchors.fill: parent
                    model: fileModel
                    visible: viewSwitcher.currentIndex === 3 && fileModel.count > 0

                    onItemDoubleClicked: (item) => {
                        if (item.isDirectory) {
                            fileModel.setUrl(item.url)
                        } else {
                            fileOps.openUrl(item.url)
                        }
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

            // Bottom PathBar
            PathBar {
                Layout.fillWidth: true
                pathUrl: fileModel.currentUrl ? fileModel.currentUrl.toString() : ""
                onSegmentClicked: (url) => fileModel.setUrl(url)
            }
        }
    }
}
