import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

import "../components"

Item {
    id: root

    required property var config
    required property var targetScreen

    property var themes: []
    property var recentThemes: []
    property int selectedIndex: 0
    property bool saveMode: false
    readonly property int recentLimit: 4

    readonly property string themesDir:
        Quickshell.env("HOME") + "/.config/wal/colorschemes/dark"
    readonly property string historyFile:
        Quickshell.env("HOME") + "/.cache/wal-theme-history"
    readonly property string cacheFile:
        Quickshell.env("HOME") + "/.cache/wal/colors.json"

    readonly property var menuEntries: {
        const entries = []

        for (let i = 0; i < recentThemes.length; ++i) {
            entries.push({
                type: "theme",
                name: recentThemes[i],
                recent: true
            })
        }

        if (recentThemes.length > 0 && themes.length > 0)
            entries.push({ type: "separator" })

        for (let i = 0; i < themes.length; ++i) {
            entries.push({
                type: "theme",
                name: themes[i],
                recent: false
            })
        }

        return entries
    }

    function openMenu(): void {
        saveMode = false
        selectedIndex = firstSelectableIndex()
        refreshProc.running = true
        themeMenu.visible = true
        Qt.callLater(() => keyboardHandler.forceActiveFocus())
    }

    function openSavePrompt(): void {
        saveMode = true
        saveInput.text = ""
        themeMenu.visible = true
        Qt.callLater(() => saveInput.forceActiveFocus())
    }

    function closeMenu(): void {
        saveMode = false
        themeMenu.visible = false
    }

    function saveTheme(): void {
        const name = normalizedThemeName(saveInput.text)

        if (name === "") {
            Quickshell.execDetached([
                "notify-send",
                "Invalid theme name",
                "Use letters, numbers, spaces, dots, underscores, or hyphens."
            ])
            return
        }

        saveProc.command = [
            "sh",
            "-lc",
            "cache=" + shellQuote(cacheFile) + "; "
                + "dest="
                + shellQuote(themesDir + "/" + name) + "; "
                + "if [ ! -f \"$cache\" ]; then "
                + "notify-send 'Error' "
                + "'No active Pywal theme found in cache.'; "
                + "exit 1; "
                + "fi; "
                + "mkdir -p " + shellQuote(themesDir) + "; "
                + "jq 'del(.checksum, .wallpaper, .alpha)' "
                + "\"$cache\" > \"$dest\" "
                + "&& notify-send 'Theme Saved' "
                + "\"Saved as $dest\""
        ]

        closeMenu()
        saveProc.running = true
    }

    function normalizedThemeName(input): string {
        let name = String(input).trim()

        if (name.toLowerCase().endsWith(".json"))
            name = name.slice(0, -5)

        if (!/^[A-Za-z0-9][A-Za-z0-9 ._-]*$/.test(name))
            return ""

        if (name.includes(".."))
            return ""

        return name + ".json"
    }

    function toggleMenu(): void {
        themeMenu.visible ? closeMenu() : openMenu()
    }

    function firstSelectableIndex(): int {
        for (let i = 0; i < menuEntries.length; ++i) {
            if (menuEntries[i].type === "theme")
                return i
        }

        return 0
    }

    function nextSelectable(from, direction): int {
        if (menuEntries.length === 0)
            return 0

        let index = from

        for (let i = 0; i < menuEntries.length; ++i) {
            index =
                (index + direction + menuEntries.length)
                % menuEntries.length

            if (menuEntries[index].type === "theme")
                return index
        }

        return from
    }

    function selectNext(): void {
        selectedIndex = nextSelectable(selectedIndex, 1)
    }

    function selectPrevious(): void {
        selectedIndex = nextSelectable(selectedIndex, -1)
    }

    function activateSelected(): void {
        if (selectedIndex < 0 || selectedIndex >= menuEntries.length)
            return

        const entry = menuEntries[selectedIndex]

        if (entry.type === "theme")
            applyTheme(entry.name)
    }

    function applyTheme(name): void {
        closeMenu()

        applyProc.command = [
            "sh",
            "-lc",
            "theme=" + shellQuote(name) + "; "
                + "history=" + shellQuote(historyFile) + "; "
                + "printf '%s\\n' \"$theme\" >> \"$history\"; "
                + "trimmed=$(tac \"$history\" 2>/dev/null "
                + "| awk '!seen[$0]++' | head -4 | tac); "
                + "printf '%s\\n' \"$trimmed\" > \"$history\"; "
                + "wal -e -n --theme \"$theme\" "
                + "&& vicinae theme set pywal "
                + "&& xrdb -merge -quiet "
                + shellQuote(
                    Quickshell.env("HOME")
                    + "/.cache/wal/colors.Xresources"
                )
        ]
        applyProc.running = true
    }

    function shellQuote(text): string {
        return "'" + String(text).replace(/'/g, "'\\''") + "'"
    }

    Process {
        id: refreshProc

        command: [
            "sh",
            "-lc",
            "themes=" + root.shellQuote(root.themesDir) + "; "
                + "history=" + root.shellQuote(root.historyFile) + "; "
                + "printf '%s\\n' '__RECENT__'; "
                + "tac \"$history\" 2>/dev/null "
                + "| awk '!seen[$0]++' | head -4; "
                + "printf '%s\\n' '__THEMES__'; "
                + "find \"$themes\" -type f -name '*.json' "
                + "-printf '%f\\n' 2>/dev/null "
                + "| sed 's/\\.json$//' | sort"
        ]

        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text
                    .split("\n")
                    .map(line => line.trim())
                    .filter(line => line.length > 0)

                const recent = []
                const all = []
                let section = ""

                for (let i = 0; i < lines.length; ++i) {
                    const line = lines[i]

                    if (line === "__RECENT__") {
                        section = "recent"
                        continue
                    }

                    if (line === "__THEMES__") {
                        section = "themes"
                        continue
                    }

                    if (section === "recent")
                        recent.push(line)
                    else if (section === "themes")
                        all.push(line)
                }

                root.recentThemes = recent
                root.themes = all
                root.selectedIndex = root.firstSelectableIndex()
            }
        }
    }

    Process {
        id: applyProc
    }

    Process {
        id: saveProc
    }

    PanelWindow {
        id: themeMenu

        screen: root.targetScreen

        anchors {
            top: true
            left: true
            right: true
            bottom: true
        }

        visible: false
        color: "transparent"
        exclusiveZone: 0
        focusable: true

        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: visible
            ? WlrKeyboardFocus.Exclusive
            : WlrKeyboardFocus.None

        MouseArea {
            anchors.fill: parent
            onClicked: root.closeMenu()
        }

        FocusScope {
            id: keyboardHandler

            anchors.fill: parent
            focus: !root.saveMode
            enabled: !root.saveMode

            Keys.onPressed: event => {
                switch (event.key) {
                case Qt.Key_Up:
                    root.selectPrevious()
                    event.accepted = true
                    return

                case Qt.Key_Down:
                    root.selectNext()
                    event.accepted = true
                    return

                case Qt.Key_Return:
                case Qt.Key_Enter:
                    root.activateSelected()
                    event.accepted = true
                    return

                case Qt.Key_Escape:
                    root.closeMenu()
                    event.accepted = true
                    return
                }
            }
        }

        PopoutPanel {
            id: menuCard

            z: 1
            visible: !root.saveMode
            config: root.config
            contentWidth: 230
            padding: 12
            spacing: 4

            anchors.top: parent.top
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.topMargin: root.config.popupGap

            Repeater {
                model: root.menuEntries

                delegate: Item {
                    id: menuItem

                    required property var modelData
                    required property int index

                    width: parent ? parent.width : 0
                    height: modelData.type === "separator" ? 9 : 32

                    readonly property bool isSeparator:
                        modelData.type === "separator"

                    readonly property bool selected:
                        !isSeparator
                        && root.selectedIndex === index

                    Rectangle {
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter

                        height: 1
                        visible: menuItem.isSeparator
                        color: root.config.borderColor
                    }

                    Rectangle {
                        anchors.fill: parent
                        visible: !menuItem.isSeparator
                        radius: 4
                        color: menuItem.selected || itemMouse.containsMouse
                            ? root.config.borderColor
                            : "transparent"
                    }

                    Text {
                        anchors.left: parent.left
                        anchors.leftMargin: 8
                        anchors.verticalCenter: parent.verticalCenter

                        width: 22
                        visible: !menuItem.isSeparator
                        color: root.config.accent
                        font.pointSize: root.config.fontSize(1)
                        horizontalAlignment: Text.AlignHCenter
                        text: !menuItem.isSeparator && modelData.recent
                            ? "★"
                            : ""
                    }

                    Text {
                        anchors.left: parent.left
                        anchors.leftMargin: 38
                        anchors.right: parent.right
                        anchors.rightMargin: 8
                        anchors.verticalCenter: parent.verticalCenter

                        visible: !menuItem.isSeparator
                        color: root.config.fg
                        font.pointSize: root.config.fontSize(1)
                        font.weight:
                            !menuItem.isSeparator && modelData.recent
                            ? Font.DemiBold
                            : Font.Medium
                        elide: Text.ElideRight
                        text: !menuItem.isSeparator
                            ? (modelData.name ?? "")
                            : ""
                    }

                    MouseArea {
                        id: itemMouse

                        anchors.fill: parent
                        enabled: !menuItem.isSeparator
                        hoverEnabled: enabled
                        cursorShape: enabled
                            ? Qt.PointingHandCursor
                            : Qt.ArrowCursor

                        onEntered:
                            root.selectedIndex = menuItem.index

                        onClicked:
                            root.applyTheme(menuItem.modelData.name)
                    }
                }
            }
        }

        PopoutPanel {
            id: savePanel

            z: 2
            visible: root.saveMode
            config: root.config
            contentWidth: 260
            padding: 10
            spacing: 8

            anchors.top: parent.top
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.topMargin: root.config.popupGap

            Text {
                width: parent.width
                color: root.config.fg
                font.pointSize: root.config.fontSize(1)
                font.weight: Font.DemiBold
                text: "Save theme"
            }

            Rectangle {
                width: parent.width
                height: 34
                radius: 4
                color: "transparent"
                border.width: 1
                border.color: saveInput.activeFocus
                    ? root.config.accent
                    : root.config.borderColor

                TextInput {
                    id: saveInput

                    anchors.fill: parent
                    anchors.leftMargin: 9
                    anchors.rightMargin: 9

                    verticalAlignment: TextInput.AlignVCenter
                    color: root.config.fg
                    selectionColor: root.config.accent
                    selectedTextColor: root.config.bg
                    font.pointSize: root.config.fontSize(1)

                    clip: true
                    selectByMouse: true

                    Keys.onReturnPressed: root.saveTheme()
                    Keys.onEnterPressed: root.saveTheme()
                    Keys.onEscapePressed: root.closeMenu()
                }

                Text {
                    anchors.left: parent.left
                    anchors.leftMargin: 9
                    anchors.verticalCenter: parent.verticalCenter

                    visible: saveInput.text.length === 0
                    color: root.config.muted
                    font.pointSize: root.config.fontSize(1)
                    text: "Theme name"
                }
            }

            Text {
                width: parent.width
                color: root.config.muted
                font.pointSize: root.config.fontSize(0.77)
                text: "Enter to save  •  Esc to cancel"
            }
        }
    }

    IpcHandler {
        target: "themeMenu"

        function toggle(): void {
            root.toggleMenu()
        }

        function open(): void {
            root.openMenu()
        }

        function close(): void {
            root.closeMenu()
        }

        function save(): void {
            root.openSavePrompt()
        }

        function refresh(): void {
            if (!refreshProc.running)
                refreshProc.running = true
        }
    }
}
