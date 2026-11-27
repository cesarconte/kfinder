import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import CachyOS.UI

Rectangle {
    id: root

    property string pathUrl: ""
    signal segmentClicked(string segmentUrl)

    height: 26
    color: CachyPalette.isDark ? Qt.rgba(0, 0, 0, 0.22) : Qt.rgba(0, 0, 0, 0.04)

    // Top 1px specular border
    Rectangle {
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: 1
        color: CachyPalette.specularBorder
    }

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

    Row {
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
        anchors.leftMargin: 12
        spacing: 4

        Repeater {
            model: root.segments

            Row {
                anchors.verticalCenter: parent.verticalCenter
                spacing: 4

                Rectangle {
                    id: crumb
                    anchors.verticalCenter: parent.verticalCenter
                    height: 20
                    radius: 4
                    color: crumbHover.hovered ? (CachyPalette.isDark ? Qt.rgba(1, 1, 1, 0.10) : Qt.rgba(0, 0, 0, 0.06)) : "transparent"
                    width: crumbContent.width + 8

                    HoverHandler {
                        id: crumbHover
                        cursorShape: Qt.PointingHandCursor
                    }

                    TapHandler {
                        onTapped: root.segmentClicked(modelData.url)
                    }

                    Row {
                        id: crumbContent
                        anchors.centerIn: parent
                        spacing: 4

                        CachyIcon {
                            anchors.verticalCenter: parent.verticalCenter
                            name: index === 0 ? "drive-harddisk" : "inode-directory"
                            size: 13
                            colored: false
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: modelData.name
                            color: crumbHover.hovered ? CachyPalette.text : CachyPalette.textSecondary
                            font.pixelSize: 11
                            font.weight: index === root.segments.length - 1 ? Font.DemiBold : Font.Normal
                        }
                    }
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    visible: index < root.segments.length - 1
                    text: "›"
                    color: CachyPalette.textMuted
                    font.pixelSize: 11
                }
            }
        }
    }
}
