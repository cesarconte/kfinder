import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import CachyOS.UI

Rectangle {
    id: root

    property string currentFolderName: CachyI18n.i18n("Carpeta actual")
    property int scopeIndex: 0 // 0: This Mac / Este equipo, 1: Current Folder
    signal scopeChanged(int index)
    signal saveSearchRequested()

    height: 32
    color: CachyPalette.isDark ? Qt.rgba(0, 0, 0, 0.45) : Qt.rgba(0, 0, 0, 0.06)
    border.width: 1
    border.color: CachyPalette.hardDividerColor

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: CachyTheme.spacingMedium
        anchors.rightMargin: CachyTheme.spacingMedium
        spacing: CachyTheme.spacingSmall

        CachyLabel {
            text: CachyI18n.i18n("Buscar:")
            font.bold: true
            color: CachyPalette.textSecondary
            font.pixelSize: 11
        }

        CachyToolbarGroup {
            CachyToolbarButton {
                text: CachyI18n.i18n("Este equipo")
                checkable: true
                checked: root.scopeIndex === 0
                pillStyle: false
                onClicked: {
                    root.scopeIndex = 0
                    root.scopeChanged(0)
                }
            }

            CachyToolbarButton {
                text: "\"" + root.currentFolderName + "\""
                checkable: true
                checked: root.scopeIndex === 1
                pillStyle: false
                onClicked: {
                    root.scopeIndex = 1
                    root.scopeChanged(1)
                }
            }
        }

        Item { Layout.fillWidth: true }

        CachyButton {
            text: CachyI18n.i18n("Guardar")
            iconName: "add"
            pillStyle: true
            font.pixelSize: 11
            onClicked: root.saveSearchRequested()
        }
    }
}
