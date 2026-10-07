import QtQuick
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: root

    required property var config
    required property var targetScreen

    signal accepted(string geometry)
    signal canceled()

    screen: targetScreen

    anchors {
        top: true
        left: true
        right: true
        bottom: true
    }

    visible: false
    color: "#44000000"
    exclusiveZone: 0
    focusable: true

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: visible
        ? WlrKeyboardFocus.Exclusive
        : WlrKeyboardFocus.None

    property real startX: 0
    property real startY: 0
    property real endX: 0
    property real endY: 0
    property bool selecting: false

    function open(): void {
        selecting = false
        visible = true
        Qt.callLater(() => keyboardHandler.forceActiveFocus())
    }

    function close(): void {
        selecting = false
        visible = false
    }

    Rectangle {
        x: Math.min(root.startX, root.endX)
        y: Math.min(root.startY, root.endY)

        width: Math.abs(root.endX - root.startX)
        height: Math.abs(root.endY - root.startY)

        visible: root.selecting
        color: "transparent"
        border.width: 2
        border.color: root.config.accent
        radius: 2
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: root.selecting
            ? Qt.CrossCursor
            : Qt.CrossCursor

        onPressed: mouse => {
            if (mouse.button === Qt.RightButton) {
                root.close()
                root.canceled()
                return
            }

            root.startX = mouse.x
            root.startY = mouse.y
            root.endX = mouse.x
            root.endY = mouse.y
            root.selecting = true
        }

        onPositionChanged: mouse => {
            if (!root.selecting)
                return

            root.endX = mouse.x
            root.endY = mouse.y
        }

        onReleased: mouse => {
            if (!root.selecting || mouse.button !== Qt.LeftButton)
                return

            root.endX = mouse.x
            root.endY = mouse.y

            const x = Math.round(
                Math.min(root.startX, root.endX)
            )
            const y = Math.round(
                Math.min(root.startY, root.endY)
            )
            const width = Math.round(
                Math.abs(root.endX - root.startX)
            )
            const height = Math.round(
                Math.abs(root.endY - root.startY)
            )

            root.selecting = false
            root.visible = false

            if (width < 10 || height < 10) {
                root.canceled()
                return
            }

            root.accepted(
                width + "x" + height + "+" + x + "+" + y
            )
        }
    }

    FocusScope {
        id: keyboardHandler

        anchors.fill: parent
        focus: true

        Keys.onEscapePressed: {
            root.close()
            root.canceled()
        }
    }
}
