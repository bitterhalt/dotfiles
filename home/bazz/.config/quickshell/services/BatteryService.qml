import QtQuick
import Quickshell.Io

Item {
    id: root

    visible: false

    property bool present: false
    property int capacity: 0
    property string status: ""

    readonly property string icon: {
        if (status.toLowerCase().includes("charging"))
            return "󰂄"

        const icons = [
            "󰂎", "󰁺", "󰁻", "󰁼", "󰁽", "󰁾",
            "󰁿", "󰂀", "󰂁", "󰂂", "󰁹"
        ]
        const index = Math.max(0, Math.min(10, Math.round(capacity / 10)))
        return icons[index]
    }

    function refresh(): void {
        if (!batteryProcess.running)
            batteryProcess.running = true
    }

    Process {
        id: batteryProcess

        command: [
            "sh",
            "-lc",
            "for BAT in /sys/class/power_supply/BAT*; do "
                + "[ -d \"$BAT\" ] || continue; "
                + "printf '%s\\n%s\\n' \"$(cat \"$BAT/capacity\")\" "
                + "\"$(cat \"$BAT/status\" 2>/dev/null || true)\"; "
                + "exit 0; done; exit 1"
        ]

        onExited: exitCode => {
            if (exitCode !== 0)
                root.present = false
        }

        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.trim().split(/\n+/)

                if (lines.length > 0 && lines[0] !== "") {
                    root.capacity = parseInt(lines[0]) || 0
                    root.status = lines.length > 1 ? lines[1] : ""
                    root.present = true
                } else {
                    root.present = false
                }
            }
        }
    }

    Timer {
        running: true
        repeat: true
        interval: 60000
        triggeredOnStart: true
        onTriggered: root.refresh()
    }
}
