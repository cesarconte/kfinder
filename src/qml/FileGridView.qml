import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import CachyOS.UI

Item {
    id: root

    property var model: null
    property url currentUrl: ""
    property var selectedUrls: []
    property var selectedItems: []
    property int currentIndex: -1
    property int iconSize: 64

    signal itemClicked(var item)
    signal itemDoubleClicked(var item)
    signal itemContextMenuRequested(var item, real globalX, real globalY)
    signal backgroundContextMenuRequested(real globalX, real globalY)
    signal filesDropped(var urls, url destination, real mouseX, real mouseY)

    function selectAll() {
        if (!model) return;
        var urls = [];
        var items = [];
        for (var i = 0; i < model.count; ++i) {
            var it = model.get(i);
            urls.push(it.url.toString());
            items.push(it);
        }
        root.selectedUrls = urls;
        root.selectedItems = items;
    }

    function clearSelection() {
        root.selectedUrls = [];
        root.selectedItems = [];
        root.currentIndex = -1;
    }

    function isSelected(urlStr) {
        return root.selectedUrls.indexOf(urlStr) !== -1;
    }

    function toggleSelect(item, isMulti) {
        var urlStr = item.url.toString();
        var urls = [...root.selectedUrls];
        var items = [...root.selectedItems];
        if (isMulti) {
            var idx = urls.indexOf(urlStr);
            if (idx !== -1) {
                urls.splice(idx, 1);
                items.splice(idx, 1);
            } else {
                urls.push(urlStr);
                items.push(item);
            }
        } else {
            urls = [urlStr];
            items = [item];
        }
        root.selectedUrls = urls;
        root.selectedItems = items;
    }

    // View Background Drop Area
    DropArea {
        id: bgDropArea
        anchors.fill: parent
        onDropped: (drop) => {
            if (drop.hasUrls) {
                root.filesDropped(drop.urls, root.currentUrl, drop.x, drop.y);
                drop.acceptProposedAction();
            }
        }
    }

    // Rubberband Selection Box
    Rectangle {
        id: rubberBand
        visible: false
        z: 99
        color: CachyTheme.withAlpha(CachyTheme.accentColor, 0.20)
        border.color: CachyTheme.accentColor
        border.width: 1
        radius: 3
    }

    // Background interaction & rubberband
    MouseArea {
        id: bgMouseArea
        anchors.fill: parent
        propagateComposedEvents: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton

        property real startX: 0
        property real startY: 0
        property bool selecting: false

        onPressed: (mouse) => {
            if (mouse.button === Qt.RightButton) {
                var gp = bgMouseArea.mapToGlobal(mouse.x, mouse.y);
                root.backgroundContextMenuRequested(gp.x, gp.y);
            } else {
                startX = mouse.x;
                startY = mouse.y;
                selecting = true;
                rubberBand.x = startX;
                rubberBand.y = startY;
                rubberBand.width = 0;
                rubberBand.height = 0;
                rubberBand.visible = true;
                if (!(mouse.modifiers & Qt.ControlModifier) && !(mouse.modifiers & Qt.ShiftModifier)) {
                    root.clearSelection();
                }
            }
        }

        onPositionChanged: (mouse) => {
            if (!selecting) return;
            var rx = Math.min(startX, mouse.x);
            var ry = Math.min(startY, mouse.y);
            var rw = Math.abs(mouse.x - startX);
            var rh = Math.abs(mouse.y - startY);

            rubberBand.x = rx;
            rubberBand.y = ry;
            rubberBand.width = rw;
            rubberBand.height = rh;

            // Check intersecting items
            if (rw > 5 && rh > 5 && root.model) {
                var urls = [];
                var items = [];
                for (var i = 0; i < gridView.count; ++i) {
                    var item = gridView.itemAtIndex(i);
                    if (item) {
                        var ix = item.x - gridView.contentX;
                        var iy = item.y - gridView.contentY;
                        var iw = item.width;
                        var ih = item.height;
                        if (rx < ix + iw && rx + rw > ix && ry < iy + ih && ry + rh > iy) {
                            var data = root.model.get(i);
                            urls.push(data.url.toString());
                            items.push(data);
                        }
                    }
                }
                root.selectedUrls = urls;
                root.selectedItems = items;
            }
        }

        onReleased: {
            selecting = false;
            rubberBand.visible = false;
        }
    }

    GridView {
        id: gridView
        anchors.fill: parent
        anchors.margins: 20
        clip: true
        cellWidth: Math.max(90, root.iconSize + 56)
        cellHeight: Math.max(96, root.iconSize + 62)
        model: root.model
        focus: true

        delegate: Item {
            id: delegateRoot
            width: gridView.cellWidth
            height: gridView.cellHeight

            readonly property var itemData: root.model ? root.model.get(index) : null
            readonly property bool isItemSelected: itemData && root.isSelected(itemData.url.toString())

            // Folder Drop Area
            DropArea {
                anchors.fill: parent
                enabled: model.isDirectory
                onDropped: (drop) => {
                    if (drop.hasUrls) {
                        root.filesDropped(drop.urls, model.url, drop.x, drop.y);
                        drop.acceptProposedAction();
                    }
                }
            }

            CachyGridItem {
                id: gridItem
                anchors.centerIn: parent
                width: gridView.cellWidth - 12
                height: gridView.cellHeight - 10
                iconSize: root.iconSize
                title: model.name || ""
                iconName: model.iconName || "inode-directory"
                badgeText: model.isDirectory ? "" : (model.sizeString || "")
                selected: delegateRoot.isItemSelected

                Drag.active: dragArea.drag.active
                Drag.dragType: Drag.Automatic
                Drag.supportedActions: Qt.CopyAction | Qt.MoveAction | Qt.LinkAction
                Drag.mimeData: {
                    "text/uri-list": root.selectedUrls.length > 0
                        ? root.selectedUrls.join("\r\n")
                        : (model.url ? model.url.toString() : "")
                }

                MouseArea {
                    id: dragArea
                    anchors.fill: parent
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    drag.target: parent

                    onClicked: (mouse) => {
                        gridView.currentIndex = index;
                        root.currentIndex = index;
                        var it = delegateRoot.itemData || {
                            name: model.name,
                            url: model.url,
                            isDirectory: model.isDirectory
                        };
                        if (mouse.button === Qt.RightButton) {
                            if (!delegateRoot.isItemSelected) {
                                root.toggleSelect(it, false);
                            }
                            var gp = dragArea.mapToGlobal(mouse.x, mouse.y);
                            root.itemContextMenuRequested(it, gp.x, gp.y);
                        } else {
                            var isMulti = (mouse.modifiers & Qt.ControlModifier) || (mouse.modifiers & Qt.ShiftModifier);
                            root.toggleSelect(it, isMulti);
                            root.itemClicked(it);
                        }
                    }

                    onDoubleClicked: (mouse) => {
                        if (mouse.button === Qt.LeftButton) {
                            var it = delegateRoot.itemData || {
                                name: model.name,
                                url: model.url,
                                isDirectory: model.isDirectory
                            };
                            root.itemDoubleClicked(it);
                        }
                    }
                }
            }
        }
    }
}
