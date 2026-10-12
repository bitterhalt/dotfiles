import QtQuick
import Quickshell
import Quickshell.Wayland

Scope {
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
    readonly property int slotHeight: toastHeight + toastSpacing
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

        // The "+N more" count belongs to the current burst of toasts. Once
        // the stack is empty, forget it so it doesn't reappear on the next one.
        if (toasts.length === 0)
            overflowedNotifications = []
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

    Connections {
        target: root.notificationService

        function onDndChanged(): void {
            if (root.notificationService.dnd)
                root.hide()
        }
    }

    // One layer surface per toast, each exactly card-sized. Compositor effects
    // (a niri shadow, say) then wrap each card, and the gaps between cards stay
    // empty instead of being filled by one big surface.
    Variants {
        model: root.toasts

        delegate: PanelWindow {
            id: toastWindow

            required property var modelData

            // Position in the stack (0 = newest, at the top).
            readonly property int slot: Math.max(
                0, root.toasts.indexOf(modelData))

            screen: root.targetScreen
            anchors.top: true
            anchors.left: true
            margins.top: root.config.popupGap + slot * root.slotHeight
            margins.left: root.targetScreen
                ? Math.max(
                    0,
                    Math.round(
                        (root.targetScreen.width - root.toastWidth) / 2
                    )
                )
                : 0

            WlrLayershell.namespace: "notifications"
            WlrLayershell.layer: WlrLayer.Overlay

            exclusiveZone: 0
            implicitWidth: root.toastWidth
            implicitHeight: card.height
            color: "transparent"

            HoverHandler {
                id: hover
            }

            NotificationCard {
                id: card

                width: parent.width
                height: implicitHeight

                config: root.config
                notification: toastWindow.modelData
                notificationService: root.notificationService

                compact: true
                showClose: false
                dismissOnClick: false
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor

                onClicked: root.dismissToast(toastWindow.modelData)
            }

            // Hovering pauses the countdown; leaving restarts it.
            Timer {
                interval: root.toastTimeoutMs(toastWindow.modelData)
                running: interval > 0 && !hover.hovered
                repeat: false

                onTriggered: root.dismissToast(toastWindow.modelData)
            }

            Connections {
                target: toastWindow.modelData

                function onClosed(): void {
                    root.removeToast(toastWindow.modelData)
                }
            }
        }
    }

    // "+N more" chip, in its own surface right below the last toast.
    PanelWindow {
        id: chipWindow

        screen: root.targetScreen
        anchors.top: true
        anchors.left: true
        margins.top: root.config.popupGap + root.toasts.length * root.slotHeight
        margins.left: root.targetScreen
            ? Math.max(
                0,
                Math.round((root.targetScreen.width - root.toastWidth) / 2)
            )
            : 0

        WlrLayershell.namespace: "notifications"
        WlrLayershell.layer: WlrLayer.Overlay

        exclusiveZone: 0
        implicitWidth: root.toastWidth
        implicitHeight: root.chipHeight
        visible: root.toasts.length > 0 && root.overflowCount > 0
        color: "transparent"

        // Stop tracking bumped notifications once they are closed elsewhere.
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

        Rectangle {
            anchors.fill: parent
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
