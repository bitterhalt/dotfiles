pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import "../components"
import "../menus"
import "../services"

Item {
    id: root

    required property var config
    required property var targetScreen
    required property var settingsService
    property WallpaperService wallpaperService: null
    property var menuScreen: null
    property bool opened: false
    property string errorText: ""
    property string noticeText: ""
    property bool replyReceived: false
    property int applyExitCode: 0
    // Only a real wallpaper change needs the layers reloaded, not a theme refresh.
    property bool reloadOnReply: false
    readonly property bool busy: applyProcess.running
    readonly property string directory: Quickshell.env("HOME") + "/Pictures/wallpaper"
    readonly property string helperPath: Quickshell.env("HOME") + "/.config/quickshell/wallpaper/wallpaper-helper.py"

    PopupMotion {
        id: motion
        duration: 150
        shown: root.opened
        animationsEnabled: root.config.popupAnimations
        animationType: "fade"
    }

    onOpenedChanged: if (!opened)
        noticeText = ""
    onNoticeTextChanged: {
        if (noticeText !== "")
            noticeTimer.restart();
        else
            noticeTimer.stop();
    }

    Timer {
        id: noticeTimer
        interval: 2500
        onTriggered: root.noticeText = ""
    }

    // Process can report exit before StdioCollector finishes draining stdout.
    Timer {
        id: responseTimer
        interval: 1000
        onTriggered: {
            if (!root.replyReceived && applyStdout.text.trim() !== "")
                root.handleReply(applyStdout.text);
            if (!root.replyReceived)
                root.errorText = root.applyExitCode === 0 ? "No response from wallpaper helper" : "Could not run wallpaper helper";
        }
    }

    function handleReply(text) {
        root.replyReceived = true;
        // Reload even on error: the helper may have replaced the files before failing.
        if (root.reloadOnReply && root.wallpaperService)
            root.wallpaperService.reload();
        root.reloadOnReply = false;
        try {
            const reply = JSON.parse(text);
            if (reply.ok)
                root.noticeText = root.opened ? "Wallpaper applied" : "";
            else
                root.errorText = reply.error || "Could not apply wallpaper";
        } catch (error) {
            root.errorText = "Could not read the wallpaper helper response";
        }
    }

    function open(screen) {
        menuScreen = screen || targetScreen;
        opened = true;
    }

    function close() {
        opened = false;
    }
    function toggle(screen) {
        if (opened)
            close();
        else
            open(screen);
    }

    function apply(path, hellwal) {
        if (busy || !path)
            return;
        errorText = "";
        noticeText = "";
        replyReceived = false;
        reloadOnReply = true;
        const command = ["python3", helperPath, "apply", path];
        if (hellwal) {
            command.push("--hellwal", "--mode", settingsService.hellwalMode, "--dark-offset", String(settingsService.hellwalDarkOffset), "--bright-offset", String(settingsService.hellwalBrightOffset), "--gray-scale", String(settingsService.hellwalGrayScale));
            if (settingsService.hellwalBackgroundMode === "fixed")
                command.push("--static-background", settingsService.hellwalBackgroundColor);
        }
        applyProcess.command = command;
        applyProcess.running = true;
    }

    function refreshHellwal() {
        if (busy)
            return;
        errorText = "";
        noticeText = "";
        replyReceived = false;
        reloadOnReply = false;
        const command = ["python3", helperPath, "refresh", "--mode", settingsService.hellwalMode, "--dark-offset", String(settingsService.hellwalDarkOffset), "--bright-offset", String(settingsService.hellwalBrightOffset), "--gray-scale", String(settingsService.hellwalGrayScale)];
        if (settingsService.hellwalBackgroundMode === "fixed")
            command.push("--static-background", settingsService.hellwalBackgroundColor);
        applyProcess.command = command;
        applyProcess.running = true;
    }

    // The picker is disposable; an apply operation survives closing/reopening it.
    LazyLoader {
        active: motion.surfaceVisible

        WallpaperMenu {
            config: root.config
            targetScreen: root.menuScreen || root.targetScreen
            controller: root
            popupMotion: motion
            onCloseRequested: root.close()
        }
    }

    Process {
        id: applyProcess

        stdout: StdioCollector {
            id: applyStdout
            onStreamFinished: root.handleReply(text)
        }
        stderr: StdioCollector {}
        onExited: exitCode => {
            root.applyExitCode = exitCode;
            responseTimer.restart();
        }
    }

    PopupIpcHandler {
        target: "wallpaper"
        handleAction: action => {
            if (action === "open")
                root.open(root.targetScreen);
            else if (action === "toggle")
                root.toggle(root.targetScreen);
            else
                root.close();
        }
    }
}
