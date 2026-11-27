import QtQuick
import QtQuick.Controls
import CachyOS.UI

CachyMenu {
    id: dropMenu

    property var sourceUrls: []
    property url targetUrl: ""

    signal copyRequested(var sources, url destination)
    signal moveRequested(var sources, url destination)
    signal linkRequested(var sources, url destination)

    title: CachyI18n.i18n("Opciones de destino")

    CachyMenuItem {
        text: CachyI18n.i18n("Copiar aquí")
        iconName: "copy"
        onTriggered: dropMenu.copyRequested(dropMenu.sourceUrls, dropMenu.targetUrl)
    }

    CachyMenuItem {
        text: CachyI18n.i18n("Mover aquí")
        iconName: "arrow-right"
        onTriggered: dropMenu.moveRequested(dropMenu.sourceUrls, dropMenu.targetUrl)
    }

    CachyMenuItem {
        text: CachyI18n.i18n("Crear enlace aquí")
        iconName: "link"
        onTriggered: dropMenu.linkRequested(dropMenu.sourceUrls, dropMenu.targetUrl)
    }

    CachyMenuSeparator {}

    CachyMenuItem {
        text: CachyI18n.i18n("Cancelar")
        onTriggered: dropMenu.dismiss()
    }
}
