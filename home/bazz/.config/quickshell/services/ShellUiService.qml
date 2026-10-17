import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: root

    visible: false

    property var targetScreen: null

    signal weatherActionRequested(string action)
    signal notificationCenterActionRequested(string action)
    signal audioActionRequested(string action)
    signal bluetoothActionRequested(string action)
    signal networkActionRequested(string action)

    IpcHandler {
        target: "bluetooth"
        function toggle(): void { root.bluetoothActionRequested("toggle") }
        function open(): void { root.bluetoothActionRequested("open") }
        function close(): void { root.bluetoothActionRequested("close") }
    }

    IpcHandler {
        target: "audio"
        function toggle(): void { root.audioActionRequested("toggle") }
        function open(): void { root.audioActionRequested("open") }
        function close(): void { root.audioActionRequested("close") }
    }

    IpcHandler {
        target: "network"
        function toggle(): void { root.networkActionRequested("toggle") }
        function open(): void { root.networkActionRequested("open") }
        function close(): void { root.networkActionRequested("close") }
    }

    IpcHandler {
        target: "weather"

        function toggle(): void {
            root.weatherActionRequested("toggle")
        }

        function open(): void {
            root.weatherActionRequested("open")
        }

        function close(): void {
            root.weatherActionRequested("close")
        }
    }

    IpcHandler {
        target: "notificationCenter"

        function toggle(): void {
            root.notificationCenterActionRequested("toggle")
        }

        function open(): void {
            root.notificationCenterActionRequested("open")
        }

        function close(): void {
            root.notificationCenterActionRequested("close")
        }
    }

}
