import QtQuick
import Quickshell.Io
import Quickshell.Services.Notifications
import "../notifications/ToastPolicy.js" as ToastPolicy
import "../notifications/HistoryPolicy.js" as HistoryPolicy

Item {
    id: root
    visible: false

    required property var config

    property bool dnd: false
    property int historyOpenCount: 0
    property var toastNotification: null
    property int toastSerial: 0
    property var receivedTimes: ({})

    readonly property var notifications: server.trackedNotifications.values
    readonly property var historyNotifications: HistoryPolicy.visibleNotifications(notifications, config.notificationHistoryExcludedApps)
    readonly property int notificationCount: historyNotifications.length

    onNotificationsChanged: Qt.callLater(root.maintainHistory)
    Connections {
        target: root.config

        function onNotificationHistoryLimitChanged() {
            Qt.callLater(root.maintainHistory);
        }
    }

    function maintainHistory() {
        const limit = Math.max(1, config.notificationHistoryLimit);
        const history = historyNotifications;
        const excess = history.length - limit;

        if (excess > 0) {
            // Work on a snapshot: expiring an entry mutates the tracked model.
            // Prefer keeping critical alerts, but still enforce a hard limit
            // when the entire history consists of critical notifications.
            const oldest = history.slice().sort((left, right) => {
                // Do not immediately remove the newest visible alert when
                // older history happens to consist entirely of criticals.
                const leftToast = left === root.toastNotification;
                const rightToast = right === root.toastNotification;
                const leftCritical = left.urgency === NotificationUrgency.Critical;
                const rightCritical = right.urgency === NotificationUrgency.Critical;
                return Number(leftToast) - Number(rightToast) || Number(leftCritical) - Number(rightCritical) || root.receivedAt(left) - root.receivedAt(right);
            });

            for (let i = 0; i < excess; ++i) {
                if (toastNotification === oldest[i])
                    toastNotification = null;
                oldest[i].expire();
            }
        }

        pruneReceivedTimes();
    }

    function receive(notification): void {
        // Suppressed transients and history exclusions must not remain tracked.
        // Toasted entries stay alive only until their toast finishes.
        if ((notification.transient || isHistoryExcluded(notification)) && !ToastPolicy.shouldShow(notification, dnd)) {
            notification.tracked = false;
            return;
        }

        // Keep notifications alive so they can appear in the notification center.
        notification.tracked = true;

        const nextTimes = Object.assign({}, receivedTimes);
        nextTimes[notification.id] = Date.now();
        receivedTimes = nextTimes;

        // Low-urgency notifications also get a toast. DND suppresses all toasts.
        if (ToastPolicy.shouldShow(notification, dnd)) {
            toastNotification = notification;
            toastSerial += 1;
        }
    }

    function isHistoryExcluded(notification): bool {
        return HistoryPolicy.isExcluded(notification, config.notificationHistoryExcludedApps);
    }

    function receivedAt(notification): real {
        if (!notification)
            return 0;

        return receivedTimes[notification.id] ?? 0;
    }

    function removeReceivedTime(notification): void {
        if (!notification)
            return;
        const nextTimes = Object.assign({}, receivedTimes);
        delete nextTimes[notification.id];
        receivedTimes = nextTimes;
    }

    function pruneReceivedTimes(): void {
        const nextTimes = {};

        for (let i = 0; i < notifications.length; ++i) {
            const id = notifications[i].id;

            if (receivedTimes[id] !== undefined)
                nextTimes[id] = receivedTimes[id];
        }

        receivedTimes = nextTimes;
    }

    function dismiss(notification): void {
        if (!notification)
            return;
        removeReceivedTime(notification);
        notification.dismiss();
    }

    function timeLabel(notification): string {
        const timestamp = receivedAt(notification);

        if (!timestamp)
            return "";

        return Qt.formatTime(new Date(timestamp), "HH:mm");
    }

    function finishToast(notification): void {
        if (notification && (notification.transient || isHistoryExcluded(notification))) {
            removeReceivedTime(notification);
            notification.expire();
        }

        if (toastNotification === notification)
            toastNotification = null;
    }

    function toggleDnd(): void {
        dnd = !dnd;

        if (dnd)
            toastNotification = null;
    }

    function clearAll(): void {
        // Copy first because dismissing mutates the tracked model.
        const items = notifications.slice();

        for (let i = 0; i < items.length; ++i)
            items[i].dismiss();

        toastNotification = null;
        receivedTimes = ({});
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
            root.toggleDnd();
        }

        function enableDnd(): void {
            root.dnd = true;
            root.toastNotification = null;
        }

        function disableDnd(): void {
            root.dnd = false;
        }

        function isDnd(): bool {
            return root.dnd;
        }

        function clear(): void {
            root.clearAll();
        }

        function count(): int {
            return root.notificationCount;
        }
    }
}
