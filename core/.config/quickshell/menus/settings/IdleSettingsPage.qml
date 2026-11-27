pragma ComponentBehavior: Bound

import "../../components"
import "../../services/idle/Duration.js" as Duration
import QtQuick

// Idle page: pause toggle plus the three timeouts. They are edited freely and
// validated together by apply(), which the menu calls from Apply/Ctrl+Enter.
Column {
    id: root

    required property var config
    required property var idleService
    required property var settingsService
    required property var menuScreen
    property bool active: false
    property string noteText: ""

    signal applyRequested

    width: parent ? parent.width : 0
    spacing: config.spacingTight
    visible: active

    function apply() {
        const field = index => fields.itemAt(index) ? fields.itemAt(index).value : "";
        const error = settingsService.saveTimeouts(Duration.parse(field(0)), Duration.parse(field(1)), Duration.parse(field(2)));
        noteText = error === "" ? "Saved" : "";
        return error;
    }

    SettingRow {
        config: root.config
        label: root.idleService.disabled ? "Idle paused" : "Idle active"
        muted: true
        controlInset: 72

        ShellButton {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            config: root.config
            outlined: true
            text: root.idleService.disabled ? "Enable" : "Pause"
            onClicked: root.idleService.toggle(root.menuScreen)
        }
    }

    Repeater {
        id: fields

        model: root.active ? [
            {
                label: "Lock",
                key: "lockTimeout"
            },
            {
                label: "Monitors off",
                key: "offTimeout"
            },
            {
                label: "Suspend",
                key: "suspendTimeout"
            }
        ] : []

        delegate: SettingRow {
            id: idleRow

            required property var modelData
            property alias value: idleInput.text

            config: root.config
            label: modelData.label
            controlInset: 104

            ShellTextField {
                id: idleInput

                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                width: 104
                implicitHeight: 28
                config: root.config
                font.pointSize: root.config.textSizeMedium
                Component.onCompleted: text = Duration.format(root.settingsService[idleRow.modelData.key])
                onAccepted: root.applyRequested()
            }
        }
    }
}
