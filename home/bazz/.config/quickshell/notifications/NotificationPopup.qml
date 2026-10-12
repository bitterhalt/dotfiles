import QtQuick
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: root

    required property var config
    required property var targetScreen
    required property var notificationService

    // Active toasts, newest first. Delegates are keyed by the notification
    // object, so each toast keeps its own timer while others come and go.
    property var toasts: []
    // Non-transient toasts bumped off the stack remain in the center.
    property var overflowedNotifications: []
    readonly property int overflowCount: overflowedNotifications.length

    signal openNotificationCenterRequested()

    readonly property int maxToasts: 3
    readonly property int toastWidth: 380
    readonly property int toastHeight: 84
    readonly property int toastSpacing: 8
    readonly property int chipHeight: 24
    readonly property int defaultToastTimeoutMs: 5000

    // expireTimeout is the raw D-Bus value in milliseconds (despite what the
    // Quickshell docs say): -1 = unspecified, 0 = never expire.
    function toastTimeoutMs(notification): int {
        if (!notification || notification.expireTimeout < 0)
            return defaultToastTimeoutMs

        return Math.round(notification.expireTimeout)
    }

    function show(newNotification): void {
        if (!newNotification || toasts.indexOf(newNotification) !== -1)
            return

        const next = [newNotification].concat(toasts)

        while (next.length > maxToasts) {
            const overflowed = next.pop()

            if (overflowed.transient)
                notificationService.finishToast(overflowed)
            else
                overflowedNotifications =
                    overflowedNotifications.concat([overflowed])
        }

        toasts = next
    }

    // Remove from the stack only (e.g. the notification was closed elsewhere).
    function removeToast(notification): void {
        toasts = toasts.filter(toast => toast !== notification)
    }

    function removeOverflowed(notification): void {
        overflowedNotifications = overflowedNotifications.filter(
            item => item !== notification
        )
    }

    // Remove from the stack and let the service finish it (expires transients).
    function dismissToast(notification): void {
        removeToast(notification)
        notificationService.finishToast(notification)
    }

    // Hides every toast; notifications stay in the center.
    function hide(): void {
        const current = toasts

        toasts = []
        overflowedNotifications = []

        for (let i = 0; i < current.length; ++i)
            notificationService.finishToast(current[i])
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
    // Fixed size for the maximum stack: the surface never resizes, and the
    // mask below keeps everything outside the toasts click-through.
    implicitHeight: maxToasts * (toastHeight + toastSpacing) + chipHeight
    visible: toasts.length > 0
    color: "transparent"

    mask: Region {
        item: stack
    }

    Connections {
        target: root.notificationService

        function onDndChanged(): void {
            if (root.notificationService.dnd)
                root.hide()
        }
    }

    Repeater {
        model: root.overflowedNotifications

        delegate: Item {
            required property var modelData

            visible: false

            Connections {
                target: modelData

                function onClosed(): void {
                    root.removeOverflowed(modelData)
                }
            }
        }
    }

    Column {
        id: stack

        width: root.toastWidth
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: root.toastSpacing

        Repeater {
            model: ScriptModel {
                values: root.toasts
            }

            delegate: Item {
                id: toastItem

                required property var modelData

                width: stack.width
                height: card.height

                HoverHandler {
                    id: hover
                }

                NotificationCard {
                    id: card

                    width: parent.width
                    height: implicitHeight

                    config: root.config
                    notification: toastItem.modelData
                    notificationService: root.notificationService

                    compact: true
                    showClose: false
                    dismissOnClick: false
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor

                    onClicked: root.dismissToast(toastItem.modelData)
                }

                // Hovering pauses the countdown; leaving restarts it.
                Timer {
                    interval: root.toastTimeoutMs(toastItem.modelData)
                    running: interval > 0 && !hover.hovered
                    repeat: false

                    onTriggered: root.dismissToast(toastItem.modelData)
                }

                Connections {
                    target: toastItem.modelData

                    function onClosed(): void {
                        root.removeToast(toastItem.modelData)
                    }
                }
            }
        }

        Rectangle {
            visible: root.overflowCount > 0
            width: stack.width
            height: root.chipHeight
            radius: root.config.popupRadius
            color: root.config.surface
            border.color: root.config.borderColor
            border.width: 1

            Text {
                anchors.centerIn: parent
                color: root.config.muted
                font.pointSize: root.config.fontSize(0.78)
                text: "+" + root.overflowCount + " more in notification center"
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor

                onClicked: {
                    root.hide()
                    root.openNotificationCenterRequested()
                }
            }
        }
    }
}
