import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: root

    visible: false

    property var targetScreen: null

    signal weatherActionRequested(string action)
    signal notificationCenterActionRequested(string action)

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
