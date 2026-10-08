import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications

Item {
    id: root
    visible: false

    property bool dnd: false
    property var toastNotification: null
    property int toastSerial: 0
    property var receivedTimes: ({})

    readonly property var notifications: server.trackedNotifications.values
    readonly property int notificationCount: notifications.length

    onNotificationsChanged: Qt.callLater(() => root.pruneReceivedTimes())

    function receive(notification): void {
        // Keep notifications alive so they can appear in the notification center.
        notification.tracked = true

        const nextTimes = Object.assign({}, receivedTimes)
        nextTimes[notification.id] = Date.now()
        receivedTimes = nextTimes

        // Transient notifications may still be shown as banners, but they
        // should not remain in history after the banner expires.
        if (!dnd && !notification.lastGeneration) {
            toastNotification = notification
            toastSerial += 1
        }
    }

    function receivedAt(notification): real {
        if (!notification)
            return 0

        return receivedTimes[notification.id] ?? 0
    }

    function removeReceivedTime(notification): void {
        if (!notification)
            return

        const nextTimes = Object.assign({}, receivedTimes)
        delete nextTimes[notification.id]
        receivedTimes = nextTimes
    }

    function pruneReceivedTimes(): void {
        const nextTimes = {}

        for (let i = 0; i < notifications.length; ++i) {
            const id = notifications[i].id

            if (receivedTimes[id] !== undefined)
                nextTimes[id] = receivedTimes[id]
        }

        receivedTimes = nextTimes
    }

    function dismiss(notification): void {
        if (!notification)
            return

        removeReceivedTime(notification)
        notification.dismiss()
    }

    function timeLabel(notification): string {
        const timestamp = receivedAt(notification)

        if (!timestamp)
            return ""

        return Qt.formatTime(new Date(timestamp), "HH:mm")
    }

    function finishToast(notification): void {
        if (notification && notification.transient) {
            removeReceivedTime(notification)
            notification.expire()
        }

        if (toastNotification === notification)
            toastNotification = null
    }

    function toggleDnd(): void {
        dnd = !dnd

        if (dnd)
            toastNotification = null
    }

    function clearAll(): void {
        // Copy first because dismissing mutates the tracked model.
        const items = notifications.slice()

        for (let i = 0; i < items.length; ++i)
            items[i].dismiss()

        toastNotification = null
        receivedTimes = ({})
    }

    NotificationServer {
        id: server

        bodySupported: true
        bodyMarkupSupported: false
        imageSupported: true
        actionsSupported: true
        persistenceSupported: true
        keepOnReload: true

        onNotification: notification => root.receive(notification)
    }

    IpcHandler {
        target: "notifications"

        function toggleDnd(): void {
            root.toggleDnd()
        }

        function enableDnd(): void {
            root.dnd = true
            root.toastNotification = null
        }

        function disableDnd(): void {
            root.dnd = false
        }

        function isDnd(): bool {
            return root.dnd
        }

        function clear(): void {
            root.clearAll()
        }

        function count(): int {
            return root.notificationCount
        }
    }
}
