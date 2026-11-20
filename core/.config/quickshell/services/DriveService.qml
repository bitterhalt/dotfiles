import QtQuick
import Quickshell
import Quickshell.Io
import "drives/DriveModel.js" as DriveModel

// One event-driven udisks2 inventory shared by every screen's bar. Monitor
// output is only a dirty trigger; `lsblk` snapshots are the source of truth.
Item {
    id: root

    visible: false

    property var resumeService: null
    property var volumes: []
    property string errorText: ""
    property string inventoryError: ""
    property string busyPath: ""
    property string pendingOpenPath: ""
    property bool compact: false

    readonly property bool present: volumes.length > 0
    readonly property bool refreshing: lsblkProcess.running

    function start(process): void {
        process.exitSeen = false;
        process.running = true;
    }

    function refresh(): void {
        if (lsblkProcess.running)
            return;
        start(lsblkProcess);
    }

    function applySnapshot(text): void {
        const result = DriveModel.parseLsblkResult(text);
        if (!result.valid) {
            inventoryError = "Could not read the drive list";
            return;
        }
        volumes = result.volumes;
        compact = DriveModel.nextCompactStage(compact, volumes.length);
        inventoryError = "";
    }

    function perform(command, path): bool {
        if (command.length === 0) {
            errorText = "Invalid device path";
            return false;
        }
        if (actionProcess.running || busyPath !== "")
            return false;
        errorText = "";
        busyPath = path;
        actionProcess.command = command;
        start(actionProcess);
        return true;
    }

    function mount(path): bool {
        return perform(DriveModel.mountCommand(path), path);
    }

    // Bar click on an unmounted volume: mount it, then open the new mountpoint
    // once udisks reports success.
    function mountAndOpen(path): bool {
        if (!mount(path))
            return false;
        pendingOpenPath = path;
        return true;
    }

    function unmount(path): bool {
        return perform(DriveModel.unmountCommand(path), path);
    }

    function powerOff(path): bool {
        return perform(DriveModel.powerOffCommand(path), path);
    }

    function open(path): bool {
        const volume = DriveModel.findVolume(volumes, path);
        if (!volume || !volume.mounted || volume.mountpoint === "") {
            errorText = "Drive is not mounted";
            return false;
        }
        const command = DriveModel.openCommand(volume.mountpoint);
        if (command.length === 0) {
            errorText = "Invalid mountpoint";
            return false;
        }
        errorText = "";
        Quickshell.execDetached(command);
        return true;
    }

    // `udisksctl mount` prints a human-readable line, so resolve the new
    // mountpoint from lsblk instead of racing the inventory snapshot.
    function lookupMountpoint(path): void {
        if (mountLookupProcess.running)
            return;
        const command = DriveModel.mountpointCommand(path);
        if (command.length === 0)
            return;
        mountLookupProcess.command = command;
        mountLookupProcess.running = true;
    }

    function openFirstMountpoint(text): void {
        const mountpoint = DriveModel.firstMountpoint(text);
        if (mountpoint === "")
            return;
        const command = DriveModel.openCommand(mountpoint);
        if (command.length > 0)
            Quickshell.execDetached(command);
    }

    // Bar click: open a mounted volume, mount and open an unmounted one.
    // Locked LUKS volumes stay inert until unlocked outside the bar.
    function activate(volume): bool {
        if (!volume || volume.locked)
            return false;
        return volume.mounted ? open(volume.path) : mountAndOpen(volume.path);
    }

    Component.onCompleted: refresh()

    Connections {
        target: root.resumeService
        enabled: root.resumeService !== null

        function onResumed(): void {
            root.refresh();
        }
    }

    // Hotplug trigger. `udisksctl monitor` emits no inventory, only change
    // events, so any event line restarts the debounce timer.
    Process {
        id: monitorProcess
        objectName: "driveMonitorProcess"
        property bool exitSeen: false
        running: true
        command: DriveModel.monitorCommand()

        stdout: SplitParser {
            onRead: line => {
                if (DriveModel.isEventLine(line))
                    debounceTimer.restart();
            }
        }

        stderr: StdioCollector {}

        onRunningChanged: {
            if (running)
                return;
            if (!exitSeen)
                root.inventoryError = "udisksctl could not be started";
            reconnectTimer.restart();
        }

        onExited: exitSeen = true
    }

    Timer {
        id: debounceTimer
        objectName: "driveDebounceTimer"
        interval: 300
        onTriggered: root.refresh()
    }

    // udisksd may restart or the system bus may briefly drop.
    Timer {
        id: reconnectTimer
        objectName: "driveReconnectTimer"
        interval: 5000
        onTriggered: {
            if (!monitorProcess.running) {
                monitorProcess.exitSeen = false;
                monitorProcess.running = true;
            }
            root.refresh();
        }
    }

    Process {
        id: lsblkProcess
        objectName: "driveLsblkProcess"
        property bool exitSeen: false
        command: DriveModel.lsblkCommand()

        stdout: StdioCollector {
            onStreamFinished: root.applySnapshot(text)
        }

        stderr: StdioCollector {
            onStreamFinished: {
                const message = text.trim();
                if (message !== "")
                    root.inventoryError = message.split("\n")[0];
            }
        }

        onRunningChanged: if (!running && !exitSeen)
            root.inventoryError = "lsblk could not be started"

        onExited: exitSeen = true
    }

    Process {
        id: actionProcess
        objectName: "driveActionProcess"
        property bool exitSeen: false
        command: ["true"]

        stderr: StdioCollector {
            onStreamFinished: {
                const message = text.trim();
                if (message !== "")
                    root.errorText = message.split("\n")[0];
            }
        }

        onRunningChanged: {
            if (!running && !exitSeen) {
                root.busyPath = "";
                root.pendingOpenPath = "";
                root.errorText = "udisksctl could not be started";
            }
        }

        onExited: function (exitCode) {
            exitSeen = true;
            root.busyPath = "";
            const openPath = root.pendingOpenPath;
            root.pendingOpenPath = "";
            if (exitCode === 0 && openPath !== "")
                root.lookupMountpoint(openPath);
            root.refresh();
        }
    }

    Process {
        id: mountLookupProcess
        objectName: "driveMountLookupProcess"
        command: ["true"]

        stdout: StdioCollector {
            onStreamFinished: root.openFirstMountpoint(text)
        }

        stderr: StdioCollector {}
    }

    // Scriptable surface:
    //   qs ipc call drives status | refresh | mount <dev> | unmount <dev>
    //   qs ipc call drives poweroff <dev> | open <dev>
    IpcHandler {
        objectName: "driveIpcHandler"
        target: "drives"

        function status(): string {
            return JSON.stringify({
                volumes: root.volumes,
                error: root.errorText,
                inventoryError: root.inventoryError
            });
        }

        function refresh(): void {
            root.refresh();
        }

        function mount(path: string): string {
            return root.mount(path) ? "ok" : "error";
        }

        function unmount(path: string): string {
            return root.unmount(path) ? "ok" : "error";
        }

        function poweroff(path: string): string {
            return root.powerOff(path) ? "ok" : "error";
        }

        function open(path: string): string {
            return root.open(path) ? "ok" : "error";
        }
    }
}
