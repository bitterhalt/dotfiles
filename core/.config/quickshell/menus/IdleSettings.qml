import "../components"
import "../services/idle/Duration.js" as Duration
import QtQuick
import Quickshell
import Quickshell.Wayland

Item {
    id: root

    required property var config
    required property var idleService
    required property var settingsService
    required property var targetScreen
    property var menuScreen: null
    property bool opened: false
    property string validationError: ""
    readonly property string statusText: idleService.disabled ? "Idle paused" : "Idle active"
    readonly property string toggleLabel: idleService.disabled ? "Enable" : "Pause"

    // Load saved values before showing the editor; invalid values stay in-place for correction.
    function open(screen) {
        menuScreen = screen || targetScreen;
        validationError = "";
        lockRow.text = Duration.format(settingsService.lockTimeout);
        offRow.text = Duration.format(settingsService.offTimeout);
        suspendRow.text = Duration.format(settingsService.suspendTimeout);
        opened = true;
        Qt.callLater(() => {
            return lockRow.focusInput();
        });
    }

    function close() {
        opened = false;
    }

    function toggle(screen) {
        opened ? close() : open(screen);
    }

    function saveSettings() {
        validationError = settingsService.saveTimeouts(Duration.parse(lockRow.text), Duration.parse(offRow.text), Duration.parse(suspendRow.text));
        return validationError === "";
    }

    function applySettings() {
        if (saveSettings())
            close();
    }

    function toggleIdle() {
        root.idleService.toggle(root.menuScreen);
    }

    // Compact timeout editor and idle toggle.
    PanelWindow {
        id: menuWindow

        screen: root.menuScreen || root.targetScreen
        visible: popupMotion.surfaceVisible
        implicitWidth: card.implicitWidth
        implicitHeight: card.implicitHeight
        anchors.top: true
        anchors.left: true
        margins.top: root.config.popupGap
        margins.left: screen ? Math.max(0, Math.round((screen.width - width) / 2)) : 0
        color: "transparent"
        exclusiveZone: 0
        focusable: root.opened
        WlrLayershell.namespace: "slim-barpopup"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: root.opened ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

        PopupMotion {
            id: popupMotion
            duration: 150
            surfaceHeight: menuWindow.height
            shown: root.opened
            animationsEnabled: root.config.popupAnimations
            animationType: "fade"
        }

        PopoutPanel {
            id: card

            enabled: root.opened
            opacity: popupMotion.contentOpacity
            transform: Translate {
                y: popupMotion.contentOffset
            }
            config: root.config
            contentWidth: 300
            padding: 10
            spacing: 5

            Shortcut {
                sequence: "Escape"
                onActivated: root.close()
            }

            Text {
                renderType: Text.NativeRendering
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.leftMargin: 8
                anchors.rightMargin: 8
                color: root.config.muted
                font.pointSize: root.config.textSizeSmall
                wrapMode: Text.WordWrap
                text: root.statusText
            }

            // Lock, monitor-off and suspend thresholds (seconds or short units).
            DurationRow {
                id: lockRow

                config: root.config
                label: "Lock"
                onAccepted: root.applySettings()
            }

            DurationRow {
                id: offRow

                config: root.config
                label: "Monitors off"
                onAccepted: root.applySettings()
            }

            DurationRow {
                id: suspendRow

                config: root.config
                label: "Suspend"
                onAccepted: root.applySettings()
            }

            Text {
                renderType: Text.NativeRendering
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.leftMargin: 8
                anchors.rightMargin: 8
                color: root.config.muted
                font.pointSize: root.config.textSizeSmall
                text: "30s, 30m, 2h · 0 disables an idle action"
            }

            Text {
                renderType: Text.NativeRendering
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.leftMargin: 8
                anchors.rightMargin: 8
                visible: text !== ""
                color: root.config.urgent
                font.pointSize: root.config.textSizeSmall
                wrapMode: Text.WordWrap
                text: root.validationError || root.idleService.errorText
            }

            // Pause/resume idle handling or save the edited timeouts.
            Row {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.leftMargin: 8
                anchors.rightMargin: 8
                spacing: card.spacing

                ShellButton {
                    id: toggleButton

                    config: root.config
                    outlined: true
                    width: (parent.width - card.spacing) / 2
                    text: root.toggleLabel
                    focusPolicy: Qt.StrongFocus
                    onClicked: root.toggleIdle()
                }

                ShellButton {
                    id: applyButton

                    config: root.config
                    outlined: true
                    width: (parent.width - card.spacing) / 2
                    text: "Apply"
                    focusPolicy: Qt.StrongFocus
                    onClicked: root.applySettings()
                }
            }
        }
    }

    PopupCatcher {
        targetScreen: menuWindow.screen
        visible: menuWindow.visible
        onDismissed: root.close()
    }

    // Label on the left, editable duration on the right, shared baseline.
    component DurationRow: Item {
        id: row

        required property var config
        required property string label
        property alias text: input.text

        signal accepted

        function focusInput() {
            input.forceActiveFocus();
            input.selectAll();
        }

        width: parent.width
        implicitHeight: 36

        Text {
            renderType: Text.NativeRendering
            anchors.left: parent.left
            anchors.leftMargin: 8
            anchors.verticalCenter: parent.verticalCenter
            color: row.config.fg
            font.pointSize: row.config.textSizeMedium
            text: row.label
        }

        Rectangle {
            anchors.right: parent.right
            anchors.rightMargin: 8
            anchors.verticalCenter: parent.verticalCenter
            width: 104
            height: 28
            radius: 4
            color: "transparent"
            border.width: 1
            border.color: row.config.selectionBackground

            TextInput {
                id: input

                renderType: Text.NativeRendering
                anchors.fill: parent
                anchors.leftMargin: 8
                anchors.rightMargin: 8
                verticalAlignment: TextInput.AlignVCenter
                color: row.config.fg
                selectionColor: row.config.selectionBackground
                selectedTextColor: row.config.selectionForeground
                font.pointSize: row.config.textSizeNormal
                selectByMouse: true
                activeFocusOnTab: true
                onAccepted: row.accepted()
            }
        }
    }
}
