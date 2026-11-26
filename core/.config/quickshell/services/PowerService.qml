import QtQuick
import Quickshell
import Quickshell.Io

// Session power commands live here so the Settings footer and launcher actions
// cannot drift apart. Sleep goes through IdleService to keep the lock-then-
// suspend handshake.
Item {
    id: root
    visible: false

    required property var idleService

    function suspend(): void {
        idleService.suspend();
    }

    function exitSession(): void {
        Quickshell.execDetached(["niri", "msg", "action", "quit"]);
    }

    function reboot(): void {
        Quickshell.execDetached(["systemctl", "reboot"]);
    }

    function shutdown(): void {
        Quickshell.execDetached(["systemctl", "poweroff"]);
    }

    IpcHandler {
        target: "power"

        function suspend(): void {
            root.suspend();
        }

        function exit(): void {
            root.exitSession();
        }

        function reboot(): void {
            root.reboot();
        }

        function shutdown(): void {
            root.shutdown();
        }
    }
}
