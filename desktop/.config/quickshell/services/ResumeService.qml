import QtQuick
import Quickshell.Io

// One event-driven logind listener per process, shared by every screen's clock.
Item {
    id: root
    visible: false
    property bool awaitingSleepState: false
    signal resumed

    function handleLine(line): void {
        if (line.startsWith("signal ")) {
            awaitingSleepState = line.includes("path=/org/freedesktop/login1;") && line.includes("interface=org.freedesktop.login1.Manager;") && /member=PrepareForSleep\s*$/.test(line);
            return;
        }
        if (!awaitingSleepState)
            return;
        const state = /^\s*boolean (true|false)\s*$/.exec(line);
        if (state) {
            awaitingSleepState = false;
            if (state[1] === "false")
                resumed();
        }
    }

    Process {
        id: monitor
        objectName: "resumeMonitor"
        running: true
        command: ["dbus-monitor", "--system", "type='signal',sender='org.freedesktop.login1',path='/org/freedesktop/login1',interface='org.freedesktop.login1.Manager',member='PrepareForSleep'"]
        stdout: SplitParser {
            onRead: data => root.handleLine(data)
        }
        stderr: StdioCollector {}
        onExited: {
            root.awaitingSleepState = false;
            reconnectTimer.restart();
        }
    }

    // Recover if the system bus temporarily disconnects.
    Timer {
        id: reconnectTimer
        interval: 5000
        onTriggered: monitor.running = true
    }
}
