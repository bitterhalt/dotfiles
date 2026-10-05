import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: root
    visible: false

    readonly property color fallbackBg: "#100f0f"
    readonly property color fallbackSurface: "#1c1b1a"
    readonly property color fallbackBorder: "#343331"
    readonly property color fallbackFg: "#cecdc3"
    readonly property color fallbackMuted: "#878580"
    readonly property color fallbackAccent: "#205ea6"
    readonly property color fallbackUrgent: "#bc5215"

    property color bg: fallbackBg
    property color surface: fallbackSurface
    property color borderColor: fallbackBorder
    property color fg: fallbackFg
    property color muted: fallbackMuted
    property color accent: fallbackAccent
    property color urgent: fallbackUrgent

    property bool pywalActive: false

    function applyFallback(): void {
        bg = fallbackBg
        surface = fallbackSurface
        borderColor = fallbackBorder
        fg = fallbackFg
        muted = fallbackMuted
        accent = fallbackAccent
        urgent = fallbackUrgent
        pywalActive = false
    }

    function parsePalette(text): var {
        const colors = {}
        let match

        let re = /@define-color\s+(background|foreground|color(?:1[0-5]|[0-9]))\s+(#[0-9a-fA-F]{6}(?:[0-9a-fA-F]{2})?)/g
        while ((match = re.exec(text)) !== null)
            colors[match[1]] = match[2]

        re = /--(background|foreground|color(?:1[0-5]|[0-9]))\s*:\s*(#[0-9a-fA-F]{6}(?:[0-9a-fA-F]{2})?)/g
        while ((match = re.exec(text)) !== null)
            colors[match[1]] = match[2]

        re = /\$(background|foreground|color(?:1[0-5]|[0-9]))\s*:\s*(#[0-9a-fA-F]{6}(?:[0-9a-fA-F]{2})?)/g
        while ((match = re.exec(text)) !== null)
            colors[match[1]] = match[2]

        const required = [
            "background",
            "foreground",
            "color0",
            "color1",
            "color4",
            "color8"
        ]

        for (let i = 0; i < required.length; ++i) {
            if (!colors[required[i]])
                return null
        }

        return colors
    }

    function applyPalette(text): void {
        const colors = parsePalette(text)

        if (!colors) {
            applyFallback()
            return
        }

        bg = colors.background
        surface = colors.color0
        borderColor = colors.color1
        fg = colors.foreground
        muted = colors.color8
        accent = colors.color4
        urgent = colors.color1
        pywalActive = true
    }

    function refresh(): void {
        paletteFile.reload()
    }

    FileView {
        id: paletteFile

        path: Quickshell.env("HOME") + "/.cache/wal/colors.css"
        watchChanges: true
        printErrors: false

        onLoaded: root.applyPalette(text())
        onFileChanged: reload()
        onLoadFailed: root.applyFallback()
    }

    IpcHandler {
        target: "theme"

        function refresh(): void {
            root.refresh()
        }

        function usingPywal(): bool {
            return root.pywalActive
        }
    }
}
