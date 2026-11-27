import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
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

    FileListModel {
        id: fileModel
        Component.onCompleted: {
            fileModel.setUrl("file:///home/cesar")
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
            if (item && item.url) fileOps.showProperties(item.url)
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
            placeholderText: CachyI18n.i18n("Search")
            pillStyle: true
            Layout.preferredWidth: 160
        }
    }

    // Main Content Area with integrated PathBar
    Rectangle {
        anchors.fill: parent
        color: CachyPalette.contentBackground

        ColumnLayout {
            anchors.fill: parent
            spacing: 0

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

            // Bottom PathBar
            PathBar {
                Layout.fillWidth: true
                pathUrl: fileModel.currentUrl ? fileModel.currentUrl.toString() : ""
                onSegmentClicked: (url) => fileModel.setUrl(url)
            }
        }
    }
}
