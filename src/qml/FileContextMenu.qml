import QtQuick
import QtQuick.Controls
import CachyOS.UI

CachyMenu {
    id: contextMenu

    property var targetItem: null

    signal openRequested(var item)
    signal openWithRequested(var item)
    signal moveToTrashRequested(var item)
    signal getInfoRequested(var item)
    signal quickLookRequested(var item)
    signal duplicateRequested(var item)
    signal copyRequested(var item)
    signal renameRequested(var item)
    signal tagRequested(var item, string color)

    CachyMenuItem {
        text: CachyI18n.i18n("Abrir")
        iconName: "external-link"
        onTriggered: contextMenu.openRequested(contextMenu.targetItem)
    }

    CachyMenuItem {
        text: CachyI18n.i18n("Vista rápida")
        iconName: "eye"
        shortcutText: "Espacio"
        onTriggered: contextMenu.quickLookRequested(contextMenu.targetItem)
    }

    CachyMenuSeparator {}

    CachyMenuItem {
        text: CachyI18n.i18n("Obtener información")
        iconName: "info"
        shortcutText: "Ctrl+I"
        onTriggered: contextMenu.getInfoRequested(contextMenu.targetItem)
    }

    CachyMenuItem {
        text: CachyI18n.i18n("Renombrar")
        shortcutText: "Intro"
        onTriggered: contextMenu.renameRequested(contextMenu.targetItem)
    }

    CachyMenuItem {
        text: CachyI18n.i18n("Duplicar")
        iconName: "copy"
        shortcutText: "Ctrl+D"
        onTriggered: contextMenu.duplicateRequested(contextMenu.targetItem)
    }

    CachyMenuSeparator {}

    CachyMenuItem {
        text: CachyI18n.i18n("Copiar")
        iconName: "copy"
        shortcutText: "Ctrl+C"
        onTriggered: contextMenu.copyRequested(contextMenu.targetItem)
    }

    CachyMenuItem {
        text: CachyI18n.i18n("Trasladar a la papelera")
        iconName: "trash"
        destructive: true
        shortcutText: "Ctrl+⌫"
        onTriggered: contextMenu.moveToTrashRequested(contextMenu.targetItem)
    }
}
