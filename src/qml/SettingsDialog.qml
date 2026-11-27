import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import CachyOS.UI
import org.cesar.kfinder

CachyDialog {
    id: dialog

    property SettingsManager settings: null

    title: CachyI18n.i18n("Ajustes de Finder")
    preferredWidth: 500
    showCancelButton: true
    cancelText: CachyI18n.i18n("Cerrar")

    ColumnLayout {
        spacing: CachyTheme.spacingMedium
        width: parent.width

        // Tab switcher using CachySegmentedControl
        CachySegmentedControl {
            id: settingsTabs
            Layout.alignment: Qt.AlignHCenter
            pillStyle: true
            model: [
                { icon: "settings", text: CachyI18n.i18n("General") },
                { icon: "tag", text: CachyI18n.i18n("Etiquetas") },
                { icon: "sidebar", text: CachyI18n.i18n("Barra lateral") },
                { icon: "sliders", text: CachyI18n.i18n("Avanzado") }
            ]
            currentIndex: 0
        }

        // 1. General Tab
        ColumnLayout {
            Layout.fillWidth: true
            visible: settingsTabs.currentIndex === 0
            spacing: CachyTheme.spacingSmall

            CachyFormCard {
                Layout.fillWidth: true

                CachyFormComboBoxDelegate {
                    label: CachyI18n.i18n("Modo de visualización predeterminado")
                    model: [
                        CachyI18n.i18n("Como iconos"),
                        CachyI18n.i18n("Como lista"),
                        CachyI18n.i18n("Como columnas"),
                        CachyI18n.i18n("Como galería")
                    ]
                    currentIndex: dialog.settings ? dialog.settings.defaultViewMode : 0
                    onActivated: (index) => {
                        if (dialog.settings) dialog.settings.defaultViewMode = index
                    }
                }

                CachyFormDelegateSeparator {}

                CachyFormCheckDelegate {
                    text: CachyI18n.i18n("Mostrar archivos ocultos")
                    checked: dialog.settings ? dialog.settings.showHiddenFiles : false
                    onToggled: {
                        if (dialog.settings) dialog.settings.showHiddenFiles = checked
                    }
                }

                CachyFormDelegateSeparator {}

                CachyFormButtonDelegate {
                    text: (dialog.settings && dialog.settings.isDefaultFileManager)
                          ? CachyI18n.i18n("Finder es el gestor predeterminado")
                          : CachyI18n.i18n("Establecer Finder como predeterminado")
                    description: (dialog.settings && dialog.settings.isDefaultFileManager)
                          ? CachyI18n.i18n("kfinder gestiona todas las carpetas del sistema. Clic para restaurar Dolphin.")
                          : CachyI18n.i18n("Configura kfinder para abrir carpetas desde cualquier app.")
                    icon.name: (dialog.settings && dialog.settings.isDefaultFileManager) ? "check" : "external-link"
                    onClicked: {
                        if (dialog.settings) {
                            if (dialog.settings.isDefaultFileManager) {
                                dialog.settings.restoreDolphinDefault()
                            } else {
                                dialog.settings.setAsDefaultFileManager()
                            }
                        }
                    }
                }
            }
        }

        // 2. Etiquetas Tab
        ColumnLayout {
            Layout.fillWidth: true
            visible: settingsTabs.currentIndex === 1
            spacing: CachyTheme.spacingSmall

            CachyFormCard {
                Layout.fillWidth: true

                Repeater {
                    model: [
                        { name: CachyI18n.i18n("Rojo"), color: "#ff453a" },
                        { name: CachyI18n.i18n("Naranja"), color: "#ff9f0a" },
                        { name: CachyI18n.i18n("Amarillo"), color: "#ffd60a" },
                        { name: CachyI18n.i18n("Verde"), color: "#30d158" },
                        { name: CachyI18n.i18n("Azul"), color: "#0a84ff" },
                        { name: CachyI18n.i18n("Púrpura"), color: "#bf5af2" },
                        { name: CachyI18n.i18n("Gris"), color: "#8e8e93" }
                    ]

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0

                        CachyFormCheckDelegate {
                            text: modelData.name
                            checked: true
                        }

                        CachyFormDelegateSeparator {
                            visible: index < 6
                        }
                    }
                }
            }
        }

        // 3. Barra Lateral Tab
        ColumnLayout {
            Layout.fillWidth: true
            visible: settingsTabs.currentIndex === 2
            spacing: CachyTheme.spacingSmall

            CachyFormCard {
                Layout.fillWidth: true

                CachyFormCheckDelegate {
                    text: CachyI18n.i18n("Favoritos (Inicio, Descargas, Documentos)")
                    checked: true
                }

                CachyFormDelegateSeparator {}

                CachyFormCheckDelegate {
                    text: CachyI18n.i18n("Ubicaciones (Discos, Dispositivos externos, Red)")
                    checked: true
                }

                CachyFormDelegateSeparator {}

                CachyFormCheckDelegate {
                    text: CachyI18n.i18n("Etiquetas de color")
                    checked: true
                }
            }
        }

        // 4. Avanzado Tab
        ColumnLayout {
            Layout.fillWidth: true
            visible: settingsTabs.currentIndex === 3
            spacing: CachyTheme.spacingSmall

            CachyFormCard {
                Layout.fillWidth: true

                CachyFormCheckDelegate {
                    text: CachyI18n.i18n("Mostrar todas las extensiones de archivo")
                    checked: dialog.settings ? dialog.settings.showFileExtensions : true
                    onToggled: {
                        if (dialog.settings) dialog.settings.showFileExtensions = checked
                    }
                }

                CachyFormDelegateSeparator {}

                CachyFormCheckDelegate {
                    text: CachyI18n.i18n("Avisar antes de vaciar la papelera")
                    checked: dialog.settings ? dialog.settings.confirmEmptyTrash : true
                    onToggled: {
                        if (dialog.settings) dialog.settings.confirmEmptyTrash = checked
                    }
                }

                CachyFormDelegateSeparator {}

                CachyFormCheckDelegate {
                    text: CachyI18n.i18n("Mantener carpetas arriba al ordenar por nombre")
                    checked: dialog.settings ? dialog.settings.keepFoldersOnTop : true
                    onToggled: {
                        if (dialog.settings) dialog.settings.keepFoldersOnTop = checked
                    }
                }

                CachyFormDelegateSeparator {}

                CachyFormComboBoxDelegate {
                    label: CachyI18n.i18n("Perfil de atajos de teclado")
                    model: [
                        CachyI18n.i18n("Perfil Finder (Intro = Renombrar, Ctrl+↓ = Abrir)"),
                        CachyI18n.i18n("Perfil Dolphin (F2 = Renombrar, Intro = Abrir)")
                    ]
                    currentIndex: dialog.settings ? dialog.settings.keyboardProfile : 0
                    onActivated: (index) => {
                        if (dialog.settings) dialog.settings.keyboardProfile = index
                    }
                }
            }
        }
    }
}
