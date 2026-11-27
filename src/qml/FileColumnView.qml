import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import CachyOS.UI
import org.cesar.kfinder

Item {
    id: root

    property string rootUrl: ""
    signal itemDoubleClicked(var item)
    signal itemContextMenuRequested(var item, real mouseX, real mouseY)

    ListView {
        id: columnList
        anchors.fill: parent
        orientation: ListView.Horizontal
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        model: [rootUrl]

        delegate: Rectangle {
            width: 240
            height: columnList.height
            color: "transparent"
            border.width: 1
            border.color: CachyPalette.hardDividerColor

            FileListModel {
                id: colModel
                currentUrl: modelData
            }

            ListView {
                anchors.fill: parent
                model: colModel
                clip: true
                boundsBehavior: Flickable.StopAtBounds

                delegate: CachyListItem {
                    width: parent.width
                    title: model.name || ""
                    subtitle: model.isDirectory ? "" : (model.sizeString || "")
                    iconName: model.iconName || "folder"
                    showDivider: false
                    onDoubleClicked: {
                        root.itemDoubleClicked({
                            name: model.name,
                            url: model.url,
                            isDirectory: model.isDirectory
                        })
                    }
                    onContextMenuRequested: (x, y) => {
                        root.itemContextMenuRequested({
                            name: model.name,
                            url: model.url,
                            isDirectory: model.isDirectory
                        }, x, y)
                    }
                }
            }
        }
    }
}
