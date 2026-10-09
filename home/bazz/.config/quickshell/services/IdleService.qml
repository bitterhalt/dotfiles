import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: root

    visible: false

    property bool disabled: false
    property var targetScreen: null

    signal notificationRequested(string message, var screen)

    function refresh(): void {
        if (!statusCheck.running)
            statusCheck.running = true
    }

    function toggle(screen): void {
        if (disabled) {
            Quickshell.execDetached(["swayidle"])
            disabled = false
            notificationRequested("Enabled", screen || targetScreen)
        } else {
            Quickshell.execDetached(["pkill", "-x", "swayidle"])
            disabled = true
            notificationRequested("Disabled", screen || targetScreen)
        }
    }

    Process {
        id: statusCheck

        command: ["pgrep", "-x", "swayidle"]
        running: true

        onExited: exitCode => {
            root.disabled = exitCode !== 0
        }
    }

    IpcHandler {
        target: "idle"

        function toggle(): void {
            root.toggle(root.targetScreen)
        }

        function refresh(): void {
            root.refresh()
        }

        function isDisabled(): bool {
            return root.disabled
        }
    }
}
