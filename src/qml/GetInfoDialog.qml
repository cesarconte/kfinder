import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import CachyOS.UI

CachyDialog {
    id: root

    property var targetItem: null
    property string activeTagColor: (targetItem && targetItem.tagColor) ? targetItem.tagColor : ""
    signal tagChanged(string color)

    title: targetItem ? (CachyI18n.i18n("Información de ") + (targetItem.name || "")) : CachyI18n.i18n("Obtener información")
    preferredWidth: 440
    showCancelButton: false

    ColumnLayout {
        spacing: CachyTheme.spacingMedium
        width: parent.width

        // Header with Icon, Name, and Kind
        RowLayout {
            spacing: CachyTheme.spacingMedium
            Layout.fillWidth: true

            CachyIcon {
                name: (root.targetItem && root.targetItem.iconName) ? root.targetItem.iconName : "unknown"
                implicitWidth: 48
                implicitHeight: 48
            }

            ColumnLayout {
                spacing: 2
                Layout.fillWidth: true

                CachyHeading {
                    text: (root.targetItem && root.targetItem.name) ? root.targetItem.name : ""
                    level: 4
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }

                CachyLabel {
                    text: (root.targetItem && root.targetItem.isDirectory) ? CachyI18n.i18n("Carpeta") : ((root.targetItem && root.targetItem.mimeType) ? root.targetItem.mimeType : "")
                    color: CachyPalette.textSecondary
                    font.pixelSize: 11
                }

                CachyLabel {
                    text: (root.targetItem && root.targetItem.sizeString) ? root.targetItem.sizeString : ""
                    color: CachyPalette.textMuted
                    font.pixelSize: 11
                }
            }
        }

        // Color Tags Bar
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 36
            radius: 8
            color: CachyPalette.isDark ? Qt.rgba(1, 1, 1, 0.05) : Qt.rgba(0, 0, 0, 0.04)

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: CachyTheme.spacingSmall
                anchors.rightMargin: CachyTheme.spacingSmall
                spacing: 8

                CachyLabel {
                    text: CachyI18n.i18n("Etiqueta:")
                    font.pixelSize: 11
                    color: CachyPalette.textSecondary
                }

                Repeater {
                    model: [
                        { name: "red", color: "#ff453a" },
                        { name: "orange", color: "#ff9f0a" },
                        { name: "yellow", color: "#ffd60a" },
                        { name: "green", color: "#30d158" },
                        { name: "blue", color: "#0a84ff" },
                        { name: "purple", color: "#bf5af2" },
                        { name: "gray", color: "#8e8e93" }
                    ]

                    Rectangle {
                        width: 18
                        height: 18
                        radius: 9
                        color: modelData.color
                        border.width: root.activeTagColor === modelData.name ? 2 : 0
                        border.color: CachyPalette.text

                        HoverHandler {
                            id: tagHover
                            cursorShape: Qt.PointingHandCursor
                        }

                        TapHandler {
                            onTapped: {
                                if (root.activeTagColor === modelData.name) {
                                    root.activeTagColor = ""
                                    root.tagChanged("")
                                } else {
                                    root.activeTagColor = modelData.name
                                    root.tagChanged(modelData.name)
                                }
                            }
                        }
                    }
                }

                Item { Layout.fillWidth: true }
            }
        }

        // Details Card
        CachyCard {
            Layout.fillWidth: true

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: CachyTheme.spacingMedium
                spacing: CachyTheme.spacingSmall

                RowLayout {
                    Layout.fillWidth: true
                    CachyLabel {
                        text: CachyI18n.i18n("Dónde:")
                        color: CachyPalette.textSecondary
                        font.pixelSize: 11
                        Layout.preferredWidth: 80
                    }
                    CachyLabel {
                        text: (root.targetItem && root.targetItem.url) ? root.targetItem.url.toString() : ""
                        elide: Text.ElideMiddle
                        font.pixelSize: 11
                        Layout.fillWidth: true
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    CachyLabel {
                        text: CachyI18n.i18n("Modificado:")
                        color: CachyPalette.textSecondary
                        font.pixelSize: 11
                        Layout.preferredWidth: 80
                    }
                    CachyLabel {
                        text: (root.targetItem && root.targetItem.modifiedDate) ? root.targetItem.modifiedDate.toString() : ""
                        font.pixelSize: 11
                        Layout.fillWidth: true
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    CachyLabel {
                        text: CachyI18n.i18n("Creado:")
                        color: CachyPalette.textSecondary
                        font.pixelSize: 11
                        Layout.preferredWidth: 80
                    }
                    CachyLabel {
                        text: (root.targetItem && root.targetItem.createdDate) ? root.targetItem.createdDate.toString() : ""
                        font.pixelSize: 11
                        Layout.fillWidth: true
                    }
                }
            }
        }

        // Action Buttons
        RowLayout {
            Layout.fillWidth: true
            spacing: CachyTheme.spacingSmall

            CachyButton {
                text: CachyI18n.i18n("Abrir con...")
                pillStyle: true
                font.pixelSize: 11
                onClicked: {
                    if (root.targetItem && root.targetItem.url) {
                        fileOps.openWith(root.targetItem.url)
                    }
                }
            }

            CachyButton {
                text: CachyI18n.i18n("Vista rápida")
                pillStyle: true
                font.pixelSize: 11
                onClicked: {
                    if (root.targetItem && root.targetItem.url) {
                        fileOps.quickLook(root.targetItem.url)
                    }
                }
            }

            Item { Layout.fillWidth: true }

            CachyButton {
                text: CachyI18n.i18n("Más detalles...")
                primary: true
                pillStyle: true
                font.pixelSize: 11
                onClicked: {
                    if (root.targetItem && root.targetItem.url) {
                        fileOps.showProperties(root.targetItem.url)
                        root.close()
                    }
                }
            }
        }
    }
}
