import QtQuick
import Quickshell
import Quickshell.Io
import "idle/Duration.js" as Duration

// UI-managed preferences and their first-run defaults.
Item {
    id: root
    visible: false

    property bool settingsLoaded: false
    property bool updating: false
    readonly property bool applying: updating
    property int lockTimeout: 1200
    property int offTimeout: 1800
    property int suspendTimeout: 7200
    property string hellwalMode: "dark"
    property real hellwalDarkOffset: 0
    property real hellwalBrightOffset: 0
    property real hellwalGrayScale: 0
    property string hellwalBackgroundMode: "dynamic"
    property string hellwalBackgroundColor: "#111111"
    property string workspaceLayout: "dots"

    function saveTimeouts(lockSeconds, offSeconds, suspendSeconds) {
        const error = Duration.validate(lockSeconds, offSeconds, suspendSeconds);
        if (error !== "")
            return error;
        if (!settingsLoaded)
            return "Settings are still loading";
        updating = true;
        lockTimeout = lockSeconds;
        offTimeout = offSeconds;
        suspendTimeout = suspendSeconds;
        persistSettings();
        updating = false;
        return "";
    }

    function saveHellwalSettings(mode, darkOffset, brightOffset, backgroundMode, backgroundColor, grayScale) {
        if (mode !== "dark" && mode !== "light")
            return "Choose dark or light mode";
        if (!Number.isFinite(darkOffset) || darkOffset < 0 || darkOffset > 1 || !Number.isFinite(brightOffset) || brightOffset < 0 || brightOffset > 1)
            return "Offsets must be between 0 and 1";
        const nextGrayScale = grayScale === undefined ? hellwalGrayScale : grayScale;
        if (!Number.isFinite(nextGrayScale) || nextGrayScale < 0 || nextGrayScale > 1)
            return "Grayscale must be between 0 and 1";
        if (!settingsLoaded)
            return "Settings are still loading";
        const nextBackgroundMode = backgroundMode === undefined ? hellwalBackgroundMode : backgroundMode;
        const nextBackgroundColor = backgroundColor === undefined ? hellwalBackgroundColor : String(backgroundColor).trim();
        if (nextBackgroundMode !== "dynamic" && nextBackgroundMode !== "fixed")
            return "Choose dynamic or fixed background";
        const validColor = /^#[0-9a-fA-F]{6}$/.test(nextBackgroundColor);
        if (nextBackgroundMode === "fixed" && !validColor)
            return "Enter a hex color like #111111";
        hellwalMode = mode;
        hellwalDarkOffset = darkOffset;
        hellwalBrightOffset = brightOffset;
        hellwalGrayScale = nextGrayScale;
        hellwalBackgroundMode = nextBackgroundMode;
        if (validColor)
            hellwalBackgroundColor = nextBackgroundColor;
        persistSettings();
        return "";
    }

    function saveWorkspaceLayout(layout) {
        if (layout !== "dots" && layout !== "minimal")
            return "Choose dots or minimal layout";
        if (!settingsLoaded)
            return "Settings are still loading";
        workspaceLayout = layout;
        persistSettings();
        return "";
    }

    function persistSettings() {
        settingsFile.setText(JSON.stringify({
            lock: lockTimeout,
            off: offTimeout,
            suspend: suspendTimeout,
            hellwalMode,
            hellwalDarkOffset,
            hellwalBrightOffset,
            hellwalGrayScale,
            workspaceLayout,
            hellwalBackgroundMode,
            hellwalBackgroundColor
        }));
    }

    FileView {
        id: settingsFile
        // Keep the existing path and JSON keys: no migration or reset needed.
        path: (Quickshell.env("XDG_DATA_HOME") || Quickshell.env("HOME") + "/.local/share") + "/quickshell-settings.json"
        atomicWrites: true
        printErrors: false
        onLoaded: {
            root.updating = true;
            try {
                const saved = JSON.parse(text());
                if (Duration.validate(saved.lock, saved.off, saved.suspend) === "") {
                    root.lockTimeout = saved.lock;
                    root.offTimeout = saved.off;
                    root.suspendTimeout = saved.suspend;
                }
                if (saved.hellwalMode === "dark" || saved.hellwalMode === "dark-comfort")
                    root.hellwalMode = "dark";
                else if (saved.hellwalMode === "light" || saved.hellwalMode === "light-comfort")
                    root.hellwalMode = "light";
                if (Number.isFinite(saved.hellwalDarkOffset) && saved.hellwalDarkOffset >= 0 && saved.hellwalDarkOffset <= 1)
                    root.hellwalDarkOffset = saved.hellwalDarkOffset;
                if (Number.isFinite(saved.hellwalBrightOffset) && saved.hellwalBrightOffset >= 0 && saved.hellwalBrightOffset <= 1)
                    root.hellwalBrightOffset = saved.hellwalBrightOffset;
                if (Number.isFinite(saved.hellwalGrayScale) && saved.hellwalGrayScale >= 0 && saved.hellwalGrayScale <= 1)
                    root.hellwalGrayScale = saved.hellwalGrayScale;
                if (saved.workspaceLayout === "dots" || saved.workspaceLayout === "minimal")
                    root.workspaceLayout = saved.workspaceLayout;
                if (typeof saved.hellwalBackgroundColor === "string" && /^#[0-9a-fA-F]{6}$/.test(saved.hellwalBackgroundColor))
                    root.hellwalBackgroundColor = saved.hellwalBackgroundColor;
                if (saved.hellwalBackgroundMode === "dynamic" || saved.hellwalBackgroundMode === "fixed")
                    root.hellwalBackgroundMode = saved.hellwalBackgroundMode;
            } catch (error) {}
            root.updating = false;
            root.settingsLoaded = true;
        }
        onLoadFailed: root.settingsLoaded = true
    }
}
