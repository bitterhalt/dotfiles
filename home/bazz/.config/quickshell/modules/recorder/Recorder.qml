import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: recorderModule

    required property var config
    required property var barWindow

    property bool runningNow: false

    width: runningNow ? recorderText.implicitWidth + 12 : 0
    height: barWindow.height
    visible: runningNow

    function refresh(): void {
        if (statusProc.running)
            return

        statusProc.running = true
    }

    Text {
        id: recorderText

        anchors.centerIn: parent
        color: config.accent
        font.pointSize: config.fontSize(1)
        text: "Recording"
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor

        onClicked: {
            if (!stopProc.running)
                stopProc.running = true
        }
    }

    // `-f` matches the full command line, avoiding Linux's 15-character
    // process-name limit that affects plain `pgrep -x`.
    Process {
        id: statusProc
        command: ["pgrep", "--quiet", "-f", "^gpu-screen-recorder"]

        onExited: exitCode => {
            recorderModule.runningNow = exitCode === 0
        }
    }

    Process {
        id: stopProc
        command: [Quickshell.env("HOME") + "/.local/bin/wl-record", "-k"]

        onExited: recorderModule.refresh()
    }

    Component.onCompleted: refresh()

    // Event-driven refresh from your recording script:
    //   qs ipc call recorder refresh
    IpcHandler {
        target: "recorder"

        function refresh(): void {
            recorderModule.refresh()
        }

        function isRecording(): bool {
            return recorderModule.runningNow
        }
    }
}
