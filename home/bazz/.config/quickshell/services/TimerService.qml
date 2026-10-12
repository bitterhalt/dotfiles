import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: root

    property var timers: []
    property var pendingTimer: null
    readonly property string timersPath: (Quickshell.env("HOME") || "") + "/.cache/quickshell-timers.json"

    function persist() {
        timersFile.setText(JSON.stringify(timers));
    }

    function pruneExpired(now) {
        const remaining = timers.filter((timer) => {
            return timer.endAt > now;
        });
        if (remaining.length !== timers.length) {
            timers = remaining;
            persist();
        }
    }

    function startTimer(seconds, note) {
        if (startProcess.running || seconds <= 0)
            return ;

        const unit = "quickshell-timer-" + Date.now().toString(36) + "-" + Math.random().toString(36).slice(2, 8);
        const message = note || "Timer finished";
        pendingTimer = {
            "unit": unit,
            "note": note,
            "endAt": Date.now() + seconds * 1000
        };
        startProcess.command = ["systemd-run", "--user", "--quiet", "--collect", "--unit", unit, "--on-active", seconds + "s", "--timer-property", "AccuracySec=1s", "notify-send", "-a", "QuickShell Timer", "-t", "60000", "Timer finished", message];
        startProcess.running = true;
    }

    function cancelTimer(unit) {
        timers = timers.filter((timer) => {
            return timer.unit !== unit;
        });
        persist();
        Quickshell.execDetached(["systemctl", "--user", "stop", unit + ".timer"]);
    }

    visible: false

    Process {
        id: startProcess

        onExited: (exitCode) => {
            if (exitCode === 0 && root.pendingTimer) {
                root.timers = root.timers.concat([root.pendingTimer]);
                root.persist();
            }
            root.pendingTimer = null;
        }
    }

    FileView {
        id: timersFile

        path: root.timersPath
        atomicWrites: true
        printErrors: false
        onLoaded: {
            try {
                const saved = JSON.parse(text());
                root.timers = Array.isArray(saved) ? saved.filter((timer) => {
                    return timer.unit && timer.endAt > Date.now();
                }) : [];
                root.persist();
            } catch (error) {
                root.timers = [];
            }
        }
    }

}
