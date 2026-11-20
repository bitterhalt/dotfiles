// Removable-drive inventory helpers, shared by DriveService and its tests.
// Adapted from omarchy-drive-bay (MIT) by devmobasa.
//
// udisksctl monitor emits no initial inventory and its event lines are not
// stable API, so monitor output is only a dirty flag: any event line triggers
// a debounced `lsblk -J -b` snapshot, which is the single source of truth.
// Volumes shown are those on removable/hotplug/USB disks plus loop devices.
// Internal disks and udisks-ignored boot/recovery partitions never appear.

var MONITOR_BANNER = "Monitoring the udisks daemon";
var DAEMON_LINE = "The udisks-daemon is running";

// Hysteresis staging: many volumes collapse to one counted chip. The enter
// and exit thresholds differ so a volume appearing and disappearing right at
// the boundary cannot flap the row.
var COMPACT_ENTER = 5;
var COMPACT_EXIT = 3;

function monitorCommand() {
    return ["udisksctl", "monitor"];
}

function lsblkCommand() {
    return ["lsblk", "-J", "-b", "-o", "NAME,PATH,SIZE,TYPE,FSTYPE,LABEL,MOUNTPOINTS,RM,HOTPLUG,FSAVAIL,MODEL,TRAN,PARTTYPE,PARTTYPENAME"];
}

// Any timestamped udisks event line that is not a daemon banner marks the
// inventory dirty.
function isEventLine(line) {
    var text = String(line == null ? "" : line);
    if (text.indexOf(MONITOR_BANNER) !== -1)
        return false;
    if (text.indexOf(DAEMON_LINE) !== -1)
        return false;
    return /^\d\d:\d\d:\d\d\.\d\d\d: /.test(text) || /^\s+[A-Za-z]/.test(text);
}

function validDevicePath(path) {
    return /^\/dev\/[a-zA-Z0-9_\/-]+$/.test(String(path == null ? "" : path));
}

function validMountPath(path) {
    return typeof path === "string" && path.length > 1 && path.charAt(0) === "/";
}

function mountCommand(path) {
    if (!validDevicePath(path))
        return [];
    return ["udisksctl", "mount", "-b", path, "--no-user-interaction"];
}

function unmountCommand(path) {
    if (!validDevicePath(path))
        return [];
    return ["udisksctl", "unmount", "-b", path, "--no-user-interaction"];
}

function powerOffCommand(path) {
    if (!validDevicePath(path))
        return [];
    return ["udisksctl", "power-off", "-b", path, "--no-user-interaction"];
}

function openCommand(mountpoint) {
    if (!validMountPath(mountpoint))
        return [];
    return ["xdg-open", mountpoint];
}

function mountpointCommand(path) {
    if (!validDevicePath(path))
        return [];
    return ["lsblk", "-n", "-o", "MOUNTPOINTS", path];
}

function firstMountpoint(text) {
    var lines = String(text == null ? "" : text).split("\n");
    for (var i = 0; i < lines.length; i++) {
        var mountpoint = lines[i].trim();
        if (validMountPath(mountpoint))
            return mountpoint;
    }
    return "";
}

function formatSize(bytes) {
    var n = Number(bytes);
    if (!isFinite(n) || n <= 0)
        return "";
    if (n >= 1e12)
        return (n / 1e12).toFixed(1) + " TB";
    if (n >= 1e9)
        return (n / 1e9).toFixed(1) + " GB";
    if (n >= 1e6)
        return (n / 1e6).toFixed(0) + " MB";
    return Math.max(1, Math.round(n / 1e3)) + " kB";
}

// A disk qualifies when it is removable, hotplug, on the USB bus, or a loop
// device. zram never qualifies (rm/hotplug are already false, but filter the
// name defensively anyway).
function diskQualifies(node) {
    if (!node || typeof node !== "object")
        return false;
    if (String(node.name || "").indexOf("zram") === 0)
        return false;
    if (node.type === "loop")
        return true;
    if (node.type !== "disk")
        return false;
    return node.rm === true || node.hotplug === true || node.tran === "usb";
}

// Partition types udisks marks as not user-mountable (HintIgnore). Matching
// those hints keeps boot, recovery and volume-manager members out of the bar,
// just as Thunar hides them. The isohybrid live-media exception is handled
// separately so an installer's ISO partition remains visible.
var IGNORED_GPT_TYPES = [
    "c12a7328-f81f-11d2-ba4b-00a0c93ec93b",
    "21686148-6449-6e6f-744e-656564454649",
    "bc13c2ff-59e6-4262-a352-b275fd6f7172",
    "e3c9e316-0b5c-4db8-817d-f92df00215ae",
    "de94bba4-06d1-4d40-a16a-bfd50179d6ac",
    "426f6f74-0000-11aa-aa11-00306543ecac",
    "a19d880f-05fc-4d3b-a006-743f0f84911e",
    "e6d6d379-f507-44c2-a23c-238f2a3df928",
    "6a898cc3-1dd2-11b2-99a6-080020736631"
];

var IGNORED_DOS_TYPES = [
    "0x0", "0x11", "0x12", "0x14", "0x16", "0x17", "0x1b", "0x1c",
    "0x1e", "0x27", "0x3d", "0x84", "0x8d", "0x8e", "0x90", "0x91",
    "0x92", "0x93", "0x97", "0x98", "0x9a", "0x9b", "0xab", "0xbb",
    "0xc2", "0xc3", "0xdd", "0xef", "0xfd"
];

var IGNORED_RECOVERY_LABELS = [
    "recovery", "lenovo_recovery", "hp_recovery", "recovery_partition",
    "dellutility", "dellrestore", "ibm_service", "servicev001", "servicev002",
    "system_reserved", "winre_drv", "diags", "intelrst"
];

function ignoredPartition(node) {
    var type = String(node.parttype || "").toLowerCase();
    var fstype = String(node.fstype || "").toLowerCase();
    // isohybrid live media: the useful ISO lives in a normally hidden DOS type.
    if ((type === "0x0" || type === "0x17") && (fstype === "iso9660" || fstype === "udf"))
        return false;
    if (IGNORED_GPT_TYPES.indexOf(type) !== -1 || IGNORED_DOS_TYPES.indexOf(type) !== -1)
        return true;
    var label = String(node.label || "").toLowerCase();
    return (fstype === "ntfs" || fstype === "vfat") && IGNORED_RECOVERY_LABELS.indexOf(label) !== -1;
}

function mountpointsOf(node) {
    if (Array.isArray(node.mountpoints)) {
        return node.mountpoints.filter(function (mount) {
            return typeof mount === "string" && mount.length > 0;
        });
    }
    // Older lsblk releases expose only one `mountpoint` field.
    return typeof node.mountpoint === "string" && node.mountpoint.length > 0 ? [node.mountpoint] : [];
}

function volumeFrom(node, disk) {
    var mounts = mountpointsOf(node);
    var label = typeof node.label === "string" && node.label.length > 0 ? node.label : (typeof disk.model === "string" && disk.model.length > 0 ? String(disk.model) : String(node.name || ""));
    return {
        path: String(node.path || ""),
        diskPath: String(disk.path || ""),
        label: label,
        fstype: typeof node.fstype === "string" ? node.fstype : "",
        mounted: mounts.length > 0,
        mountpoint: mounts.length > 0 ? mounts[0] : "",
        size: formatSize(node.size),
        free: formatSize(node.fsavail),
        locked: node.fstype === "crypto_LUKS" && !(Array.isArray(node.children) && node.children.length > 0),
        loop: disk.type === "loop"
    };
}

// Flatten the lsblk tree into displayable volumes. For each qualifying disk:
// filesystem-bearing children (parts, and crypt mappers nested under LUKS
// parts), or the disk itself when it carries a filesystem directly (common for
// loop devices and superfloppy sticks). Swap is never displayed.
function volumesFrom(blockdevices) {
    var out = [];
    for (var i = 0; i < blockdevices.length; i++) {
        var disk = blockdevices[i];
        if (!diskQualifies(disk))
            continue;
        var stack = Array.isArray(disk.children) ? disk.children.slice() : [];
        if (stack.length === 0 && typeof disk.fstype === "string" && disk.fstype.length > 0) {
            if (disk.fstype !== "swap" && !ignoredPartition(disk))
                out.push(volumeFrom(disk, disk));
            continue;
        }
        while (stack.length > 0) {
            var node = stack.shift();
            if (!node || typeof node !== "object")
                continue;
            if (Array.isArray(node.children) && node.children.length > 0) {
                for (var c = 0; c < node.children.length; c++)
                    stack.push(node.children[c]);
                if (node.fstype === "crypto_LUKS")
                    continue;
            }
            if (typeof node.fstype === "string" && node.fstype.length > 0 && node.fstype !== "swap" && !ignoredPartition(node))
                out.push(volumeFrom(node, disk));
        }
    }
    out.sort(function (a, b) {
        return a.path < b.path ? -1 : 1;
    });
    return out;
}

function parseLsblkResult(text) {
    var parsed = null;
    try {
        parsed = JSON.parse(text);
    } catch (error) {
        parsed = null;
    }
    if (!parsed || !Array.isArray(parsed.blockdevices))
        return {
            valid: false,
            volumes: []
        };
    return {
        valid: true,
        volumes: volumesFrom(parsed.blockdevices)
    };
}

function parseLsblk(text) {
    return parseLsblkResult(text).volumes;
}

function findVolume(volumes, path) {
    var list = Array.isArray(volumes) ? volumes : [];
    for (var i = 0; i < list.length; i++) {
        if (list[i] && list[i].path === path)
            return list[i];
    }
    return null;
}

function tooltip(volume, error) {
    if (!volume)
        return "";
    if (error)
        return "Drive bay: " + error;
    if (volume.locked)
        return "locked (unlock via terminal)";
    if (volume.mounted) {
        var state = volume.free !== "" ? "mounted (" + volume.free + " free)" : "mounted";
        return state + "\nclick to open · right-click to unmount";
    }
    return "click to mount and open";
}

function nextCompactStage(compact, count) {
    var n = Number(count);
    if (!isFinite(n) || n < 0)
        n = 0;
    if (compact === true)
        return n > COMPACT_EXIT;
    return n >= COMPACT_ENTER;
}

function compactTooltip(volumes) {
    var list = Array.isArray(volumes) ? volumes : [];
    var mounted = 0;
    for (var i = 0; i < list.length; i++) {
        if (list[i] && list[i].mounted)
            mounted++;
    }
    return list.length + " removable volumes · " + mounted + " mounted\nclick to expand";
}
