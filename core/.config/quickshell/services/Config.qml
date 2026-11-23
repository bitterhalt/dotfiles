import QtQuick
import Quickshell
import Quickshell.Io
import "config/Schema.js" as Schema

Item {
    id: config

    required property var theme
    property var values: Schema.defaults()
    property bool ready: false
    property bool applying: false
    readonly property real fontScale: values.fontScale
    readonly property real iconScale: values.iconScale
    readonly property string iconFontFamily: values.iconFontFamily
    readonly property real maxVolume: values.maxVolume
    readonly property int barHeight: values.barHeight
    readonly property bool showTray: values.showTray
    readonly property bool launcherEnabled: values.launcherEnabled
    readonly property string clockFormat: values.clockFormat
    readonly property string clockAlternativeFormat: values.clockAlternativeFormat
    readonly property int popupGap: values.popupGap
    readonly property int popupRadius: values.popupRadius
    // Internal layout rhythm; popupGap remains the window-to-screen gap.
    readonly property int spacingTight: 4
    readonly property int spacingControl: 8
    readonly property int panelPadding: 12
    readonly property int previewPadding: 16
    readonly property bool popupAnimations: values.popupAnimations
    readonly property int notificationHistoryLimit: values.notificationHistoryLimit
    readonly property var notificationHistoryExcludedApps: values.notificationHistoryExcludedApps
    readonly property int bluetoothBatteryWarningPercent: values.bluetoothBatteryWarningPercent
    readonly property int bluetoothBatteryCriticalPercent: values.bluetoothBatteryCriticalPercent
    readonly property int bluetoothBatteryRearmMargin: values.bluetoothBatteryRearmMargin
    // Semantic palette supplied by ThemeService, with its own fallback palette.
    readonly property color border: theme.border
    readonly property color bg: theme.bg
    readonly property color fg: theme.fg
    readonly property color muted: theme.muted
    readonly property color urgent: theme.urgent
    readonly property color selectionBackground: theme.selectionBackground
    readonly property color selectionForeground: theme.selectionForeground
    readonly property string textFontFamily: systemFontMetrics.font.family
    readonly property real systemFontPointSize: systemFontMetrics.font.pointSize > 0 ? systemFontMetrics.font.pointSize : 10
    readonly property real fontSize: systemFontPointSize * fontScale
    readonly property real textSizeNormal: fontSize
    readonly property real textSizeMedium: fontSize * 0.88
    readonly property real textSizeSmall: fontSize * 0.78
    readonly property real iconSize: fontSize * iconScale

    function run(command) {
        Quickshell.execDetached(["sh", "-lc", command]);
    }

    // Settings menu entry point: validate, apply and save one value.
    // Returns an error message, or "" on success.
    function setValue(name, value) {
        let error = Schema.check(name, value);
        if (error !== "")
            return error;
        const next = Object.assign({}, values);
        next[name] = Array.isArray(value) ? value.slice() : value;
        error = Schema.checkAll(next);
        if (error !== "")
            return error;
        values = next;
        settingsFile.setText(JSON.stringify(Schema.toDocument(values), null, 2) + "\n");
        return "";
    }

    function applySettings(text) {
        try {
            const parsed = Schema.parse(text);
            // Our own writes come back through the file watcher; ignore no-op reloads.
            if (JSON.stringify(parsed.values) !== JSON.stringify(values)) {
                applying = true;
                values = parsed.values;
            }
            if (parsed.warnings.length > 0)
                console.warn("quickshell-config.json: using defaults for " + parsed.warnings.join(", "));
        } catch (error) {
            console.warn("Invalid quickshell-config.json; keeping previous settings");
        }
        applying = false;
        ready = true;
    }

    visible: false
    Component.onCompleted: {
        const initial = settingsFile.text();
        if (!ready)
            applySettings(initial);
    }

    FileView {
        id: settingsFile

        // Written by the Settings menu; still reloads when edited by hand.
        path: (Quickshell.env("XDG_DATA_HOME") || Quickshell.env("HOME") + "/.local/share") + "/quickshell-config.json"
        blockLoading: true
        watchChanges: true
        atomicWrites: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: config.applySettings(text())
        // First run: no file yet, so the built-in defaults stay in effect.
        onLoadFailed: config.ready = true
    }

    FontMetrics {
        id: systemFontMetrics
    }
}
