import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import CachyOS.UI

CachyWindow {
    id: root

    title: CachyI18n.i18n("Finder")
    width: CachyTheme.windowWidthSettings
    height: CachyTheme.windowHeightSettings
    minimumWidth: 620
    minimumHeight: 420

    showTrafficLights: true
    showTitleBarDivider: false
    showWindowFrame: true
    contentPadded: false
    sidebarCollapsible: true
    sidebarWidthExpanded: 180

    sidebar: ColumnLayout {
        spacing: CachyTheme.spacingSmall
        anchors.fill: parent
        anchors.margins: CachyTheme.spacingMedium

        CachySidebarItem {
            Layout.fillWidth: true
            text: CachyI18n.i18n("Recents")
            iconName: "clock"
            selected: true
            accentSelected: false
        }

        CachySidebarItem {
            Layout.fillWidth: true
            text: CachyI18n.i18n("Applications")
            iconName: "apps"
            selected: false
            accentSelected: false
        }

        CachySidebarItem {
            Layout.fillWidth: true
            text: CachyI18n.i18n("Desktop")
            iconName: "desktop"
            selected: false
            accentSelected: false
        }

        CachySidebarItem {
            Layout.fillWidth: true
            text: CachyI18n.i18n("Documents")
            iconName: "folder"
            selected: false
            accentSelected: false
        }

        CachySidebarItem {
            Layout.fillWidth: true
            text: CachyI18n.i18n("Downloads")
            iconName: "download"
            selected: false
            accentSelected: false
        }

        Item { Layout.fillHeight: true }
    }

    headerLeading: RowLayout {
        spacing: CachyTheme.spacingSmall

        CachyNavigationButtons {
            canGoBack: false
            canGoForward: false
        }

        CachyHeading {
            text: CachyI18n.i18n("Finder")
            level: 4
            color: CachyPalette.text
            Layout.minimumWidth: 0
        }
    }

    headerCenter: RowLayout {
        spacing: CachyTheme.spacingSmall

        CachySegmentedControl {
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

    Rectangle {
        anchors.fill: parent
        color: CachyPalette.contentBackground

        CachyPlaceholderMessage {
            anchors.centerIn: parent
            iconName: "folder"
            text: CachyI18n.i18n("Carpeta vacía")
            
        }
    }
}
