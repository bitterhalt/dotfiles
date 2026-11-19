import QtQuick
import Quickshell
import Quickshell.Io

import "../components"
import "UpdateModel.js" as UpdateModel

// Owns the on-demand check and the lazily created popup surface.
Item {
    id: root

    required property var config
    required property var targetScreen

    property var menuScreen: null
    property bool opened: false
    property var report: null
    property bool busy: false
    property string errorText: ""
    property bool replyReceived: false
    property int checkExitCode: 0
    // True while the disposable view exists. It is created before `opened`
    // flips so the window is already alive when the enter fade starts.
    property bool viewPrepared: false
    readonly property string helperPath: Quickshell.env("HOME") + "/.config/quickshell/updates/updates-helper.py"
    readonly property string upgradeScript: Quickshell.env("HOME") + "/.config/quickshell/updates/upgrade.sh"

    function open(screen): void {
        menuScreen = screen || targetScreen;
        viewPrepared = true;
        opened = true;
        // Check once per session; later opens reuse the cached report until
        // the user presses Refresh. A missing report (first open or a failed
        // check) retries the next time the popup is shown.
        if (!report && !busy)
            refresh();
    }

    function close(): void {
        opened = false;
    }

    function toggle(screen): void {
        opened ? close() : open(screen);
    }

    function refresh(): void {
        if (busy)
            return;
        errorText = "";
        replyReceived = false;
        busy = true;
        checkProcess.command = ["python3", helperPath, "check"];
        checkProcess.running = true;
    }

    function handleReport(text): void {
        replyReceived = true;
        busy = false;
        let parsed;
        try {
            parsed = JSON.parse(text);
        } catch (error) {
            errorText = "Could not read the update report";
            return;
        }
        if (!parsed || parsed.ok !== true) {
            errorText = parsed && parsed.error ? String(parsed.error) : "Could not check for updates";
            return;
        }

        if (!Array.isArray(parsed.managers))
            parsed.managers = [];
        if (!Array.isArray(parsed.notices))
            parsed.notices = [];

        report = parsed;
        errorText = "";
    }

    function upgrade(): void {
        if (!report || busy || UpdateModel.total(report) === 0)
            return;
        const terminal = Quickshell.env("TERMINAL") || "foot";
        close();
        Quickshell.execDetached([terminal, "--app-id", "pop-upgrade", "-e", "bash", upgradeScript]);
    }

    onOpenedChanged: {
        if (opened)
            return;
        responseTimer.stop();
        if (checkProcess.running)
            checkProcess.running = false;
        busy = false;
        replyReceived = true;
    }

    PopupMotion {
        id: motion
        duration: 150
        shown: root.opened
        animationsEnabled: root.config.popupAnimations
        animationType: "fade"
        onClosed: {
            // Dispose the view after the exit fade. Deferred so the loader is
            // not destroyed from inside the motion's own signal handler, and
            // skipped when the popup was reopened during the fade.
            Qt.callLater(() => {
                if (!root.opened)
                    root.viewPrepared = false;
            });
        }
    }

    // The view is disposable; the last report stays in this controller.
    LazyLoader {
        objectName: "updatesView"
        active: motion.surfaceVisible || root.viewPrepared

        UpdatesPopup {
            config: root.config
            targetScreen: root.menuScreen || root.targetScreen
            controller: root
            popupMotion: motion
            onCloseRequested: root.close()
        }
    }

    Process {
        id: checkProcess

        stdout: StdioCollector {
            onStreamFinished: root.handleReport(text)
        }
        stderr: StdioCollector {}
        onExited: exitCode => {
            root.checkExitCode = exitCode;
            if (!root.replyReceived)
                responseTimer.restart();
        }
    }

    // Process can report exit before StdioCollector finishes draining stdout.
    Timer {
        id: responseTimer
        interval: 1000
        onTriggered: {
            if (root.replyReceived)
                return;
            root.busy = false;
            root.errorText = root.checkExitCode === 0 ? "No response from the update helper" : "Could not check for updates";
        }
    }

    PopupIpcHandler {
        target: "updates"
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
