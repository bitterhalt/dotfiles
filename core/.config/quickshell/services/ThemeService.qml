import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: root
    visible: false

    // Fallback palette (used when hellwal output is missing or invalid)
    readonly property color fallbackBg: "#100f0f"
    readonly property color fallbackFg: "#cecdc3"
    readonly property color fallbackSelectionBackground: "#205ea6"
    readonly property color fallbackSelectionForeground: "#ffffff"
    readonly property color fallbackUrgent: "#bc5215"

    // Shared derivation values so fallback and palette paths stay consistent
    readonly property real mutedAlpha: 0.65
    readonly property real borderAlpha: 0.45

    readonly property color fallbackMuted: Qt.alpha(fallbackFg, mutedAlpha)

    // Active theme colors
    property color bg: fallbackBg
    property color fg: fallbackFg
    property color muted: fallbackMuted
    property color urgent: fallbackUrgent
    property color selectionBackground: fallbackSelectionBackground
    property color selectionForeground: fallbackSelectionForeground

    // Binding: updates automatically whenever selectionBackground changes
    readonly property color border: Qt.alpha(selectionBackground, borderAlpha)
    // readonly property color border: Qt.tint(bg, Qt.alpha(selectionBackground, borderAlpha))

    property bool hellwalActive: false

    // Regex building blocks, defined once to avoid copy/paste typos
    readonly property string colorNames: "(background|foreground|selection_background|selection_foreground|color(?:1[0-5]|[0-9]))"
    readonly property string hexValue: "(#[0-9a-fA-F]{6}(?:[0-9a-fA-F]{2})?)"

    function applyFallback(): void {
        bg = fallbackBg;
        fg = fallbackFg;
        muted = fallbackMuted;
        urgent = fallbackUrgent;
        selectionBackground = fallbackSelectionBackground;
        selectionForeground = fallbackSelectionForeground;
        hellwalActive = false;
    }

    function parsePalette(text): var {
        const colors = {};

        const patterns = [
            // GTK:   @define-color name #hex
            new RegExp("@define-color\\s+" + colorNames + "\\s+" + hexValue, "g"),
            // CSS:   --name: #hex
            new RegExp("--" + colorNames + "\\s*:\\s*" + hexValue, "g"),
            // SCSS:  $name: #hex
            new RegExp("\\$" + colorNames + "\\s*:\\s*" + hexValue, "g"),];

        for (const re of patterns) {
            let match;
            while ((match = re.exec(text)) !== null)
                colors[match[1]] = match[2];
        }

        const required = ["background", "foreground", "color3", "color6",];

        for (let i = 0; i < required.length; ++i) {
            if (!colors[required[i]])
                return null;
        }

        return colors;
    }

    function applyPalette(text): void {
        const colors = parsePalette(text);

        if (!colors) {
            applyFallback();
            return;
        }

        bg = colors.background;
        fg = colors.foreground;
        muted = Qt.alpha(colors.foreground, mutedAlpha);
        urgent = colors.color3;
        selectionBackground = colors.color6;
        selectionForeground = colors.background;
        hellwalActive = true;
    }

    function refresh(): void {
        paletteFile.reload();
    }

    FileView {
        id: paletteFile

        path: Quickshell.env("HOME") + "/.cache/hellwal/colors.css"
        watchChanges: true
        printErrors: false

        onLoaded: root.applyPalette(text())
        onFileChanged: reload()
        onLoadFailed: root.applyFallback()
    }

    IpcHandler {
        target: "theme"

        function refresh(): void {
            root.refresh();
        }

        function usingHellwal(): bool {
            return root.hellwalActive;
        }
    }
}
