import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "../idle/Duration.js" as Duration

Item {
    id: root
    visible: false

    required property var config
    required property var lockService
    property var targetScreen: null
    property bool disabled: false
    property bool settingsLoaded: false
    property bool screensOff: false
    property bool applying: false
    property string errorText: ""
    property int lockTimeout: config.idleLockTimeout
    property int offTimeout: config.idleOffTimeout
    property int suspendTimeout: config.idleSuspendTimeout
    readonly property bool automaticEnabled: settingsLoaded && !disabled && !applying

    signal notificationRequested(string message, var screen)
    signal settingsRequested(var screen)

    onErrorTextChanged: {
        if (errorText !== "")
            notificationRequested(errorText, targetScreen)
    }

    function openSettings(screen) {
        settingsRequested(screen || targetScreen)
    }

    function toggle(screen) {
        if (!settingsLoaded) {
            notificationRequested("Still starting up", screen || targetScreen)
            return
        }
        disabled = !disabled
        notificationRequested(disabled ? "Disabled" : "Enabled", screen || targetScreen)
    }

    function saveTimeouts(lockSeconds, offSeconds, suspendSeconds) {
        const error = Duration.validate(lockSeconds, offSeconds, suspendSeconds)
        if (error !== "")
            return error
        if (!settingsLoaded)
            return "Settings are still loading"
        applying = true
        lockTimeout = lockSeconds
        offTimeout = offSeconds
        suspendTimeout = suspendSeconds
        persistSettings()
        applying = false
        return ""
    }

    function persistSettings() {
        settingsFile.setText(JSON.stringify({lock: lockTimeout, off: offTimeout,
            suspend: suspendTimeout}))
    }

    function wakeScreens() {
        if (screensOff) {
            screensOff = false
            Quickshell.execDetached(["niri", "msg", "action", "power-on-monitors"])
        }
    }

    function turnOffScreens() {
        if (automaticEnabled && offIdle.isIdle && !powerOff.running) {
            screensOff = true
            powerOff.running = true
        }
    }

    // Lock the session, then suspend. The helper waits for the compositor to
    // confirm the lock before the machine sleeps.
    function suspend() {
        if (suspendProcess.running)
            return
        suspendProcess.running = true
    }

    onDisabledChanged: if (disabled) wakeScreens()

    IdleMonitor {
        id: lockIdle
        // When both deadlines match, the monitor-off readiness check locks first.
        enabled: root.automaticEnabled && root.lockTimeout > 0
            && (root.offTimeout === 0 || root.lockTimeout !== root.offTimeout)
        timeout: root.lockTimeout
        respectInhibitors: true
        onIsIdleChanged: if (isIdle && enabled) root.lockService.lock()
    }

    IdleMonitor {
        id: offIdle
        enabled: root.automaticEnabled && root.offTimeout > 0
        timeout: root.offTimeout
        respectInhibitors: true
        onIsIdleChanged: {
            if (isIdle && enabled) {
                if (root.lockTimeout > 0) {
                    if (!prepareOff.running)
                        prepareOff.running = true
                } else {
                    root.turnOffScreens()
                }
            } else {
                root.wakeScreens()
            }
        }
    }

    IdleMonitor {
        id: suspendIdle
        enabled: root.automaticEnabled && root.suspendTimeout > 0
        timeout: root.suspendTimeout
        respectInhibitors: true
        onIsIdleChanged: if (isIdle && enabled) root.suspend()
    }

    Process {
        id: prepareOff
        command: ["bash", Quickshell.env("HOME") + "/.config/quickshell/lock/lock.sh"]
        onExited: exitCode => {
            if (exitCode === 0)
                root.turnOffScreens()
            else
                root.errorText = "Could not secure the screen; monitors left on"
        }
    }

    Process {
        id: powerOff
        command: ["niri", "msg", "action", "power-off-monitors"]
        onExited: exitCode => {
            if (exitCode !== 0) {
                root.screensOff = false
                root.errorText = "Could not turn off monitors"
            } else if (!root.automaticEnabled || !offIdle.isIdle) {
                root.wakeScreens()
            }
        }
    }

    Process {
        id: suspendProcess
        command: ["bash", Quickshell.env("HOME") + "/.config/quickshell/idle/suspend.sh"]
        onExited: exitCode => {
            if (exitCode !== 0)
                root.errorText = "Suspend failed"
        }
    }

    FileView {
        id: settingsFile
        path: (Quickshell.env("XDG_CACHE_HOME") || Quickshell.env("HOME") + "/.cache")
            + "/quickshell-idle.json"
        atomicWrites: true
        printErrors: false
        onLoaded: {
            try {
                const saved = JSON.parse(text())
                if (Duration.validate(saved.lock, saved.off, saved.suspend) === "") {
                    root.applying = true
                    root.lockTimeout = saved.lock
                    root.offTimeout = saved.off
                    root.suspendTimeout = saved.suspend
                    root.applying = false
                }
            } catch (error) {}
            root.settingsLoaded = true
        }
        onLoadFailed: root.settingsLoaded = true
    }

    IpcHandler {
        target: "idle"
        function toggle() { root.toggle(root.targetScreen) }
        function isDisabled(): bool { return root.disabled }
        function settings() { root.openSettings(root.targetScreen) }
    }
}
