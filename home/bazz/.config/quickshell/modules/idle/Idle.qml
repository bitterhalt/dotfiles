import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: idleModule

    required property var config
    required property var barWindow

    property bool disabled: false
    width: disabled ? 24 : 0
    height: barWindow.height
    visible: width > 0

    function refresh(): void {
        if (!statusCheck.running)
            statusCheck.running = true
    }

    function toggle(): void {
        if (disabled) {
            Quickshell.execDetached(["swayidle"])
            disabled = false
            idleNotifier.show("Enabled")
        } else {
            Quickshell.execDetached(["pkill", "-x", "swayidle"])
            disabled = true
            idleNotifier.show("Disabled")
        }
    }

    Text {
        anchors.centerIn: parent
        color: config.accent
        font.family: config.iconFontFamily
        font.pointSize: config.iconSize
        text: "󱐋"
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: idleModule.toggle()
    }

    // One initial state check only. Explicit toggles update the state directly.
    Process {
        id: statusCheck

        command: ["pgrep", "-x", "swayidle"]
        running: true

        onExited: exitCode => {
            idleModule.disabled = exitCode !== 0
        }
    }

    IdleNotifier {
        id: idleNotifier
        config: idleModule.config
        barWindow: idleModule.barWindow
    }

    IpcHandler {
        target: "idle"

        function toggle(): void {
            idleModule.toggle()
        }

        function refresh(): void {
            idleModule.refresh()
        }

        function isDisabled(): bool {
            return idleModule.disabled
        }
    }
}
