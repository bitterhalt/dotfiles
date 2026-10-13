import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: root
    visible: false

    function lock() {
        if (!launch.running)
            launch.running = true
    }

    Process {
        id: launch
        command: ["qs", "-n", "-d", "-p",
            Quickshell.env("HOME") + "/.config/quickshell/lock.qml",
            "--no-detailed-logs"]
        onExited: exitCode => {
            if (exitCode !== 0)
                Quickshell.execDetached(["notify-send", "Lock failed", "Could not start a session locker"])
        }
    }

    IpcHandler {
        target: "lock"
        function lock() { root.lock() }
    }
}
