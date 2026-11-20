import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

import "../components"

Item {
    id: root

    required property var config
    required property var targetScreen
    required property var lockService
    required property var idleService
    required property var wallpaperPicker
    required property var updatesController

    property string page: ""
    property bool opened: false
    property int selectedIndex: 0
    property var menuScreen: null
    property var confirmItem: null
    property int confirmIndex: -1

    // Session actions remain built in; personal menus live in menus.json.
    readonly property var powerItems: [
        {
            label: "Lock",
            icon: "󰌾",
            shortcut: "l",
            action: "lock"
        },
        {
            label: "Log out",
            icon: "󰍃",
            shortcut: "e",
            command: "niri msg action quit",
            confirm: true
        },
        {
            label: "Sleep",
            icon: "󰤄",
            shortcut: "z",
            action: "suspend"
        },
        {
            label: "Restart",
            icon: "󰜉",
            shortcut: "r",
            command: "systemctl reboot",
            confirm: true
        },
        {
            label: "Shut down",
            icon: "󰐥",
            shortcut: "s",
            command: "systemctl poweroff",
            confirm: true
        }
    ]

    MenuConfig {
        id: menuConfig
        onMenusChanged: {
            if (root.page !== "power") {
                root.confirmItem = null;
                root.confirmIndex = -1;
                root.selectedIndex = 0;
                Qt.callLater(() => menuCard.prepareLayout());
            }
        }
    }

    readonly property var currentItems: {
        if (confirmItem)
            return [
                {
                    label: "Yes",
                    icon: "󰄬",
                    shortcut: "y"
                },
                {
                    label: "No",
                    icon: "󰅖",
                    shortcut: "n"
                }
            ];

        switch (page) {
        case "power":
            return powerItems;
        default:
            return menuConfig.menus[page] || [];
        }
    }

    readonly property string title: {
        switch (page) {
        case "power":
            return "Power";
        default:
            return page;
        }
    }

    function open(name, screen): void {
        cancelConfirmation();
        page = name || "power";
        if (!["power", "user-menu1", "user-menu2", "user-menu3", "user-menu4"].includes(page))
            page = "power";
        menuScreen = screen || targetScreen;
        selectedIndex = 0;
        menuCard.prepareLayout();
        opened = true;
        Qt.callLater(() => keyboardHandler.forceActiveFocus());
    }

    function close(): void {
        cancelConfirmation();
        opened = false;
    }

    function toggle(name, screen): void {
        const requestedPage = name || "power";
        if (opened && page === requestedPage)
            close();
        else
            open(requestedPage, screen);
    }

    function cancelConfirmation(): void {
        if (!confirmItem)
            return;
        selectedIndex = confirmIndex;
        confirmItem = null;
        confirmIndex = -1;
        menuCard.prepareLayout();
    }

    function back(): void {
        if (confirmItem) {
            cancelConfirmation();
            return;
        }

        close();
    }

    function selectNext(): void {
        if (currentItems.length === 0)
            return;
        selectedIndex = (selectedIndex + 1) % currentItems.length;
    }

    function selectPrevious(): void {
        if (currentItems.length === 0)
            return;
        selectedIndex = (selectedIndex - 1 + currentItems.length) % currentItems.length;
    }

    function activateIndex(index): void {
        if (confirmItem) {
            const pending = confirmItem;
            if (index === 0) {
                close();
                if (pending.command)
                    config.run(pending.command);
            } else {
                cancelConfirmation();
            }
            return;
        }

        if (index < 0 || index >= currentItems.length)
            return;
        const item = currentItems[index];

        if (item.confirm) {
            confirmItem = item;
            confirmIndex = index;
            selectedIndex = 1;
            menuCard.prepareLayout();
            return;
        }

        if (item.action === "wallpaper") {
            const screen = menuWindow.screen;
            close();
            wallpaperPicker.open(screen);
            return;
        }

        if (item.action === "idleSettings") {
            const screen = menuWindow.screen;
            close();
            idleService.openSettings(screen);
            return;
        }

        if (item.action === "updates") {
            const screen = menuWindow.screen;
            close();
            updatesController.open(screen);
            return;
        }

        if (item.action === "suspend") {
            close();
            idleService.suspend();
            return;
        }

        if (item.action === "lock") {
            close();
            lockService.lock();
            return;
        }

        if (item.page) {
            page = item.page;
            selectedIndex = 0;
            menuCard.prepareLayout();
            return;
        }

        if (item.command) {
            close();
            config.run(item.command);
        }
    }

    function activateSelected(): void {
        activateIndex(selectedIndex);
    }

    // Popup frame and keyboard focus scope for the selected page.
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
        margins.left: screen ? Math.max(0, Math.round((screen.width - menuCard.implicitWidth) / 2)) : 0

        visible: popupMotion.surfaceVisible
        color: "transparent"
        exclusiveZone: 0
        focusable: root.opened

        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "slim-submenu"
        WlrLayershell.keyboardFocus: root.opened ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

        PopupMotion {
            id: popupMotion
            duration: 150
            surfaceHeight: menuWindow.height
            shown: root.opened
            animationsEnabled: root.config.popupAnimations
            animationType: "fade"
            onClosed: root.menuScreen = null
        }

        FocusScope {
            id: keyboardHandler

            anchors.fill: parent
            focus: true
            enabled: root.opened

            Keys.onPressed: event => {
                switch (event.key) {
                case Qt.Key_Left:
                    if (root.page === "power") {
                        root.selectPrevious();
                        event.accepted = true;
                    }
                    return;
                case Qt.Key_Right:
                    if (root.page === "power") {
                        root.selectNext();
                        event.accepted = true;
                    }
                    return;
                case Qt.Key_Up:
                case Qt.Key_Backtab:
                    root.selectPrevious();
                    event.accepted = true;
                    return;
                case Qt.Key_Down:
                case Qt.Key_Tab:
                    root.selectNext();
                    event.accepted = true;
                    return;
                case Qt.Key_Return:
                case Qt.Key_Enter:
                    root.activateSelected();
                    event.accepted = true;
                    return;
                case Qt.Key_Escape:
                    root.back();
                    event.accepted = true;
                    return;
                }

                const key = event.text.toLowerCase();

                for (let i = 0; i < root.currentItems.length; ++i) {
                    if (root.currentItems[i].shortcut === key) {
                        root.activateIndex(i);
                        event.accepted = true;
                        return;
                    }
                }
            }
        }

        PopoutPanel {
            id: menuCard

            enabled: root.opened
            opacity: popupMotion.contentOpacity
            transform: Translate {
                y: popupMotion.contentOffset
            }

            z: 1
            config: root.config
            contentWidth: 260
            padding: root.config.panelPadding
            spacing: root.config.spacingTight

            anchors.top: parent.top
            anchors.horizontalCenter: parent.horizontalCenter

            Text {
                renderType: Text.NativeRendering
                width: parent.width
                visible: root.confirmItem !== null
                color: root.config.urgent
                font.pointSize: root.config.textSizeNormal
                font.weight: Font.Medium
                wrapMode: Text.WordWrap
                text: root.confirmItem ? root.confirmItem.label + "?" : ""
            }

            // Highlighted row, icon, label, and shortcut hint.
            Text {
                width: parent.width
                visible: root.currentItems.length === 0
                text: "No menu items configured"
                textFormat: Text.PlainText
                renderType: Text.NativeRendering
                color: root.config.muted
                font.pointSize: root.config.textSizeSmall
            }

            Repeater {
                model: root.currentItems

                delegate: MenuRow {
                    required property var modelData
                    required property int index

                    config: root.config
                    selected: root.selectedIndex === index
                    icon: modelData.icon ?? ""
                    label: modelData.label
                    keyHint: modelData.shortcut ?? ""
                    submenu: modelData.page !== undefined
                }
            }
        }

        onVisibleChanged: {
            if (visible)
                Qt.callLater(() => keyboardHandler.forceActiveFocus());
        }
    }

    PopupCatcher {
        targetScreen: menuWindow.screen
        visible: menuWindow.visible
        onDismissed: root.close()
    }

    PopupIpcHandler {
        target: "power"
        handleAction: action => {
            if (action === "toggle")
                root.toggle("power", root.targetScreen);
            else if (action === "open")
                root.open("power");
            else if (root.page === "power")
                root.close();
        }
    }

    IpcHandler {
        target: "menu"

        function open(name: string): void {
            root.open(name);
        }
        function toggle(name: string): void {
            root.toggle(name, root.targetScreen);
        }

        function packages(): void {
            root.open("user-menu1");
        }

        function settings(): void {
            root.open("user-menu2");
        }

        function system(): void {
            root.open("user-menu3");
        }

        function close(): void {
            root.close();
        }
    }
}
