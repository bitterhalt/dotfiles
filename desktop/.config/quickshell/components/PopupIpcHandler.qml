import QtQuick
import Quickshell.Io

// Registers the common toggle/open/close IPC surface for a popup controller.
Item {
    id: root

    required property string target
    required property var handleAction

    IpcHandler {
        target: root.target

        function toggle(): void {
            root.handleAction("toggle");
        }

        function open(): void {
            root.handleAction("open");
        }

        function close(): void {
            root.handleAction("close");
        }
    }
}
