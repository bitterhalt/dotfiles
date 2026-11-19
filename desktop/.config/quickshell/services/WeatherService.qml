import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: root
    visible: false

    property string text: "…"
    property var data: ({
            available: false,
            forecast: []
        })
    readonly property bool refreshing: weatherProcess.running
    readonly property string scriptPath: Quickshell.env("HOME") + "/.config/quickshell/weather/weather.py"
    property bool replyReceived: false

    function refresh(force): void {
        if (refreshing)
            return;
        replyReceived = false;
        weatherProcess.command = ["python3", scriptPath].concat(force === true ? ["--refresh"] : []);
        weatherProcess.running = true;
    }

    function unavailable(): void {
        data = {
            available: false,
            forecast: []
        };
        text = "⚠ N/A";
    }

    Process {
        id: weatherProcess
        objectName: "weatherProcess"
        stdout: StdioCollector {
            onStreamFinished: {
                root.replyReceived = true;
                try {
                    const result = JSON.parse(text);
                    if (typeof result.available !== "boolean")
                        throw new Error("Invalid weather response");
                    root.data = result;
                    root.text = result.text || "⚠ N/A";
                } catch (_) {
                    root.unavailable();
                }
            }
        }
        stderr: StdioCollector {}
        onExited: exitCode => {
            if (exitCode !== 0 && !root.replyReceived)
                root.unavailable();
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
