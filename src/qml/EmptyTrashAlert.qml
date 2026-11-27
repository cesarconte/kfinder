import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import CachyOS.UI

CachyDialog {
    id: dialog

    title: CachyI18n.i18n("¿Vaciar la papelera?")
    preferredWidth: 380
    showCancelButton: true
    cancelText: CachyI18n.i18n("Cancelar")

    signal confirmed()

    ColumnLayout {
        spacing: CachyTheme.spacingMedium
        width: parent.width

        RowLayout {
            spacing: CachyTheme.spacingMedium
            Layout.fillWidth: true

            CachyIcon {
                name: "trash"
                size: 48
                color: CachyTheme.errorColor
                colored: true
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: CachyTheme.spacingTiny

                CachyLabel {
                    text: CachyI18n.i18n("¿Seguro que quieres eliminar definitivamente los elementos de la papelera?")
                    font.bold: true
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                }

                CachyLabel {
                    text: CachyI18n.i18n("Esta acción no se puede deshacer.")
                    color: CachyPalette.textSecondary
                    font.pixelSize: 11
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                }
            }
        }

        RowLayout {
            Layout.alignment: Qt.AlignRight
            CachyButton {
                text: CachyI18n.i18n("Vaciar papelera")
                destructive: true
                pillStyle: true
                onClicked: {
                    dialog.confirmed()
                    dialog.close()
                }
            }
        }
    }
}
