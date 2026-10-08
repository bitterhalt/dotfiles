import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: root

    visible: false

    property string text: ""
    property var data: ({})

    function refresh(): void {
        if (!weatherProcess.running)
            weatherProcess.running = true
    }

    Process {
        id: weatherProcess

        command: [
            Quickshell.env("HOME")
                + "/.config/quickshell/modules/weather/weather.py"
        ]

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
        onTriggered: root.refresh()
    }
}
