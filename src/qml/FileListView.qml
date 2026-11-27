import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import CachyOS.UI

Item {
    id: root

    property alias model: tableView.model
    signal itemDoubleClicked(var item)
    signal itemContextMenuRequested(var item, real mouseX, real mouseY)

    CachyTableView {
        id: tableView
        anchors.fill: parent
        framed: false
        alternatingRows: true
        rowHeight: 32

        columns: [
            { role: "name", iconRole: "iconName", type: "icon", title: CachyI18n.i18n("Nombre"), width: 340 },
            { role: "sizeString", title: CachyI18n.i18n("Tamaño"), width: 110 },
            { role: "mimeType", title: CachyI18n.i18n("Clase"), width: 180 }
        ]

        onRowDoubleClicked: (index, rowData) => {
            root.itemDoubleClicked(rowData)
        }

        onContextMenuRequested: (index, mouseX, mouseY) => {
            var data = tableView.getRowData(index)
            root.itemContextMenuRequested(data, mouseX, mouseY)
        }
    }
}
