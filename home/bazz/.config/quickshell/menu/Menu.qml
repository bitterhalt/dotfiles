import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

import "../components"

Item {
    id: root

    required property var config
    required property var themeMenu
    required property var targetScreen

    property string page: ""
    property int selectedIndex: 0


    readonly property var packagesItems: [
        { label: "Install Packages", icon: "󰏗", shortcut: "i", command: "foot -a pacseek -T pacseek -e pacseek -m" },
        { label: "Update", icon: "󰑐", shortcut: "u", command: "foot -a pop-upgrade -e sup" }
    ]


    readonly property var settingsItems: [
        { label: "Bash", icon: "󱆃", command: "foot -e nvim ~/.bashrc ~/.config/shell/aliases ~/.config/shell/inputrc" },
        { label: "Foot", icon: "󰆍", command: "foot -e nvim ~/.config/foot/foot.ini" },
        { label: "Niri", icon: "󰖲", command: "foot sh -c 'cd ~/.config/niri/ && nvim *'" },
        { label: "Nvim", icon: "", command: "foot sh -c 'cd ~/.config/nvim && vopen .'" },
        { label: "Pywal", icon: "󰏘", command: "foot -e nvim ~/.local/bin/setbg ~/.config/wal/templates/*" },
        { label: "Quickshell", icon: "󰆍", command: "foot sh -c 'cd ~/.config/quickshell && vopen .'" },
        { label: "Swayidle", icon: "󰒲", command: "foot sh -c 'cd ~/.config/swayidle/ && nvim config'" },
        { label: "Dmenus", icon: "󰍉", command: "foot sh -c 'nvim ~/.local/bin/menu_*'" },
    ]

    readonly property var systemItems: [
        { label: "Wiremix", icon: "󰓃", command: "foot -a wiremix -e wiremix" },
        { label: "Bluetooth", icon: "󰂯", command: "foot -a bluetui -e bluetui" },
        { label: "Wi-Fi", icon: "󰖩", command: "foot -a impala -e impala" },
        { label: "Network Manager", icon: "󰲝", command: "foot -e nmtui" },
        { label: "Update System", icon: "󰑐", command: "foot -a pop-upgrade -e sysup" },
        { label: "Monitor", icon: "󰨇", page: "monitor" }
    ]

    readonly property var monitorItems: [
        { label: "Atop [AMD GPU Monitor]", icon: "󰾲", command: "foot -T atop -e amdgpu_top --smi" },
        { label: "Btop [System Monitor]", icon: "󰨇", command: "foot -a btop -e btop" },
        { label: "Nethogs [Network Monitor]", icon: "󰛳", command: "foot -a nethogs -e nethogs" },
        { label: "Logs", icon: "󰌱", command: "foot -a foot -T journalctl -e journalctl -f" },
        { label: "Combined", icon: "󰕮", command: "foot -a Sysmon -T Sysmon -e ~/.local/bin/tmux-sysmon.sh" }
    ]

    readonly property var themingItems: [
        { label: "Set wallpaper", icon: "󰸉", command: "swayimg --appid swayimg-setwall -g ~/Pictures/wallpaper/" },
        { label: "Set theme", icon: "󰏘", action: "theme" },
        { label: "Save theme", icon: "󰆓", action: "saveTheme" }
    ]

    readonly property var currentItems: {
        switch (page) {
        case "packages":
            return packagesItems
        case "settings":
            return settingsItems
        case "system":
            return systemItems
        case "monitor":
            return monitorItems
        case "theming":
            return themingItems
        default:
            return []
        }
    }

    readonly property string title: {
        switch (page) {
        case "packages":
            return "Packages"
        case "settings":
            return "Edit configs"
        case "system":
            return "Settings"
        case "monitor":
            return "Monitor"
        case "theming":
            return "Theming"
        default:
            return ""
        }
    }

    function openPage(name): void {
        page = name
        selectedIndex = 0
        menuWindow.visible = true
        Qt.callLater(() => keyboardHandler.forceActiveFocus())
    }

    function closeMenu(): void {
        menuWindow.visible = false
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
            focus: true

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
                    root.back()
                    event.accepted = true
                    return
                }

                const key = event.text.toLowerCase()

                for (let i = 0; i < root.currentItems.length; ++i) {
                    if (root.currentItems[i].shortcut === key) {
                        root.activateIndex(i)
                        event.accepted = true
                        return
                    }
                }

                const number = Number(event.text)

                if (number >= 1 && number <= root.currentItems.length) {
                    root.activateIndex(number - 1)
                    event.accepted = true
                }
            }
        }

        PopoutPanel {
            id: menuCard

            z: 1
            config: root.config
            contentWidth: 260
            padding: 8
            spacing: 2

            anchors.top: parent.top
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.topMargin: root.config.popupGap

            Item {
                width: parent ? parent.width : 0
                height: 30

                Text {
                    anchors.left: parent.left
                    anchors.leftMargin: 8
                    anchors.verticalCenter: parent.verticalCenter

                    color: root.config.fg
                    font.pointSize: root.config.fontSize(1)
                    font.weight: Font.DemiBold
                    text: root.title
                }

                Text {
                    anchors.right: parent.right
                    anchors.rightMargin: 8
                    anchors.verticalCenter: parent.verticalCenter

                    visible: root.page === "monitor"
                    color: root.config.muted
                    font.pointSize: root.config.fontSize(0.846)
                    text: "Esc  Back"
                }
            }

            PanelSeparator {
                config: root.config
            }

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
                        anchors.right: keyBox.left
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
                        anchors.right: keyBox.left
                        anchors.rightMargin: 8
                        anchors.verticalCenter: parent.verticalCenter

                        color: root.config.muted
                        font.family: root.config.iconFontFamily
                        font.pointSize: root.config.iconSize
                        text: "󰅂"
                    }

                    Rectangle {
                        id: keyBox

                        anchors.right: parent.right
                        anchors.rightMargin: 6
                        anchors.verticalCenter: parent.verticalCenter

                        width: 21
                        height: 20
                        radius: 4
                        color: "transparent"

                        border.width: 1
                        border.color: root.config.accent

                        Text {
                            anchors.centerIn: parent
                            color: root.config.muted
                            font.pointSize: root.config.fontSize(0.846)
                            text: modelData.shortcut ?? (menuItem.index + 1)
                        }
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

        function close(): void {
            root.closeMenu()
        }
    }
}
