/*
 * SPDX-FileCopyrightText: 2026 CachyOS UI contributors
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * Bottom Status Bar (macOS & Dolphin status bar equivalent).
 * Displays selected item count, volume free storage, and icon zoom slider.
 */

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import CachyOS.UI

Rectangle {
    id: root

    property int totalCount: 0
    property int selectedCount: 0
    property string statusText: ""
    property var storageInfo: ({})
    property alias zoomValue: zoomSlider.value

    signal zoomChanged(real value)

    implicitHeight: 28
    color: CachyPalette.isDark ? Qt.rgba(0.14, 0.14, 0.16, 0.70) : Qt.rgba(0.96, 0.96, 0.98, 0.70)
    border.width: 1
    border.color: CachyPalette.specularBorder

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 12
        anchors.rightMargin: 12
        spacing: 16

        // Left: Item count / Selection status
        Text {
            Layout.alignment: Qt.AlignVCenter
            text: {
                if (root.statusText.length > 0) return root.statusText;
                if (root.selectedCount > 0) {
                    return root.selectedCount === 1
                        ? CachyI18n.i18n("1 elemento seleccionado")
                        : (root.selectedCount + " " + CachyI18n.i18n("elementos seleccionados"));
                }
                return root.totalCount === 1
                    ? CachyI18n.i18n("1 elemento")
                    : (root.totalCount + " " + CachyI18n.i18n("elementos"));
            }
            font.pixelSize: 11
            color: CachyPalette.textMuted
            elide: Text.ElideRight
        }

        Item {
            Layout.fillWidth: true
        }

        // Center/Right: Storage information with capacity meter
        Row {
            Layout.alignment: Qt.AlignVCenter
            spacing: 8
            visible: root.storageInfo && root.storageInfo.freeString !== undefined

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: (root.storageInfo && root.storageInfo.freeString) ? root.storageInfo.freeString : ""
                font.pixelSize: 11
                color: CachyPalette.textMuted
            }

            // Slim progress bar for storage capacity
            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: 60
                height: 5
                radius: 2.5
                color: CachyPalette.isDark ? Qt.rgba(1, 1, 1, 0.15) : Qt.rgba(0, 0, 0, 0.12)

                Rectangle {
                    anchors.left: parent.left
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    width: parent.width * Math.max(0.0, Math.min(1.0, (root.storageInfo && root.storageInfo.percentUsed) ? root.storageInfo.percentUsed : 0.0))
                    radius: 2.5
                    color: CachyTheme.accentColor
                }
            }
        }

        // Separator between storage and zoom slider
        Rectangle {
            Layout.alignment: Qt.AlignVCenter
            width: 1
            height: 14
            color: CachyPalette.divider
        }

        // Right: Icon Zoom Slider (Dolphin & Finder parity)
        Row {
            Layout.alignment: Qt.AlignVCenter
            spacing: 6

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: "—"
                font.pixelSize: 10
                font.weight: Font.Bold
                color: CachyPalette.textMuted
            }

            Slider {
                id: zoomSlider
                anchors.verticalCenter: parent.verticalCenter
                implicitWidth: 80
                from: 40
                to: 128
                value: 64
                stepSize: 4

                onValueChanged: root.zoomChanged(value)
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: "+"
                font.pixelSize: 12
                font.weight: Font.Bold
                color: CachyPalette.textMuted
            }
        }
    }
}
