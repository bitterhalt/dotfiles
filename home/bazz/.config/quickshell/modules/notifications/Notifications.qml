import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

Item {
    id: root

    required property var config
    required property var barWindow
    required property var popupManager
    required property var notificationService

    readonly property int defaultToastTimeoutMs: 5000

    function toastTimeoutMs(notification): int {
        if (!notification)
            return defaultToastTimeoutMs

        if (notification.expireTimeout < 0)
            return defaultToastTimeoutMs

        return Math.round(notification.expireTimeout)
    }

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

            toastWindow.visible = false
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

    PanelWindow {
        id: toastWindow

        screen: root.barWindow.screen

        anchors {
            top: true
            left: true
            right: true
        }

        margins.top: root.config.popupGap

        WlrLayershell.layer: WlrLayer.Overlay

        exclusiveZone: 0
        implicitHeight: 92
        visible: false
        color: "transparent"

        mask: Region {
            item: toastCard
        }

        NotificationCard {
            id: toastCard

            width: 380
            height: parent.height
            anchors.horizontalCenter: parent.horizontalCenter

            config: root.config
            notification: notificationService.toastNotification
            notificationService: root.notificationService

            compact: true
            showClose: false
            dismissOnClick: false
        }

        MouseArea {
            anchors.fill: toastCard
            cursorShape: Qt.PointingHandCursor

            onClicked: {
                toastWindow.visible = false
                toastTimer.stop()
            }
        }
    }

    Timer {
        id: toastTimer

        interval: root.toastTimeoutMs(
            notificationService.toastNotification
        )
        repeat: false

        onTriggered: {
            const notification = notificationService.toastNotification
            toastWindow.visible = false
            notificationService.finishToast(notification)
        }
    }

    Connections {
        target: notificationService

        function onToastSerialChanged(): void {
            if (!notificationService.dnd
                    && notificationService.toastNotification) {
                centerPopup.visible = false
                toastWindow.visible = true

                if (root.toastTimeoutMs(
                        notificationService.toastNotification) > 0) {
                    toastTimer.restart()
                } else {
                    toastTimer.stop()
                }
            }
        }

        function onDndChanged(): void {
            if (notificationService.dnd) {
                toastWindow.visible = false
                toastTimer.stop()
            }
        }
    }

    IpcHandler {
        target: "notificationCenter"

        function toggle(): void {
            toastWindow.visible = false

            if (centerPopup.visible) {
                centerPopup.visible = false
            } else {
                centerPopup.grabFocus = false
                centerPopup.visible = true
            }
        }

        function open(): void {
            toastWindow.visible = false
            centerPopup.grabFocus = false
            centerPopup.visible = true
        }

        function close(): void {
            centerPopup.visible = false
        }
    }
}
