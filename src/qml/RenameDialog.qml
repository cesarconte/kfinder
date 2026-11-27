import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import CachyOS.UI

CachyDialog {
    id: dialog

    property url targetUrl: ""
    property string currentName: ""

    signal renameConfirmed(url target, string newName)

    title: CachyI18n.i18n("Renombrar elemento")
    preferredWidth: 380
    showCancelButton: true
    cancelText: CachyI18n.i18n("Cancelar")

    function confirmRename() {
        if (nameField.text.trim().length > 0 && nameField.text !== dialog.currentName) {
            dialog.renameConfirmed(dialog.targetUrl, nameField.text.trim())
        }
        dialog.close()
    }

    customFooterActions: [
        QtObject {
            property string text: CachyI18n.i18n("Renombrar")
            function trigger() {
                dialog.confirmRename()
            }
        }
    ]

    onVisibleChanged: {
        if (visible) {
            nameField.text = dialog.currentName
            nameField.forceActiveFocus()
            const dotIndex = dialog.currentName.lastIndexOf(".")
            if (dotIndex > 0) {
                nameField.select(0, dotIndex)
            } else {
                nameField.selectAll()
            }
        }
    }

    ColumnLayout {
        spacing: CachyTheme.spacingMedium
        width: parent.width

        Text {
            Layout.fillWidth: true
            text: CachyI18n.i18n("Introduce el nuevo nombre:")
            font.pixelSize: 13
            color: CachyPalette.textSecondary
            wrapMode: Text.WordWrap
        }

        CachyTextField {
            id: nameField
            Layout.fillWidth: true
            onAccepted: dialog.confirmRename()
        }
    }
}
