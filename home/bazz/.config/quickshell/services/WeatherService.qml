import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: root

    visible: false

    property string text: ""
    property var data: ({})
    readonly property string scriptPath:
        Quickshell.env("HOME") + "/.config/quickshell/weather/weather.py"

    function refresh(force): void {
        if (!weatherProcess.running) {
            weatherProcess.command = force === true
                ? [scriptPath, "--refresh"]
                : [scriptPath]
            weatherProcess.running = true
        }
    }

    Process {
        id: weatherProcess

        command: [root.scriptPath]

        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const obj = JSON.parse(text)
                    root.data = obj
                    root.text = obj.text ?? ""
                } catch (_) {
                    root.data = ({ available: false })
                    root.text = "⚠ N/A"
                }
            }
        }
    }

    Timer {
        running: true
        repeat: true
        interval: 3600000
        triggeredOnStart: true
        onTriggered: root.refresh(false)
    }
}
