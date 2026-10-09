import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

Item {
    id: root

    visible: false

    required property var config

    property bool disabled: false
    property var targetScreen: null
    property bool displaysPoweredOff: false

    signal notificationRequested(string message, var screen)

    function lockSession(): void {
        Quickshell.execDetached([
            "sh",
            "-lc",
            "pidof swaylock >/dev/null || "
                + "swaylock -C \"$HOME/.cache/wal/colors-swaylock\" -f"
        ])
    }

    function powerOffDisplays(): void {
        if (displaysPoweredOff)
            return

        displaysPoweredOff = true
        Quickshell.execDetached([
            "niri", "msg", "action", "power-off-monitors"
        ])
    }

    function powerOnDisplays(): void {
        if (!displaysPoweredOff)
            return

        displaysPoweredOff = false
        Quickshell.execDetached([
            "niri", "msg", "action", "power-on-monitors"
        ])
    }

    function toggle(screen): void {
        if (disabled) {
            disabled = false
            notificationRequested("Enabled", screen || targetScreen)
        } else {
            disabled = true
            powerOnDisplays()
            notificationRequested("Disabled", screen || targetScreen)
        }
    }

    IdleMonitor {
        enabled: !root.disabled && root.config.idleLockTimeout > 0
        timeout: root.config.idleLockTimeout
        respectInhibitors: root.config.idleRespectInhibitors

        onIsIdleChanged: {
            if (isIdle)
                root.lockSession()
        }
    }

    IdleMonitor {
        enabled: !root.disabled && root.config.idleDisplayTimeout > 0
        timeout: root.config.idleDisplayTimeout
        respectInhibitors: root.config.idleRespectInhibitors

        onIsIdleChanged: {
            if (isIdle)
                root.powerOffDisplays()
            else
                root.powerOnDisplays()
        }
    }

    IdleMonitor {
        enabled: !root.disabled && root.config.idleSuspendTimeout > 0
        timeout: root.config.idleSuspendTimeout
        respectInhibitors: root.config.idleRespectInhibitors

        onIsIdleChanged: {
            if (isIdle)
                Quickshell.execDetached(["systemctl", "suspend"])
        }
    }

    IpcHandler {
        target: "idle"

        function toggle(): void {
            root.toggle(root.targetScreen)
        }

        function isDisabled(): bool {
            return root.disabled
        }
    }
}
