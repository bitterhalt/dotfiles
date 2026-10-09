import QtQuick
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: root

    required property var config
    required property var targetScreen
    required property var notificationService

    property var notification: null

    readonly property int defaultToastTimeoutMs: 5000

    function toastTimeoutMs(notification): int {
        if (!notification)
            return defaultToastTimeoutMs

        if (notification.expireTimeout < 0)
            return defaultToastTimeoutMs

        return Math.round(notification.expireTimeout)
    }

    function show(newNotification): void {
        if (!newNotification)
            return

        notification = newNotification
        visible = true

        if (toastTimeoutMs(newNotification) > 0)
            toastTimer.restart()
        else
            toastTimer.stop()
    }

    function hide(): void {
        visible = false
        toastTimer.stop()
    }

    screen: targetScreen

    anchors {
        top: true
        left: true
        right: true
    }

    margins.top: config.popupGap

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
        notification: root.notification
        notificationService: root.notificationService

        compact: true
        showClose: false
        dismissOnClick: false
    }

    MouseArea {
        anchors.fill: toastCard
        cursorShape: Qt.PointingHandCursor

        onClicked: root.hide()
    }

    Timer {
        id: toastTimer

        interval: root.toastTimeoutMs(root.notification)
        repeat: false

        onTriggered: {
            const current = root.notification
            root.visible = false
            root.notificationService.finishToast(current)
        }
    }
}
