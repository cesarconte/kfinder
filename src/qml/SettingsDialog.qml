import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import CachyOS.UI

CachyDialog {
    id: dialog

    title: CachyI18n.i18n("Ajustes de Finder")
    preferredWidth: 480
    showCancelButton: true
    cancelText: CachyI18n.i18n("Cerrar")

    ColumnLayout {
        spacing: CachyTheme.spacingMedium
        width: parent.width

        CachyFormCard {
            Layout.fillWidth: true

            CachyFormCheckDelegate {
                text: CachyI18n.i18n("Mostrar extensiones de archivo")
                checked: true
            }

            CachyFormDelegateSeparator {}

            CachyFormCheckDelegate {
                text: CachyI18n.i18n("Avisar antes de vaciar la papelera")
                checked: true
            }

            CachyFormDelegateSeparator {}

            CachyFormCheckDelegate {
                text: CachyI18n.i18n("Eliminar elementos de la papelera tras 30 días")
                checked: false
            }

            CachyFormDelegateSeparator {}

            CachyFormCheckDelegate {
                text: CachyI18n.i18n("Mantener carpetas arriba al ordenar")
                checked: true
            }
        }
    }
}
