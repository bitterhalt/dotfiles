import QtQuick
import Quickshell
import Quickshell.Wayland

import "../components"

Item {
    id: root

    required property var config
    required property var barWindow
    required property var recorderService

    readonly property bool runningNow: recorderService.runningNow
    readonly property bool ipcOwner: barWindow.screen === recorderService.targetScreen

    property int selectedIndex: 0
    property bool opened: false
    readonly property int actionCount: runningNow ? 3 : 2

    width: 0
    height: 0

    function open(): void {
        selectedIndex = 0;
        menuCard.prepareLayout();
        opened = true;
        Qt.callLater(() => keyboardHandler.forceActiveFocus());
    }

    function close(): void {
        opened = false;
    }

    function toggle(): void {
        opened ? close() : open();
    }

    function selectNext(): void {
        selectedIndex = (selectedIndex + 1) % actionCount;
    }

    function selectPrevious(): void {
        selectedIndex = (selectedIndex - 1 + actionCount) % actionCount;
    }

    function activateSelected(): void {
        switch (selectedIndex) {
        case 0:
            fullscreen();
            break;
        case 1:
            region();
            break;
        case 2:
            stop();
            break;
        }
    }

    function fullscreen(): void {
        close();
        recorderService.fullscreen();
    }

    function region(): void {
        close();

        if (recorderService.canStart())
            regionSelector.open();
    }

    function stop(): void {
        close();
        recorderService.stop();
    }

    // Full-screen drag selector used by the Region menu action.
    RegionSelector {
        id: regionSelector

        config: root.config
        targetScreen: root.barWindow.screen

        onAccepted: geometry => {
            root.recorderService.startRegion(geometry);
        }
    }

    // Keyboard-driven recorder action menu.
    PanelWindow {
        id: recorderMenu

        screen: root.barWindow.screen

        anchors {
            top: true
            left: true
        }

        implicitWidth: menuCard.implicitWidth
        implicitHeight: menuCard.implicitHeight
        margins.top: root.config.popupGap
        margins.left: root.barWindow.screen ? Math.max(0, Math.round((root.barWindow.screen.width - menuCard.implicitWidth) / 2)) : 0

        visible: popupMotion.surfaceVisible
        color: "transparent"
        exclusiveZone: 0
        focusable: root.opened

        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "slim-submenu"
        WlrLayershell.keyboardFocus: root.opened ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

        FocusScope {
            id: keyboardHandler

            anchors.fill: parent
            focus: true
            enabled: root.opened

            Keys.onPressed: event => {
                switch (event.key) {
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
                    root.close();
                    event.accepted = true;
                    return;
                }

                switch (event.text.toLowerCase()) {
                case "f":
                    root.fullscreen();
                    event.accepted = true;
                    break;
                case "r":
                    root.region();
                    event.accepted = true;
                    break;
                case "s":
                    if (root.runningNow)
                        root.stop();
                    event.accepted = true;
                    break;
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
            contentWidth: 190
            padding: 12
            spacing: 4

            anchors.top: parent.top
            anchors.horizontalCenter: parent.horizontalCenter

            // Fullscreen, region, and stop actions.
            RecorderMenuItem {
                index: 0
                icon: "󰑋"
                label: "Fullscreen"
                keyHint: "f"
            }

            RecorderMenuItem {
                index: 1
                icon: "󰩬"
                label: "Region"
                keyHint: "r"
            }

            RecorderMenuItem {
                index: 2
                icon: "󰙦"
                label: "Stop"
                keyHint: "s"
                visible: root.runningNow
            }
        }
    }

    PopupMotion {
        id: popupMotion
        shown: root.opened
        animationsEnabled: root.config.popupAnimations
        animationType: "fade"
        duration: 150
        surfaceHeight: recorderMenu.height
    }

    PopupCatcher {
        targetScreen: root.barWindow.screen
        visible: popupMotion.surfaceVisible
        onDismissed: root.close()
    }

    component RecorderMenuItem: MenuRow {
        id: menuItem

        required property int index

        config: root.config
        selected: root.selectedIndex === menuItem.index
        accentIcon: false
        iconInset: 7
        hintInset: 6
        iconScale: 1.077
    }

    Connections {
        target: recorderService

        function onMenuActionRequested(action): void {
            if (action === "close") {
                root.close();
                return;
            }

            if (!root.ipcOwner) {
                root.close();
                return;
            }

            if (action === "toggle")
                root.toggle();
            else if (action === "open")
                root.open();
        }

        function onRegionSelectionRequested(): void {
            if (root.ipcOwner)
                root.region();
        }
    }
}
