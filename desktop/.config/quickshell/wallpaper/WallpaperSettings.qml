pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import "../components"

// Draft preferences: only Save writes them; Escape/Cancel leaves them unchanged.
FocusScope {
    id: root

    required property var config
    required property var settingsService
    required property bool busy
    property string errorText: ""
    signal saved
    signal cancelled

    function begin(): void {
        errorText = "";
        modeInput.currentIndex = settingsService.hellwalMode === "light" ? 1 : 0;
        backgroundModeInput.currentIndex = settingsService.hellwalBackgroundMode === "fixed" ? 1 : 0;
        darkOffsetInput.text = String(settingsService.hellwalDarkOffset);
        brightOffsetInput.text = String(settingsService.hellwalBrightOffset);
        grayScaleInput.text = String(settingsService.hellwalGrayScale);
        backgroundInput.text = settingsService.hellwalBackgroundColor;
        Qt.callLater(() => modeInput.forceActiveFocus());
    }

    function save(): void {
        if (busy)
            return;
        const dark = darkOffsetInput.text.trim();
        const bright = brightOffsetInput.text.trim();
        const grayScale = grayScaleInput.text.trim();
        if (dark === "" || bright === "" || grayScale === "") {
            errorText = "Offsets must be between 0 and 1";
            return;
        }
        errorText = settingsService.saveHellwalSettings(modeInput.currentIndex === 1 ? "light" : "dark", Number(dark), Number(bright), backgroundModeInput.currentIndex === 1 ? "fixed" : "dynamic", backgroundInput.text, Number(grayScale));
        if (errorText === "")
            saved();
    }

    Shortcut {
        sequence: "Ctrl+Return"
        enabled: root.visible && root.enabled && !root.busy
        onActivated: root.save()
    }
    Shortcut {
        sequence: "Ctrl+Enter"
        enabled: root.visible && root.enabled && !root.busy
        onActivated: root.save()
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: root.config.panelPadding

        RowLayout {
            Layout.fillWidth: true
            Text {
                renderType: Text.NativeRendering
                Layout.fillWidth: true
                text: "Wallpaper settings"
                color: root.config.fg
                font.pointSize: root.config.textSizeNormal
                font.weight: Font.Medium
                elide: Text.ElideRight
            }
        }

        ScrollView {
            id: settingsScroll
            Layout.fillWidth: true
            Layout.fillHeight: true
            contentWidth: availableWidth
            clip: true

            GridLayout {
                width: settingsScroll.availableWidth
                columns: width < 400 ? 1 : 2
                uniformCellWidths: true
                columnSpacing: root.config.panelPadding
                rowSpacing: root.config.spacingControl
                enabled: !root.busy

                ColumnLayout {
                    Layout.fillWidth: true
                    SettingLabel {
                        text: "Mode"
                    }
                    SettingCombo {
                        id: modeInput
                        objectName: "wallpaperColorMode"
                        model: ["Dark", "Light"]
                    }
                }
                ColumnLayout {
                    Layout.fillWidth: true
                    SettingLabel {
                        text: "Background"
                    }
                    SettingCombo {
                        id: backgroundModeInput
                        objectName: "wallpaperBackgroundMode"
                        model: ["Dynamic", "Fixed"]
                    }
                }
                ColumnLayout {
                    Layout.fillWidth: true
                    SettingLabel {
                        text: "Dark offset (0–1)"
                    }
                    SettingField {
                        id: darkOffsetInput
                        objectName: "wallpaperDarkOffset"
                        placeholderText: "0"
                    }
                }
                ColumnLayout {
                    Layout.fillWidth: true
                    SettingLabel {
                        text: "Bright offset (0–1)"
                    }
                    SettingField {
                        id: brightOffsetInput
                        objectName: "wallpaperBrightOffset"
                        placeholderText: "0"
                    }
                }
                ColumnLayout {
                    Layout.fillWidth: true
                    SettingLabel {
                        text: "Grayscale (0–1, 0 = off)"
                    }
                    SettingField {
                        id: grayScaleInput
                        objectName: "wallpaperGrayScale"
                        placeholderText: "0"
                    }
                }
                ColumnLayout {
                    Layout.fillWidth: true
                    enabled: backgroundModeInput.currentIndex === 1
                    opacity: enabled ? 1 : 0.5
                    SettingLabel {
                        text: "Fixed background color"
                    }
                    SettingField {
                        id: backgroundInput
                        objectName: "wallpaperBackgroundColor"
                        placeholderText: "#111111"
                        onAccepted: root.save()
                    }
                }
            }
        }

        Text {
            renderType: Text.NativeRendering
            Layout.fillWidth: true
            visible: root.errorText !== ""
            text: root.errorText
            color: root.config.urgent
            font.pointSize: root.config.textSizeSmall
            wrapMode: Text.WordWrap
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: root.config.spacingControl
            Item {
                Layout.fillWidth: true
            }
            ActionButton {
                text: "Cancel"
                onClicked: root.cancelled()
            }
            ActionButton {
                text: "Save"
                enabled: !root.busy
                onClicked: root.save()
            }
        }
    }

    component SettingLabel: Text {
        renderType: Text.NativeRendering
        Layout.fillWidth: true
        color: root.config.muted
        font.pointSize: root.config.textSizeMedium
        wrapMode: Text.WordWrap
    }

    component SettingField: ShellTextField {
        config: root.config
        Layout.fillWidth: true
        Layout.minimumWidth: 0
        Layout.preferredWidth: 1
        Layout.preferredHeight: 32
        onTextChanged: root.errorText = ""
    }

    component SettingCombo: ComboBox {
        id: combo
        Layout.fillWidth: true
        Layout.minimumWidth: 0
        Layout.preferredWidth: 1
        Layout.preferredHeight: 32
        font.pointSize: root.config.textSizeNormal
        onActivated: root.errorText = ""
        contentItem: Text {
            renderType: Text.NativeRendering
            leftPadding: 8
            rightPadding: combo.indicator ? combo.indicator.width + 8 : 8
            text: combo.currentText
            color: root.config.fg
            font: combo.font
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideRight
        }
        background: Rectangle {
            color: "transparent"
            radius: 4
            border.color: combo.activeFocus ? root.config.selectionBackground : root.config.border
        }
    }

    component ActionButton: ShellButton {
        config: root.config
        outlined: true
        outlineColor: root.config.border
        opacity: enabled ? 1 : 0.5
    }
}
