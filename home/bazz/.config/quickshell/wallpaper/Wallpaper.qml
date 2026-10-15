pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import "../menus"

Item {
    id: root

    required property var config
    required property var targetScreen
    property var menuScreen: null
    property bool opened: false
    property string errorText: ""
    property string noticeText: ""
    property string fixedBackground: "121212"
    property bool replyReceived: false
    readonly property bool busy: applyProcess.running
    readonly property string directory: Quickshell.env("HOME") + "/Pictures/wallpaper"
    readonly property string helperPath: Quickshell.env("HOME") + "/.config/quickshell/wallpaper/setbg.py"

    onOpenedChanged: if (!opened) noticeText = ""
    onNoticeTextChanged: {
        if (noticeText !== "")
            noticeTimer.restart()
        else
            noticeTimer.stop()
    }

    Timer {
        id: noticeTimer
        interval: 2500
        onTriggered: root.noticeText = ""
    }

    function openMenu(screen) {
        menuScreen = screen || targetScreen
        opened = true
    }

    function close() { opened = false }
    function toggle() {
        if (opened)
            close()
        else
            openMenu(targetScreen)
    }

    function apply(path, pywal, background) {
        if (busy || !path)
            return
        errorText = ""
        noticeText = ""
        replyReceived = false
        const command = ["python3", helperPath, "apply", path]
        if (pywal)
            command.push("--pywal")
        if (pywal && background)
            command.push("--background", background)
        applyProcess.command = command
        applyProcess.running = true
    }

    // The picker is disposable; an apply operation survives closing/reopening it.
    LazyLoader {
        active: root.opened

        WallpaperMenu {
            config: root.config
            targetScreen: root.menuScreen || root.targetScreen
            controller: root
            onCloseRequested: root.close()
        }
    }

    Process {
        id: applyProcess

        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const reply = JSON.parse(text)
                    root.replyReceived = true
                    if (reply.ok)
                        root.noticeText = root.opened ? "Wallpaper applied" : ""
                    else
                        root.errorText = reply.error || "Could not apply wallpaper"
                } catch (error) {
                    root.errorText = "Could not read the wallpaper helper response"
                }
            }
        }
        stderr: StdioCollector {}
        onExited: exitCode => {
            if (!root.replyReceived)
                root.errorText = exitCode === 0 ? "No response from wallpaper helper" : "Could not run wallpaper helper"
        }
    }

    IpcHandler {
        target: "wallpaper"
        function open() { root.openMenu(root.targetScreen) }
        function close() { root.close() }
        function toggle() { root.toggle() }
    }
}
