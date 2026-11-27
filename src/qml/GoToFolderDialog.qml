import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import CachyOS.UI

CachyDialog {
    id: dialog

    title: CachyI18n.i18n("Ir a la carpeta")
    preferredWidth: 420
    showCancelButton: true
    cancelText: CachyI18n.i18n("Cancelar")

    signal folderSelected(string path)

    ColumnLayout {
        spacing: CachyTheme.spacingMedium
        width: parent.width

        CachyTextField {
            id: pathInput
            Layout.fillWidth: true
            placeholderText: "~/Descargas o /usr/share"
            onAccepted: {
                if (text.length > 0) {
                    dialog.folderSelected(text.trim())
                    dialog.close()
                }
            }
        }

        CachyLabel {
            text: CachyI18n.i18n("Introduce una ruta absoluta o relativa con ~ para navegar.")
            color: CachyPalette.textSecondary
            font.pixelSize: 11
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
        }

        RowLayout {
            Layout.alignment: Qt.AlignRight
            CachyButton {
                text: CachyI18n.i18n("Ir")
                primary: true
                pillStyle: true
                onClicked: {
                    if (pathInput.text.length > 0) {
                        dialog.folderSelected(pathInput.text.trim())
                        dialog.close()
                    }
                }
            }
        }
    }
}
