import "../components"
import "../idle/Duration.js" as Duration
import QtQuick
import QtQuick.Controls.Basic
import Quickshell
import Quickshell.Wayland

Item {
    id: root

    required property var config
    required property var idleService
    required property var targetScreen
    property var menuScreen: null
    property bool opened: false
    property string validationError: ""
    readonly property string statusText: idleService.disabled ? "Idle paused" : "Idle active"
    readonly property string toggleLabel: idleService.disabled ? "Enable" : "Pause"

    function openMenu(screen) {
        menuScreen = screen || targetScreen;
        validationError = "";
        lockRow.text = Duration.format(idleService.lockTimeout);
        offRow.text = Duration.format(idleService.offTimeout);
        suspendRow.text = Duration.format(idleService.suspendTimeout);
        opened = true;
        Qt.callLater(() => {
            return lockRow.focusInput();
        });
    }

    function closeMenu() {
        opened = false;
    }

    function saveSettings() {
        validationError = idleService.saveTimeouts(Duration.parse(lockRow.text), Duration.parse(offRow.text), Duration.parse(suspendRow.text));
        return validationError === "";
    }

    function applySettings() {
        if (saveSettings())
            closeMenu();

    }

    function toggleIdle() {
        root.idleService.toggle(root.menuScreen);
    }

    PanelWindow {
        id: menuWindow

        screen: root.menuScreen || root.targetScreen
        visible: root.opened
        implicitWidth: card.implicitWidth
        implicitHeight: card.implicitHeight
        anchors.top: true
        anchors.left: true
        margins.top: root.config.popupGap
        margins.left: screen ? Math.max(0, Math.round((screen.width - width) / 2)) : 0
        color: "transparent"
        exclusiveZone: 0
        focusable: true
        WlrLayershell.namespace: "quickshell-submenu"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

        PopoutPanel {
            id: card

            config: root.config
            contentWidth: 300
            padding: 10
            spacing: 5

            Shortcut {
                sequence: "Escape"
                onActivated: root.closeMenu()
            }

            Text {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.leftMargin: 8
                anchors.rightMargin: 8
                color: root.config.muted
                font.pointSize: root.config.fontSize(0.8)
                wrapMode: Text.WordWrap
                text: root.statusText
            }

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
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.leftMargin: 8
                anchors.rightMargin: 8
                color: root.config.muted
                font.pointSize: root.config.fontSize(0.78)
                text: "30s, 30m, 2h · 0 disables an idle action"
            }

            Text {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.leftMargin: 8
                anchors.rightMargin: 8
                visible: text !== ""
                color: root.config.urgent
                font.pointSize: root.config.fontSize(0.78)
                wrapMode: Text.WordWrap
                text: root.validationError || root.idleService.errorText
            }

            Row {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.leftMargin: 8
                anchors.rightMargin: 8
                spacing: card.spacing

                Button {
                    id: toggleButton

                    width: (parent.width - card.spacing) / 2
                    height: 32
                    text: root.toggleLabel
                    focusPolicy: Qt.StrongFocus
                    onClicked: root.toggleIdle()

                    background: FocusRing {
                        config: root.config
                        hovered: toggleButton.hovered
                        focused: toggleButton.activeFocus
                    }

                    contentItem: ButtonLabel {
                        config: root.config
                        text: toggleButton.text
                    }

                }

                Button {
                    id: applyButton

                    width: (parent.width - card.spacing) / 2
                    height: 32
                    text: "Apply"
                    focusPolicy: Qt.StrongFocus
                    onClicked: root.applySettings()

                    background: FocusRing {
                        config: root.config
                        hovered: applyButton.hovered
                        focused: applyButton.activeFocus
                    }

                    contentItem: ButtonLabel {
                        config: root.config
                        text: applyButton.text
                    }

                }

            }

        }

    }

    PopupCatcher {
        targetScreen: menuWindow.screen
        visible: root.opened
        onDismissed: root.closeMenu()
    }

    // Label on the left, editable duration on the right, shared baseline.
    component DurationRow: Item {
        id: row

        required property var config
        required property string label
        property alias text: input.text

        signal accepted()

        function focusInput() {
            input.forceActiveFocus();
            input.selectAll();
        }

        width: parent.width
        implicitHeight: 36

        Text {
            anchors.left: parent.left
            anchors.leftMargin: 8
            anchors.verticalCenter: parent.verticalCenter
            color: row.config.fg
            font.pointSize: row.config.fontSize(0.94)
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
            border.color: input.activeFocus ? row.config.accent : row.config.borderColor

            TextInput {
                id: input

                anchors.fill: parent
                anchors.leftMargin: 8
                anchors.rightMargin: 8
                verticalAlignment: TextInput.AlignVCenter
                color: row.config.fg
                selectionColor: row.config.accent
                selectedTextColor: row.config.bg
                font.pointSize: row.config.fontSize(0.92)
                selectByMouse: true
                onAccepted: row.accepted()
            }

        }

    }

    component FocusRing: Rectangle {
        required property var config
        required property bool hovered
        required property bool focused

        radius: 4
        color: hovered || focused ? config.borderColor : "transparent"
        border.width: 1
        border.color: focused ? config.accent : config.borderColor
    }

    component ButtonLabel: Text {
        required property var config

        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        color: config.fg
        font.pointSize: config.fontSize(0.88)
    }

}
