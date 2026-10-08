import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: root

    visible: false

    property string outputFile: ""
    property string pendingTarget: ""
    property bool pendingAudio: false
    property var targetScreen: null

    readonly property bool runningNow: recorderProcess.running
    readonly property bool busy: runningNow || prepareDirectory.running

    signal menuActionRequested(string action)
    signal regionSelectionRequested()

    function captureDirectory(): string {
        return Quickshell.env("HOME") + "/Videos/Captures"
    }

    function makeOutputFile(): string {
        const stamp = Qt.formatDateTime(
            new Date(),
            "yyyy-MM-dd-HH-mm-ss"
        )

        return captureDirectory() + "/" + stamp + "_capture.mp4"
    }

    function notify(title, message): void {
        Quickshell.execDetached([
            "notify-send",
            "-a", "gpu-screen-recorder",
            "-t", "3000",
            title,
            message
        ])
    }

    function canStart(): bool {
        if (!busy)
            return true

        notify("Screen record", "Recording already in progress")
        return false
    }

    function prepare(target, withAudio): void {
        if (!canStart())
            return

        pendingTarget = target
        pendingAudio = withAudio
        outputFile = makeOutputFile()
        prepareDirectory.running = true
    }

    function fullscreen(): void {
        prepare("screen", true)
    }

    function startRegion(geometry): void {
        if (!geometry)
            return

        prepare(geometry, false)
    }

    function stop(): void {
        if (!runningNow) {
            notify("Screen record", "No active recording")
            return
        }

        // Signal only the process owned by this service.
        recorderProcess.signal(2)
    }

    function startRecorder(): void {
        const command = [
            "gpu-screen-recorder",
            "-w", pendingTarget,
            "-f", "60"
        ]

        if (pendingAudio)
            command.push("-a", "default_output")

        command.push("-o", outputFile)

        pendingTarget = ""
        pendingAudio = false
        recorderProcess.command = command
        recorderProcess.running = true
    }

    Process {
        id: prepareDirectory

        command: ["mkdir", "-p", root.captureDirectory()]

        onExited: exitCode => {
            if (exitCode === 0) {
                root.startRecorder()
                return
            }

            root.pendingTarget = ""
            root.pendingAudio = false
            root.outputFile = ""
            root.notify(
                "Screen record",
                "Could not create capture directory"
            )
        }
    }

    Process {
        id: recorderProcess

        onExited: exitCode => {
            if (root.outputFile !== "") {
                if (exitCode === 0) {
                    root.notify(
                        "Screen record",
                        "Recording saved to " + root.captureDirectory()
                    )
                } else {
                    root.notify(
                        "Screen record",
                        "Recording stopped with an error"
                    )
                }
            }

            root.outputFile = ""
        }
    }

    IpcHandler {
        target: "recorder"

        function toggle(): void {
            root.menuActionRequested("toggle")
        }

        function open(): void {
            root.menuActionRequested("open")
        }

        function close(): void {
            root.menuActionRequested("close")
        }

        function fullscreen(): void {
            root.menuActionRequested("close")
            root.fullscreen()
        }

        function region(): void {
            root.regionSelectionRequested()
        }

        function stop(): void {
            root.menuActionRequested("close")
            root.stop()
        }

        function isRecording(): bool {
            return root.runningNow
        }
    }
}
