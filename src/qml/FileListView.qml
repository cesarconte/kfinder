import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import CachyOS.UI

Item {
    id: root

    property alias model: tableView.model
    property url currentUrl: ""
    property var selectedUrls: []
    property var selectedItems: []

    signal itemClicked(var item)
    signal itemDoubleClicked(var item)
    signal itemContextMenuRequested(var item, real mouseX, real mouseY)
    signal backgroundContextMenuRequested(real mouseX, real mouseY)
    signal filesDropped(var urls, url destination, real mouseX, real mouseY)

    function selectAll() {
        if (!tableView.model) return;
        var urls = [];
        var items = [];
        var indices = [];
        for (var i = 0; i < tableView.model.count; ++i) {
            var it = tableView.model.get(i);
            urls.push(it.url.toString());
            items.push(it);
            indices.push(i);
        }
        root.selectedUrls = urls;
        root.selectedItems = items;
        tableView.selectedIndices = indices;
    }

    function clearSelection() {
        root.selectedUrls = [];
        root.selectedItems = [];
        tableView.selectedIndices = [];
        tableView.currentIndex = -1;
    }

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

    CachyTableView {
        id: tableView
        anchors.fill: parent
        framed: false
        alternatingRows: true
        rowHeight: 32
        multiSelect: true

        columns: [
            { role: "name", iconRole: "iconName", type: "icon", title: CachyI18n.i18n("Nombre"), width: 340 },
            { role: "sizeString", title: CachyI18n.i18n("Tamaño"), width: 110 },
            { role: "mimeType", title: CachyI18n.i18n("Clase"), width: 180 },
            { role: "modifiedDate", title: CachyI18n.i18n("Fecha de modificación"), width: 160 }
        ]

        onRowClicked: (index, rowData) => {
            root.itemClicked(rowData);
            var it = root.model ? root.model.get(index) : rowData;
            if (it && it.url) {
                root.selectedUrls = [it.url.toString()];
                root.selectedItems = [it];
            }
        }

        onRowDoubleClicked: (index, rowData) => {
            var it = root.model ? root.model.get(index) : rowData;
            root.itemDoubleClicked(it);
        }

        onContextMenuRequested: (index, mouseX, mouseY) => {
            var data = tableView.getRowData(index);
            if (Object.keys(data).length === 0 && root.model) {
                data = root.model.get(index);
            }
            if (data && data.url) {
                root.selectedUrls = [data.url.toString()];
                root.selectedItems = [data];
            }
            root.itemContextMenuRequested(data, mouseX, mouseY);
        }

        onSortRequested: (role, order) => {
            if (root.model && typeof root.model.setSortRole === "function") {
                // Map role string to model sort role enum
                var roleEnum = 1; // Default Name
                if (role === "sizeString" || role === "sizeBytes") roleEnum = 5;
                else if (role === "modifiedDate") roleEnum = 6;
                else if (role === "mimeType") roleEnum = 11;
                root.model.setSortRole(roleEnum);
                root.model.setSortOrder(order);
            }
        }
    }
}
