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
    readonly property bool ipcOwner:
        barWindow.screen === recorderService.targetScreen

    property int selectedIndex: 0
    readonly property int actionCount: runningNow ? 3 : 2

    width: runningNow ? 24 : 0
    height: barWindow.height
    visible: runningNow

    function openMenu(): void {
        selectedIndex = 0
        recorderMenu.visible = true
        Qt.callLater(() => keyboardHandler.forceActiveFocus())
    }

    function closeMenu(): void {
        recorderMenu.visible = false
    }

    function toggleMenu(): void {
        recorderMenu.visible ? closeMenu() : openMenu()
    }

    function selectNext(): void {
        selectedIndex = (selectedIndex + 1) % actionCount
    }

    function selectPrevious(): void {
        selectedIndex =
            (selectedIndex - 1 + actionCount) % actionCount
    }

    function activateSelected(): void {
        switch (selectedIndex) {
        case 0:
            fullscreen()
            break
        case 1:
            region()
            break
        case 2:
            stop()
            break
        }
    }

    function fullscreen(): void {
        closeMenu()
        recorderService.fullscreen()
    }

    function region(): void {
        closeMenu()

        if (recorderService.canStart())
            regionSelector.open()
    }

    function stop(): void {
        closeMenu()
        recorderService.stop()
    }

    Text {
        anchors.centerIn: parent
        color: config.accent
        font.family: config.iconFontFamily
        font.pointSize: config.iconSize * 1.15
        text: "󰑋"
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: root.toggleMenu()
    }

    RegionSelector {
        id: regionSelector

        config: root.config
        targetScreen: root.barWindow.screen

        onAccepted: geometry => {
            root.recorderService.startRegion(geometry)
        }
    }

    PanelWindow {
        id: recorderMenu

        screen: root.barWindow.screen

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
                    root.closeMenu()
                    event.accepted = true
                    return
                }

                switch (event.text.toLowerCase()) {
                case "f":
                    root.fullscreen()
                    event.accepted = true
                    break

                case "r":
                    root.region()
                    event.accepted = true
                    break

                case "s":
                    if (root.runningNow)
                        root.stop()
                    event.accepted = true
                    break
                }
            }
        }

        PopoutPanel {
            id: menuCard

            z: 1
            config: root.config
            contentWidth: 190
            padding: 14
            spacing: 2

            anchors.top: parent.top
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.topMargin: root.config.popupGap

            RecorderMenuItem {
                index: 0
                icon: "󰑋"
                label: "Fullscreen"
                keyHint: "f"
                onTriggered: root.fullscreen()
            }

            RecorderMenuItem {
                index: 1
                icon: "󰩬"
                label: "Region"
                keyHint: "r"
                onTriggered: root.region()
            }

            RecorderMenuItem {
                index: 2
                icon: "󰙦"
                label: "Stop"
                keyHint: "s"
                dangerous: true
                visible: root.runningNow
                height: visible ? 32 : 0
                onTriggered: root.stop()
            }
        }

        onVisibleChanged: {
            if (visible) {
                root.selectedIndex = 0
                Qt.callLater(
                    () => keyboardHandler.forceActiveFocus()
                )
            }
        }
    }

    component RecorderMenuItem: Item {
        id: menuItem

        required property int index
        required property string icon
        required property string label
        required property string keyHint

        property bool dangerous: false
        readonly property bool selected:
            root.selectedIndex === menuItem.index

        signal triggered()

        width: parent ? parent.width : 0
        height: 32

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
            color: root.config.accent
            font.family: root.config.iconFontFamily
            font.pointSize: root.config.iconSize * 1.077
            horizontalAlignment: Text.AlignHCenter
            text: menuItem.icon
        }

        Text {
            anchors.left: parent.left
            anchors.leftMargin: 38
            anchors.verticalCenter: parent.verticalCenter

            color: root.config.fg
            font.pointSize: root.config.fontSize(1)
            font.weight: Font.Medium
            text: menuItem.label
        }

        Rectangle {
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

                color: menuItem.dangerous
                    ? root.config.accent
                    : root.config.muted

                font.pointSize: root.config.fontSize(0.846)
                font.weight: menuItem.dangerous
                    ? Font.DemiBold
                    : Font.Normal

                text: menuItem.keyHint
            }
        }

        MouseArea {
            id: itemMouse

            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor

            onEntered: root.selectedIndex = menuItem.index
            onClicked: menuItem.triggered()
        }
    }

    Connections {
        target: recorderService

        function onMenuActionRequested(action): void {
            if (action === "close") {
                root.closeMenu()
                return
            }

            if (!root.ipcOwner) {
                root.closeMenu()
                return
            }

            if (action === "toggle")
                root.toggleMenu()
            else if (action === "open")
                root.openMenu()
        }

        function onRegionSelectionRequested(): void {
            if (root.ipcOwner)
                root.region()
        }
    }
}
