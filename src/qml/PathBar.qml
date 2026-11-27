import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import CachyOS.UI

Rectangle {
    id: root

    property string pathUrl: ""
    signal segmentClicked(string segmentUrl)

    height: 26
    color: CachyPalette.isDark ? Qt.rgba(0, 0, 0, 0.35) : Qt.rgba(0, 0, 0, 0.05)
    border.width: 1
    border.color: CachyPalette.hardDividerColor

    readonly property var segments: {
        var str = root.pathUrl.replace("file://", "")
        if (!str || str.length === 0) return []
        var parts = str.split("/").filter(Boolean)
        var result = []
        var accum = ""
        for (var i = 0; i < parts.length; ++i) {
            accum += "/" + parts[i]
            result.push({
                name: parts[i],
                url: "file://" + accum
            })
        }
        return result
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: CachyTheme.spacingSmall
        anchors.rightMargin: CachyTheme.spacingSmall
        spacing: CachyTheme.spacingTiny

        CachyIcon {
            name: "folder"
            size: 14
            colored: false
        }

        Repeater {
            model: root.segments

            RowLayout {
                spacing: CachyTheme.spacingTiny

                CachyLabel {
                    text: modelData.name
                    color: CachyPalette.textSecondary
                    font.pixelSize: 11

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        hoverEnabled: true
                        onClicked: root.segmentClicked(modelData.url)
                    }
                }

                CachyLabel {
                    visible: index < root.segments.length - 1
                    text: "›"
                    color: CachyPalette.textMuted
                    font.pixelSize: 11
                }
            }
        }

        Item { Layout.fillWidth: true }
    }
}
