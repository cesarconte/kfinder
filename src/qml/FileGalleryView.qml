import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import CachyOS.UI

Item {
    id: root

    property var model: null
    property int currentIndex: 0
    signal itemDoubleClicked(var item)
    signal itemContextMenuRequested(var item, real mouseX, real mouseY)
    signal rotateLeftRequested(var item)
    signal quickLookRequested(var item)

    readonly property var currentItem: (model && model.count > root.currentIndex && root.currentIndex >= 0)
                                        ? model.get(root.currentIndex)
                                        : null

    RowLayout {
        anchors.fill: parent
        spacing: 0

        // Main preview area + bottom thumbnail filmstrip
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 0

            // Big preview surface
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true

                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: CachyTheme.spacingMedium

                    CachyIcon {
                        Layout.alignment: Qt.AlignHCenter
                        name: root.currentItem ? (root.currentItem.iconName || "folder") : "folder"
                        size: 160
                        colored: false
                    }

                    CachyHeading {
                        Layout.alignment: Qt.AlignHCenter
                        text: root.currentItem ? (root.currentItem.name || "") : ""
                        level: 3
                        color: CachyPalette.text
                    }
                }
            }

            // Bottom filmstrip of thumbnails
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 84
                color: CachyPalette.isDark ? Qt.rgba(0, 0, 0, 0.25) : Qt.rgba(0, 0, 0, 0.05)
                border.width: 1
                border.color: CachyPalette.hardDividerColor

                ListView {
                    id: filmstrip
                    anchors.fill: parent
                    anchors.margins: CachyTheme.spacingSmall
                    orientation: ListView.Horizontal
                    spacing: CachyTheme.spacingSmall
                    clip: true
                    model: root.model
                    boundsBehavior: Flickable.StopAtBounds

                    delegate: Rectangle {
                        width: 64
                        height: 64
                        radius: CachyTheme.radiusSmall
                        color: root.currentIndex === index
                               ? (CachyPalette.isDark ? Qt.rgba(1, 1, 1, 0.18) : Qt.rgba(0, 0, 0, 0.12))
                               : "transparent"
                        border.width: root.currentIndex === index ? 1 : 0
                        border.color: CachyTheme.accentColor

                        ColumnLayout {
                            anchors.centerIn: parent
                            spacing: 2

                            CachyIcon {
                                Layout.alignment: Qt.AlignHCenter
                                name: model.iconName || "folder"
                                size: 36
                                colored: false
                            }

                            CachyLabel {
                                Layout.alignment: Qt.AlignHCenter
                                text: model.name || ""
                                font.pixelSize: 10
                                elide: Text.ElideMiddle
                                Layout.maximumWidth: 56
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: root.currentIndex = index
                            onDoubleClicked: {
                                var data = root.model.get(index)
                                root.itemDoubleClicked(data)
                            }
                        }
                    }
                }
            }
        }

        // Vertical divider
        Rectangle {
            Layout.fillHeight: true
            Layout.preferredWidth: 1
            color: CachyPalette.hardDividerColor
        }

        // Right metadata & quick actions inspector panel
        Rectangle {
            Layout.fillHeight: true
            Layout.preferredWidth: 260
            color: CachyPalette.sidebarBackground

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: CachyTheme.spacingMedium
                spacing: CachyTheme.spacingMedium

                CachyHeading {
                    text: CachyI18n.i18n("Información")
                    level: 4
                    color: CachyPalette.text
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: CachyTheme.spacingTiny

                    CachyLabel {
                        text: CachyI18n.i18n("Nombre:")
                        font.bold: true
                        color: CachyPalette.textSecondary
                    }
                    CachyLabel {
                        text: root.currentItem ? (root.currentItem.name || "--") : "--"
                        wrapMode: Text.WordWrap
                        Layout.fillWidth: true
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: CachyTheme.spacingTiny

                    CachyLabel {
                        text: CachyI18n.i18n("Tamaño:")
                        font.bold: true
                        color: CachyPalette.textSecondary
                    }
                    CachyLabel {
                        text: root.currentItem ? (root.currentItem.sizeString || "--") : "--"
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: CachyTheme.spacingTiny

                    CachyLabel {
                        text: CachyI18n.i18n("Clase:")
                        font.bold: true
                        color: CachyPalette.textSecondary
                    }
                    CachyLabel {
                        text: root.currentItem ? (root.currentItem.mimeType || "--") : "--"
                        wrapMode: Text.WordWrap
                        Layout.fillWidth: true
                    }
                }

                Item { Layout.fillHeight: true }

                // Quick actions
                CachyHeading {
                    text: CachyI18n.i18n("Acciones rápidas")
                    level: 5
                    color: CachyPalette.text
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: CachyTheme.spacingSmall

                    CachyButton {
                        Layout.fillWidth: true
                        text: CachyI18n.i18n("Vista rápida")
                        iconName: "eye"
                        pillStyle: true
                        onClicked: {
                            if (root.currentItem) root.quickLookRequested(root.currentItem)
                        }
                    }
                }
            }
        }
    }
}
