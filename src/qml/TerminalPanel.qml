import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import CachyOS.UI
import org.cesar.kfinder

Rectangle {
    id: root

    property alias workingDirectory: terminal.workingDirectory
    signal closeRequested()
    signal openExternalRequested()

    implicitHeight: 220
    color: CachyPalette.isDark ? Qt.rgba(0.08, 0.08, 0.10, 0.95) : Qt.rgba(0.96, 0.96, 0.97, 0.95)
    border.width: 1
    border.color: CachyPalette.hardDividerColor

    TerminalBridge {
        id: terminal
    }

    Component.onCompleted: {
        terminal.startShell()
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // Terminal Panel Header
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 28
            color: CachyPalette.isDark ? Qt.rgba(0, 0, 0, 0.35) : Qt.rgba(0, 0, 0, 0.05)
            border.width: 1
            border.color: CachyPalette.hardDividerColor

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: CachyTheme.spacingMedium
                anchors.rightMargin: CachyTheme.spacingSmall
                spacing: CachyTheme.spacingSmall

                CachyIcon {
                    name: "utilities-terminal"
                    implicitWidth: 14
                    implicitHeight: 14
                    color: CachyPalette.textSecondary
                }

                CachyLabel {
                    text: CachyI18n.i18n("Terminal") + (root.workingDirectory ? (" — " + root.workingDirectory) : "")
                    font.pixelSize: 11
                    font.bold: true
                    color: CachyPalette.textSecondary
                    elide: Text.ElideMiddle
                    Layout.fillWidth: true
                }

                CachyToolbarButton {
                    iconName: "edit-clear"
                    tooltipText: CachyI18n.i18n("Limpiar salida")
                    pillStyle: false
                    onClicked: terminal.clear()
                }

                CachyToolbarButton {
                    iconName: "system-run"
                    tooltipText: CachyI18n.i18n("Abrir en Konsole (Shift+F4)")
                    pillStyle: false
                    onClicked: root.openExternalRequested()
                }

                CachyToolbarButton {
                    iconName: "window-close"
                    tooltipText: CachyI18n.i18n("Cerrar (F4)")
                    pillStyle: false
                    onClicked: root.closeRequested()
                }
            }
        }

        // Terminal Output Area
        ScrollView {
            id: outputScroll
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true

            TextArea {
                id: outputText
                readOnly: true
                text: terminal.output
                color: CachyPalette.isDark ? "#e0e0e6" : "#1a1a1c"
                background: null
                font.family: "Noto Sans Mono, monospace"
                font.pixelSize: 12
                wrapMode: TextEdit.Wrap
                selectByMouse: true

                onTextChanged: {
                    outputScroll.ScrollBar.vertical.position = 1.0 - outputScroll.ScrollBar.vertical.size
                }
            }
        }

        // Terminal Command Input Bar
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 32
            color: CachyPalette.isDark ? Qt.rgba(0, 0, 0, 0.25) : Qt.rgba(0, 0, 0, 0.03)
            border.width: 1
            border.color: CachyPalette.hardDividerColor

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: CachyTheme.spacingMedium
                anchors.rightMargin: CachyTheme.spacingSmall
                spacing: CachyTheme.spacingSmall

                CachyLabel {
                    text: "$"
                    font.family: "Noto Sans Mono, monospace"
                    font.bold: true
                    color: CachyTheme.accentColor
                }

                CachyTextField {
                    id: cmdInput
                    Layout.fillWidth: true
                    placeholderText: CachyI18n.i18n("Escribe un comando y pulsa Intro...")
                    font.family: "Noto Sans Mono, monospace"
                    font.pixelSize: 12

                    property var history: []
                    property int historyIndex: -1

                    Keys.onReturnPressed: {
                        if (text.trim().length > 0) {
                            terminal.sendCommand(text)
                            history.push(text)
                            historyIndex = history.length
                            text = ""
                        }
                    }

                    Keys.onUpPressed: {
                        if (history.length > 0 && historyIndex > 0) {
                            historyIndex--
                            text = history[historyIndex]
                        }
                    }

                    Keys.onDownPressed: {
                        if (historyIndex < history.length - 1) {
                            historyIndex++
                            text = history[historyIndex]
                        } else {
                            historyIndex = history.length
                            text = ""
                        }
                    }
                }

                CachyButton {
                    text: CachyI18n.i18n("Ejecutar")
                    pillStyle: true
                    font.pixelSize: 11
                    onClicked: {
                        if (cmdInput.text.trim().length > 0) {
                            terminal.sendCommand(cmdInput.text)
                            cmdInput.history.push(cmdInput.text)
                            cmdInput.historyIndex = cmdInput.history.length
                            cmdInput.text = ""
                        }
                    }
                }
            }
        }
    }
}
