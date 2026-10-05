import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: root

    required property var config
    required property var barWindow
    required property var popupManager
    required property var notificationService

    readonly property bool active:
        notificationService.dnd
        || notificationService.notificationCount > 0

    width: active ? 22 : 0
    height: barWindow.height
    visible: active

    Text {
        anchors.centerIn: parent

        color: notificationService.dnd
            || notificationService.notificationCount > 0
            ? config.accent
            : config.muted

        font.family: config.iconFontFamily
        font.pointSize: config.iconSize
        text: notificationService.dnd ? "󰂛" : "󱅫"
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: Qt.PointingHandCursor

        onClicked: mouse => {
            if (mouse.button === Qt.RightButton) {
                notificationService.toggleDnd()
                return
            }

            notificationPopup.hide()

            centerPopup.grabFocus = true
            popupManager.toggle(centerPopup)
        }
    }

    NotificationCenter {
        id: centerPopup

        config: root.config
        anchorItem: root
        notificationService: root.notificationService
    }

    NotificationPopup {
        id: notificationPopup

        config: root.config
        barWindow: root.barWindow
        notificationService: root.notificationService
    }

    Connections {
        target: notificationService

        function onToastSerialChanged(): void {
            if (!notificationService.dnd
                    && notificationService.toastNotification) {
                centerPopup.visible = false
                notificationPopup.show(
                    notificationService.toastNotification
                )
            }
        }

        function onDndChanged(): void {
            if (notificationService.dnd)
                notificationPopup.hide()
        }
    }

    IpcHandler {
        target: "notificationCenter"

        function toggle(): void {
            notificationPopup.hide()

            if (centerPopup.visible) {
                centerPopup.visible = false
            } else {
                centerPopup.grabFocus = false
                centerPopup.visible = true
            }
        }

        function open(): void {
            notificationPopup.hide()
            centerPopup.grabFocus = false
            centerPopup.visible = true
        }

        function close(): void {
            centerPopup.visible = false
        }
    }
}
