/*
 * SPDX-FileCopyrightText: 2026 CachyOS UI contributors
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * Information Panel / Inspector (macOS Preview Pane & Dolphin F11 equivalent).
 * Provides full metadata inspection, tags, 5-star rating, and comments via KFileMetaData.
 */

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import CachyOS.UI

Rectangle {
    id: root

    property var targetItem: null
    property var metadata: ({})
    property var fileOps: null

    signal closeRequested()
    signal openWithRequested(var item)
    signal quickLookRequested(var item)
    signal propertiesRequested(var item)
    signal tagChanged(string color)

    implicitWidth: 280
    color: CachyPalette.isDark ? Qt.rgba(0.12, 0.12, 0.14, 0.85) : Qt.rgba(0.97, 0.97, 0.98, 0.85)
    border.width: 1
    border.color: CachyPalette.specularBorder

    onTargetItemChanged: {
        updateMetadata();
    }

    function updateMetadata() {
        if (targetItem && targetItem.url && fileOps) {
            root.metadata = fileOps.getMetadata(targetItem.url);
        } else {
            root.metadata = ({});
        }
    }

    Flickable {
        anchors.fill: parent
        anchors.margins: 14
        contentWidth: width
        contentHeight: contentCol.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        ScrollBar.vertical: ScrollBar {
            policy: ScrollBar.AsNeeded
        }

        ColumnLayout {
            id: contentCol
            width: parent.width
            spacing: 14

            // Header with Close Button
            RowLayout {
                Layout.fillWidth: true

                Text {
                    Layout.fillWidth: true
                    text: CachyI18n.i18n("Información")
                    font.pixelSize: 14
                    font.weight: Font.DemiBold
                    color: CachyPalette.text
                }

                CachyButton {
                    text: "✕"
                    flat: true
                    onClicked: root.closeRequested()
                }
            }

            // Big Preview / Icon
            Item {
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredWidth: 120
                Layout.preferredHeight: 120

                Rectangle {
                    anchors.fill: parent
                    radius: 12
                    color: CachyPalette.isDark ? Qt.rgba(1, 1, 1, 0.04) : Qt.rgba(0, 0, 0, 0.03)
                    border.width: 1
                    border.color: CachyPalette.specularBorder

                    CachyIcon {
                        anchors.centerIn: parent
                        size: 96
                        name: (root.metadata && root.metadata.iconName) ? root.metadata.iconName : "inode-directory"
                        colored: false
                    }
                }
            }

            // File / Folder Title
            Text {
                Layout.fillWidth: true
                text: (root.metadata && root.metadata.name) ? root.metadata.name : (root.targetItem ? (root.targetItem.name || "") : "")
                font.pixelSize: 15
                font.weight: Font.Bold
                color: CachyPalette.text
                horizontalAlignment: Text.AlignHCenter
                elide: Text.ElideMiddle
                maximumLineCount: 2
                wrapMode: Text.Wrap
            }

            // Metadata Attributes Card
            Rectangle {
                Layout.fillWidth: true
                radius: 10
                color: CachyPalette.cardBackground
                border.width: 1
                border.color: CachyPalette.specularBorder
                implicitHeight: attrGrid.implicitHeight + 16

                GridLayout {
                    id: attrGrid
                    anchors.fill: parent
                    anchors.margins: 10
                    columns: 2
                    rowSpacing: 8
                    columnSpacing: 10

                    Text {
                        text: CachyI18n.i18n("Tipo:")
                        font.pixelSize: 12
                        font.weight: Font.Medium
                        color: CachyPalette.textMuted
                        Layout.alignment: Qt.AlignLeft | Qt.AlignTop
                    }
                    Text {
                        text: (root.metadata && root.metadata.type) ? root.metadata.type : "--"
                        font.pixelSize: 12
                        color: CachyPalette.text
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                    }

                    Text {
                        text: CachyI18n.i18n("Tamaño:")
                        font.pixelSize: 12
                        font.weight: Font.Medium
                        color: CachyPalette.textMuted
                        Layout.alignment: Qt.AlignLeft | Qt.AlignTop
                    }
                    Text {
                        text: (root.metadata && root.metadata.size) ? root.metadata.size : "--"
                        font.pixelSize: 12
                        color: CachyPalette.text
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                    }

                    Text {
                        text: CachyI18n.i18n("Modificado:")
                        font.pixelSize: 12
                        font.weight: Font.Medium
                        color: CachyPalette.textMuted
                        Layout.alignment: Qt.AlignLeft | Qt.AlignTop
                    }
                    Text {
                        text: (root.metadata && root.metadata.modified) ? root.metadata.modified : "--"
                        font.pixelSize: 12
                        color: CachyPalette.text
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                    }

                    Text {
                        text: CachyI18n.i18n("Accedido:")
                        font.pixelSize: 12
                        font.weight: Font.Medium
                        color: CachyPalette.textMuted
                        Layout.alignment: Qt.AlignLeft | Qt.AlignTop
                    }
                    Text {
                        text: (root.metadata && root.metadata.accessed) ? root.metadata.accessed : "--"
                        font.pixelSize: 12
                        color: CachyPalette.text
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                    }

                    Text {
                        text: CachyI18n.i18n("Creado:")
                        font.pixelSize: 12
                        font.weight: Font.Medium
                        color: CachyPalette.textMuted
                        Layout.alignment: Qt.AlignLeft | Qt.AlignTop
                    }
                    Text {
                        text: (root.metadata && root.metadata.created) ? root.metadata.created : "--"
                        font.pixelSize: 12
                        color: CachyPalette.text
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                    }
                }
            }

            // Tags Section (Interactive Colored Dots)
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 6

                Text {
                    text: CachyI18n.i18n("Etiquetas:")
                    font.pixelSize: 12
                    font.weight: Font.Medium
                    color: CachyPalette.textMuted
                }

                Row {
                    spacing: 8
                    Layout.alignment: Qt.AlignLeft

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
                            id: tagCircle
                            width: 16
                            height: 16
                            radius: 8
                            color: modelData.color
                            border.width: (root.metadata && root.metadata.tagColor === modelData.name) ? 2 : 0.5
                            border.color: (root.metadata && root.metadata.tagColor === modelData.name) ? CachyPalette.text : Qt.rgba(0,0,0,0.2)

                            scale: tagHover.hovered ? 1.2 : 1.0
                            Behavior on scale { NumberAnimation { duration: 100 } }

                            HoverHandler {
                                id: tagHover
                                cursorShape: Qt.PointingHandCursor
                            }

                            TapHandler {
                                onTapped: {
                                    var newTag = (root.metadata && root.metadata.tagColor === modelData.name) ? "" : modelData.name;
                                    if (root.targetItem && root.targetItem.url && root.fileOps) {
                                        root.fileOps.setTag(root.targetItem.url, newTag);
                                        root.updateMetadata();
                                        root.tagChanged(newTag);
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // Star Rating Section (Interactive 5 Stars via Baloo / KFileMetaData)
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 6

                Text {
                    text: CachyI18n.i18n("Valoración:")
                    font.pixelSize: 12
                    font.weight: Font.Medium
                    color: CachyPalette.textMuted
                }

                Row {
                    spacing: 4

                    Repeater {
                        model: 5
                        Text {
                            id: starText
                            property int starVal: index + 1
                            property int currentRating: (root.metadata && root.metadata.rating) ? root.metadata.rating : 0

                            text: starVal <= currentRating ? "★" : "☆"
                            font.pixelSize: 18
                            color: starVal <= currentRating ? "#FFCC00" : CachyPalette.textMuted

                            HoverHandler {
                                cursorShape: Qt.PointingHandCursor
                            }

                            TapHandler {
                                onTapped: {
                                    var nextRating = (starText.currentRating === starText.starVal) ? 0 : starText.starVal;
                                    if (root.targetItem && root.targetItem.url && root.fileOps) {
                                        root.fileOps.setRating(root.targetItem.url, nextRating);
                                        root.updateMetadata();
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // Comment Section (Baloo / UserMetaData)
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 6

                Text {
                    text: CachyI18n.i18n("Comentario:")
                    font.pixelSize: 12
                    font.weight: Font.Medium
                    color: CachyPalette.textMuted
                }

                CachyTextArea {
                    id: commentArea
                    Layout.fillWidth: true
                    implicitHeight: 64
                    placeholderText: CachyI18n.i18n("Escribe un comentario...")
                    text: (root.metadata && root.metadata.comment) ? root.metadata.comment : ""

                    onEditingFinished: {
                        if (root.targetItem && root.targetItem.url && root.fileOps) {
                            root.fileOps.setComment(root.targetItem.url, text);
                        }
                    }
                }
            }

            // Action Buttons
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 8
                Layout.topMargin: 6

                CachyButton {
                    Layout.fillWidth: true
                    text: CachyI18n.i18n("Vista rápida")
                    iconName: "eye"
                    onClicked: {
                        if (root.targetItem && root.targetItem.url) {
                            root.quickLookRequested(root.targetItem);
                        }
                    }
                }

                CachyButton {
                    Layout.fillWidth: true
                    text: CachyI18n.i18n("Propiedades avanzadas")
                    iconName: "document-properties"
                    onClicked: {
                        if (root.targetItem && root.targetItem.url) {
                            root.propertiesRequested(root.targetItem);
                        }
                    }
                }
            }
        }
    }
}
