pragma ComponentBehavior: Bound

import "../components"
import QtQuick
import Quickshell
import Quickshell.Wayland

// Standalone power menu, restored from the old MainMenu "Power" page.
// Session actions run through PowerService/LockService so they cannot drift
// from the launcher actions that use the same IPC.
Item {
    id: root

    required property var config
    required property var lockService
    required property var powerService
    required property var targetScreen

    property var menuScreen: null
    property bool opened: false
    property int selectedIndex: 0
    property var confirmItem: null
    property int confirmIndex: -1

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
            action: "exit",
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
            action: "reboot",
            confirm: true
        },
        {
            label: "Shut down",
            icon: "󰐥",
            shortcut: "s",
            action: "shutdown",
            confirm: true
        }
    ]

    readonly property var currentItems: confirmItem ? [
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
    ] : powerItems

    function open(screen) {
        cancelConfirmation();
        menuScreen = screen || targetScreen;
        selectedIndex = 0;
        opened = true;
        Qt.callLater(() => keyboardHandler.forceActiveFocus());
    }

    function close() {
        cancelConfirmation();
        opened = false;
    }

    function toggle(screen) {
        opened ? close() : open(screen);
    }

    function cancelConfirmation() {
        if (!confirmItem)
            return;
        selectedIndex = confirmIndex;
        confirmItem = null;
        confirmIndex = -1;
    }

    function back() {
        if (confirmItem)
            cancelConfirmation();
        else
            close();
    }

    function selectNext() {
        if (currentItems.length === 0)
            return;
        selectedIndex = (selectedIndex + 1) % currentItems.length;
    }

    function selectPrevious() {
        if (currentItems.length === 0)
            return;
        selectedIndex = (selectedIndex - 1 + currentItems.length) % currentItems.length;
    }

    function activateIndex(index) {
        if (confirmItem) {
            const pending = confirmItem;
            if (index === 0) {
                close();
                runAction(pending.action);
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
            return;
        }
        close();
        runAction(item.action);
    }

    function runAction(action) {
        if (action === "lock")
            lockService.lock();
        else if (action === "suspend")
            powerService.suspend();
        else if (action === "exit")
            powerService.exitSession();
        else if (action === "reboot")
            powerService.reboot();
        else if (action === "shutdown")
            powerService.shutdown();
    }

    PopupIpcHandler {
        target: "powermenu"
        handleAction: action => {
            if (action === "toggle")
                root.toggle(root.targetScreen);
            else if (action === "open")
                root.open(root.targetScreen);
            else
                root.close();
        }
    }

    PanelWindow {
        id: menuWindow

        screen: root.menuScreen || root.targetScreen
        visible: popupMotion.surfaceVisible
        implicitWidth: menuCard.implicitWidth
        implicitHeight: menuCard.implicitHeight
        anchors.top: true
        anchors.left: true
        margins.top: root.config.popupGap
        margins.left: screen ? Math.max(0, Math.round((screen.width - menuCard.implicitWidth) / 2)) : 0
        color: "transparent"
        exclusiveZone: 0
        focusable: root.opened
        WlrLayershell.namespace: "slim-powermenu"
        WlrLayershell.layer: WlrLayer.Overlay
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
                    root.selectPrevious();
                    event.accepted = true;
                    return;
                case Qt.Key_Right:
                    root.selectNext();
                    event.accepted = true;
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
                    root.activateIndex(root.selectedIndex);
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

            Repeater {
                model: root.currentItems

                delegate: Item {
                    id: powerRow

                    required property var modelData
                    required property int index

                    width: menuCard.contentWidth - menuCard.padding * 2
                    height: 32

                    MenuRow {
                        anchors.fill: parent
                        config: root.config
                        selected: root.selectedIndex === powerRow.index || rowMouse.containsMouse
                        icon: powerRow.modelData.icon ?? ""
                        label: powerRow.modelData.label
                        keyHint: powerRow.modelData.shortcut ?? ""
                    }

                    MouseArea {
                        id: rowMouse

                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            root.selectedIndex = powerRow.index;
                            root.activateIndex(powerRow.index);
                        }
                    }
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
}
