import QtQuick
import Quickshell
import Quickshell.Wayland

import "../../components"

Item {
    id: root

    required property var config
    required property var barWindow
    required property var popupManager
    required property var uiService

    width: 24
    height: barWindow.height

    property int selectedIndex: 0
    readonly property int actionCount: 5

    function run(command) {
        config.run(command)
    }

    function openMenu() {
        selectedIndex = 0
        powerMenu.visible = true
        Qt.callLater(() => keyboardHandler.forceActiveFocus())
    }

    function closeMenu() {
        powerMenu.visible = false
    }

    function toggleMenu() {
        if (powerMenu.visible)
            closeMenu()
        else
            openMenu()
    }

    function selectNext() {
        selectedIndex = (selectedIndex + 1) % actionCount
    }

    function selectPrevious() {
        selectedIndex =
            (selectedIndex - 1 + actionCount) % actionCount
    }

    function activateSelected() {
        switch (selectedIndex) {
        case 0:
            lock()
            break
        case 1:
            suspend()
            break
        case 2:
            restart()
            break
        case 3:
            shutdown()
            break
        case 4:
            logout()
            break
        }
    }

    function lock() {
        closeMenu()
        run("swaylock -C ~/.cache/wal/colors-swaylock")
    }

    function suspend() {
        closeMenu()
        run("systemctl suspend")
    }

    function restart() {
        closeMenu()
        run("systemctl reboot")
    }

    function shutdown() {
        closeMenu()
        run("systemctl poweroff")
    }

    function logout() {
        closeMenu()
        run("niri msg action quit")
    }

    Text {
        anchors.centerIn: parent

        color: config.fg
        font.family: config.iconFontFamily
        font.pointSize: config.iconSize
        text: "󰐥"
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: Qt.PointingHandCursor

        onClicked: mouse => {
            if (mouse.button === Qt.LeftButton)
                root.toggleMenu()
            else
                config.run("foot -a pop-upgrade -e sys_upgrade")
        }
    }

    PanelWindow {
        id: powerMenu

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

                switch (event.text) {
                case "l":
                    root.lock()
                    event.accepted = true
                    break

                case "s":
                    root.suspend()
                    event.accepted = true
                    break

                case "R":
                    root.restart()
                    event.accepted = true
                    break

                case "S":
                    root.shutdown()
                    event.accepted = true
                    break

                case "E":
                    root.logout()
                    event.accepted = true
                    break
                }
            }
        }

        PopoutPanel {
            id: menuCard

            z: 1

            anchors.top: parent.top
            anchors.right: parent.right
            anchors.topMargin: root.config.popupGap
            anchors.rightMargin: root.config.barEdgeMargin

            config: root.config
            contentWidth: 180
            spacing: 2

            PowerMenuItem {
                index: 0
                icon: "󰌾"
                label: "Lock"
                keyHint: "l"
                onTriggered: root.lock()
            }

            PowerMenuItem {
                index: 1
                icon: "󰤄"
                label: "Suspend"
                keyHint: "s"
                onTriggered: root.suspend()
            }

            PowerMenuItem {
                index: 2
                icon: "󰜉"
                label: "Restart"
                keyHint: "R"
                dangerous: true
                onTriggered: root.restart()
            }

            PowerMenuItem {
                index: 3
                icon: "󰐥"
                label: "Shut down"
                keyHint: "S"
                dangerous: true
                onTriggered: root.shutdown()
            }

            PowerMenuItem {
                index: 4
                icon: "󰍃"
                label: "Log out"
                keyHint: "E"
                dangerous: true
                onTriggered: root.logout()
            }
        }

        onVisibleChanged: {
            if (visible) {
                root.selectedIndex = 0
                Qt.callLater(() => keyboardHandler.forceActiveFocus())
            }
        }
    }

    component PowerMenuItem: Item {
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

            color:
                menuItem.selected || itemMouse.containsMouse
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
            border.color:
                menuItem.dangerous
                    ? root.config.accent
                    : root.config.accent

            Text {
                anchors.centerIn: parent

                color:
                    menuItem.dangerous
                        ? root.config.accent
                        : root.config.muted

                font.pointSize: root.config.fontSize(0.846)
                font.weight:
                    menuItem.dangerous
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
        target: uiService

        function onPowerActionRequested(action): void {
            if (action === "close") {
                root.closeMenu()
                return
            }

            if (barWindow.screen !== uiService.targetScreen) {
                root.closeMenu()
                return
            }

            if (action === "toggle")
                root.toggleMenu()
            else if (action === "open")
                root.openMenu()
        }
    }
}
