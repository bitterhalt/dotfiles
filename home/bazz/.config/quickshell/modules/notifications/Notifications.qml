import QtQuick
import Quickshell

Item {
    id: root

    required property var config
    required property var barWindow
    required property var popupManager
    required property var notificationService
    required property var notificationPopup
    required property var uiService

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

    Connections {
        target: notificationService

        function onToastSerialChanged(): void {
            popupManager.closeHost("notificationCenter")
        }
    }

    Connections {
        target: uiService

        function onNotificationCenterActionRequested(action): void {
            if (action === "close") {
                popupManager.closeHost("notificationCenter")
                return
            }

            if (barWindow.screen !== uiService.targetScreen) {
                popupManager.closeHost("notificationCenter")
                return
            }

            notificationPopup.hide()

            if (action === "toggle") {
                popupManager.toggleHost(
                    "notificationCenter",
                    notificationCenterComponent,
                    root,
                    false,
                    true
                )
            } else if (action === "open") {
                popupManager.openHost(
                    "notificationCenter",
                    notificationCenterComponent,
                    root,
                    false,
                    true
                )
            }
        }
    }
}
