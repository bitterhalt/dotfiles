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

            popupManager.toggleHost(
                "notificationCenter",
                notificationCenterComponent,
                root,
                false,
                true
            )
        }
    }

    Component {
        id: notificationCenterComponent

        NotificationCenter {
            config: root.config
            notificationService: root.notificationService
        }
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
                popupManager.closeHost("notificationCenter")
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

            popupManager.toggleHost(
                "notificationCenter",
                notificationCenterComponent,
                root,
                false,
                true
            )
        }

        function open(): void {
            notificationPopup.hide()

            popupManager.openHost(
                "notificationCenter",
                notificationCenterComponent,
                root,
                false,
                true
            )
        }

        function close(): void {
            popupManager.closeHost("notificationCenter")
        }
    }
}
