import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Widgets

Item {
    id: batteryModule

    required property var config
    required property var barWindow

    width: battery.present ? batteryText.implicitWidth : 0
    height: barWindow.height
    visible: battery.present

    Text {
        id: batteryText

        anchors.centerIn: parent
        color: config.fg
        font.pointSize: config.fontSize(1)
        text: `${battery.capacity}% ${battery.icon}`
    }

    Process {
        id: battery

        property bool present: false
        property int capacity: 0
        property string status: ""
        readonly property string icon: {
            const p = capacity;
            if (status.toLowerCase().includes("charging"))
                return "󰂄";

            const icons = ["󰂎", "󰁺", "󰁻", "󰁼", "󰁽", "󰁾", "󰁿", "󰂀", "󰂁", "󰂂", "󰁹"];
            const idx = Math.max(0, Math.min(10, Math.round(p / 10)));
            return icons[idx];
        }

        command: ["sh", "-lc", "BAT=/sys/class/power_supply/BAT0; [ -d \"$BAT\" ] || exit 1; printf '%s\n%s\n' \"$(cat \"$BAT/capacity\")\" \"$(cat \"$BAT/status\" 2>/dev/null || true)\""]
        onExited: (exitCode) => {
            if (exitCode !== 0)
                battery.present = false;

        }

        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.trim().split(/\n+/);
                if (lines.length > 0 && lines[0] !== "") {
                    battery.capacity = parseInt(lines[0]) || 0;
                    battery.status = lines.length > 1 ? lines[1] : "";
                    battery.present = true;
                } else {
                    battery.present = false;
                }
            }
        }

    }

    Timer {
        running: true
        repeat: true
        interval: 60000
        triggeredOnStart: true
        onTriggered: {
            if (!battery.running)
                battery.running = true;

        }
    }

}
