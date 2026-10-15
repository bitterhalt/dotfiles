import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

import "../components"

Item {
    id: root

    required property var config
    required property var themeMenu
    required property var tmuxMenu
    required property var targetScreen
    required property var lockService
    required property var idleService

    property string page: ""
    property int selectedIndex: 0
    property var menuScreen: null

    readonly property var powerItems: [
        { label: "Lock", icon: "󰌾", shortcut: "l", action: "lock" },
        { label: "Log out", icon: "󰍃", shortcut: "E", command: "niri msg action quit" },
        { label: "Sleep", icon: "󰤄", shortcut: "z", action: "suspend" },
        { label: "Restart", icon: "󰜉", shortcut: "R", command: "systemctl reboot" },
        { label: "Shut down", icon: "󰐥", shortcut: "S", command: "systemctl poweroff" }
    ]


    readonly property var packagesItems: [
        { label: "Install Packages", icon: "󰏗", shortcut: "i", command: "foot -a pacseek -T pacseek -e pacseek -m" },
        { label: "Update", icon: "󰑐", shortcut: "u", command: "foot -a pop-upgrade -e sup" }
    ]


    readonly property var settingsItems: [
        { label: "Niri", icon: "󰖲", shortcut: "n", command: "foot sh -c 'cd ~/.config/niri/ && nvim *'" },
        { label: "Nvim", icon: "", shortcut: "v", command: "foot sh -c 'cd ~/.config/nvim && vopen .'" },
        { label: "Pywal", icon: "󰏘", shortcut: "p", command: "foot -e nvim ~/.local/bin/setbg ~/.config/wal/templates/*" },
        { label: "Quickshell", icon: "󰆍", shortcut: "q", command: "foot sh -c 'cd ~/.config/quickshell && vopen .'" },
    ]

    readonly property var systemItems: [
        { label: "Wiremix", icon: "󰓃", shortcut: "a", command: "foot -a wiremix -e wiremix" },
        { label: "Bluetooth", icon: "󰂯", shortcut: "b", command: "foot -a bluetui -e bluetui" },
        { label: "Wi-Fi", icon: "󰖩", shortcut: "w", command: "foot -a impala -e impala" },
        { label: "Network Manager", icon: "󰲝", shortcut: "n", command: "foot -e nmtui" },
        { label: "Update System", icon: "󰑐", shortcut: "u", command: "foot -a pop-upgrade -e sup" },
        { label: "Idle Settings", icon: "󰤄", shortcut: "i", action: "idleSettings" },
        { label: "Monitor", icon: "󰨇", shortcut: "m", page: "monitor" },
    ]

    readonly property var monitorItems: [
        { label: "Atop [AMD GPU Monitor]", icon: "󰾲", shortcut: "a", command: "foot -T atop -e amdgpu_top --smi" },
        { label: "Btop [System Monitor]", icon: "󰨇", shortcut: "b", command: "foot -a btop -e btop" },
        { label: "Nethogs [Network Monitor]", icon: "󰛳", shortcut: "n", command: "foot -a nethogs -e nethogs" },
        { label: "Logs", icon: "󰌱", shortcut: "l", command: "foot -a foot -T journalctl -e journalctl -f" },
        { label: "Combined", icon: "󰕮", shortcut: "c", command: "foot -a Sysmon -T Sysmon -e ~/.local/bin/tmux-sysmon.sh" }
    ]

    readonly property var notesItems: [
        { label: "Search", icon: "󰍉", shortcut: "s", command: "foot -a fzf_notes -e ~/.local/bin/menu_notes" },
        { label: "New Note", icon: "󰎚", shortcut: "n", command: "foot -e ~/.local/bin/menu_notes -c" },
        { label: "TODO", icon: "", shortcut: "t", command: "foot -a noteterm -T Notes sh -c 'cd ~/Documents/personal/notes/ && nvim todo.md'" },
        { label: "Delete", icon: "󰩹", shortcut: "d", command: "foot -e ~/.local/bin/menu_notes -d" }
    ]

    readonly property var themingItems: [
        { label: "Set wallpaper", icon: "󰸉", shortcut: "w", command: "swayimg --appid swayimg-setwall -g ~/Pictures/wallpaper/" },
        { label: "Set theme", icon: "󰏘", shortcut: "t", action: "theme" },
        { label: "Save theme", icon: "󰆓", shortcut: "s", action: "saveTheme" }
    ]

    readonly property var currentItems: {
        switch (page) {
        case "power":
            return powerItems
        case "packages":
            return packagesItems
        case "settings":
            return settingsItems
        case "system":
            return systemItems
        case "monitor":
            return monitorItems
        case "notes":
            return notesItems
        case "theming":
            return themingItems
        default:
            return []
        }
    }

    readonly property string title: {
        switch (page) {
        case "power":
            return "Power"
        case "packages":
            return "Packages"
        case "settings":
            return "Edit configs"
        case "system":
            return "Settings"
        case "monitor":
            return "Monitor"
        case "notes":
            return "Notes"
        case "theming":
            return "Theming"
        default:
            return ""
        }
    }

    function openPage(name, screen): void {
        page = name
        menuScreen = screen || targetScreen
        selectedIndex = 0
        menuWindow.visible = true
        Qt.callLater(() => keyboardHandler.forceActiveFocus())
    }

    function closeMenu(): void {
        menuWindow.visible = false
        menuScreen = null
    }

    function togglePower(screen): void {
        if (menuWindow.visible && page === "power")
            closeMenu()
        else
            openPage("power", screen)
    }

    function back(): void {
        if (page === "monitor") {
            page = "system"
            selectedIndex = 0
            return
        }

        closeMenu()
    }

    function selectNext(): void {
        if (currentItems.length === 0)
            return

        selectedIndex = (selectedIndex + 1) % currentItems.length
    }

    function selectPrevious(): void {
        if (currentItems.length === 0)
            return

        selectedIndex =
            (selectedIndex - 1 + currentItems.length)
            % currentItems.length
    }

    function activateIndex(index): void {
        if (index < 0 || index >= currentItems.length)
            return

        const item = currentItems[index]

        if (item.action === "idleSettings") {
            const screen = menuWindow.screen
            closeMenu()
            idleService.openSettings(screen)
            return
        }

        if (item.action === "suspend") {
            closeMenu()
            idleService.suspend()
            return
        }

        if (item.action === "lock") {
            closeMenu()
            lockService.lock()
            return
        }

        if (item.page) {
            page = item.page
            selectedIndex = 0
            return
        }

        if (item.action === "theme") {
            closeMenu()
            Qt.callLater(() => root.themeMenu.openMenu())
            return
        }

        if (item.action === "saveTheme") {
            closeMenu()
            Qt.callLater(() => root.themeMenu.openSavePrompt())
            return
        }

        if (item.action === "tmuxMenu") {
            closeMenu()
            root.tmuxMenu.openMenu()
            return
        }

        if (item.command) {
            closeMenu()
            config.run(item.command)
        }
    }

    function activateSelected(): void {
        activateIndex(selectedIndex)
    }

    PanelWindow {
        id: menuWindow

        screen: root.menuScreen || root.targetScreen

        anchors {
            top: true
            left: true
        }

        implicitWidth: menuCard.implicitWidth
        implicitHeight: menuCard.implicitHeight
        margins.top: root.config.popupGap
        margins.left: screen
            ? Math.max(0, Math.round((screen.width - width) / 2)) : 0

        visible: false
        color: "transparent"
        exclusiveZone: 0
        focusable: true

        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "quickshell-submenu"
        WlrLayershell.keyboardFocus: visible
            ? WlrKeyboardFocus.Exclusive
            : WlrKeyboardFocus.None

        FocusScope {
            id: keyboardHandler

            anchors.fill: parent
            focus: true

            Keys.onPressed: event => {
                switch (event.key) {
                case Qt.Key_Left:
                    if (root.page === "power") {
                        root.selectPrevious()
                        event.accepted = true
                    }
                    return
                case Qt.Key_Right:
                    if (root.page === "power") {
                        root.selectNext()
                        event.accepted = true
                    }
                    return
                case Qt.Key_Up:
                case Qt.Key_Backtab:
                    root.selectPrevious()
                    event.accepted = true
                    return

                case Qt.Key_Down:
                case Qt.Key_Tab:
                    root.selectNext()
                    event.accepted = true
                    return

                case Qt.Key_Return:
                case Qt.Key_Enter:
                    root.activateSelected()
                    event.accepted = true
                    return

                case Qt.Key_Escape:
                    root.back()
                    event.accepted = true
                    return
                }

                const key = root.page === "power" ? event.text : event.text.toLowerCase()

                for (let i = 0; i < root.currentItems.length; ++i) {
                    if (root.currentItems[i].shortcut === key) {
                        root.activateIndex(i)
                        event.accepted = true
                        return
                    }
                }

            }
        }

        PopoutPanel {
            id: menuCard

            z: 1
            config: root.config
            contentWidth: 260
            padding: 12
            spacing: 4

            anchors.top: parent.top
            anchors.horizontalCenter: parent.horizontalCenter


            Repeater {
                model: root.currentItems

                delegate: Item {
                    id: menuItem

                    required property var modelData
                    required property int index

                    width: parent ? parent.width : 0
                    height: 32

                    readonly property bool selected:
                        root.selectedIndex === index

                    Rectangle {
                        anchors.fill: parent
                        radius: 4
                        color: menuItem.selected || itemMouse.containsMouse
                            ? root.config.borderColor
                            : "transparent"
                    }

                    Text {
                        anchors.left: parent.left
                        anchors.leftMargin: 7
                        anchors.verticalCenter: parent.verticalCenter

                        width: 22
                        horizontalAlignment: Text.AlignHCenter

                        color: root.config.accent
                        font.family: root.config.iconFontFamily
                        font.pointSize: root.config.iconSize * 1.077
                        text: modelData.icon ?? ""
                    }

                    Text {
                        anchors.left: parent.left
                        anchors.leftMargin: 38
                        anchors.right: keyHint.left
                        anchors.rightMargin: 8
                        anchors.verticalCenter: parent.verticalCenter

                        color: root.config.fg
                        font.pointSize: root.config.fontSize(1)
                        font.weight: Font.Medium
                        elide: Text.ElideRight
                        text: modelData.label
                    }

                    Text {
                        visible: modelData.page !== undefined
                        anchors.right: keyHint.left
                        anchors.rightMargin: 8
                        anchors.verticalCenter: parent.verticalCenter

                        color: root.config.muted
                        font.family: root.config.iconFontFamily
                        font.pointSize: root.config.iconSize
                        text: "󰅂"
                    }

                    Text {
                        id: keyHint

                        anchors.right: parent.right
                        anchors.rightMargin: 6
                        anchors.verticalCenter: parent.verticalCenter

                        width: 21
                        horizontalAlignment: Text.AlignHCenter
                        color: root.config.fg
                        font.pointSize: root.config.fontSize(0.846)
                        text: modelData.shortcut ?? ""
                    }

                    MouseArea {
                        id: itemMouse

                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor

                        onEntered: root.selectedIndex = menuItem.index
                        onClicked: root.activateIndex(menuItem.index)
                    }
                }
            }
        }

        onVisibleChanged: {
            if (visible)
                Qt.callLater(() => keyboardHandler.forceActiveFocus())
        }
    }

    PopupCatcher {
        targetScreen: menuWindow.screen
        visible: menuWindow.visible
        onDismissed: root.closeMenu()
    }

    IpcHandler {
        target: "power"

        function toggle(): void {
            root.togglePower(root.targetScreen)
        }

        function open(): void {
            root.openPage("power")
        }

        function close(): void {
            if (root.page === "power")
                root.closeMenu()
        }
    }

    IpcHandler {
        target: "menu"


        function packages(): void {
            root.openPage("packages")
        }

        function settings(): void {
            root.openPage("settings")
        }

        function system(): void {
            root.openPage("system")
        }

        function theming(): void {
            root.openPage("theming")
        }
        function notes(): void {
            root.openPage("notes")
        }
        function close(): void {
            root.closeMenu()
        }
    }
}
