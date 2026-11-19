import QtQuick
import Quickshell
import Quickshell.Wayland
import "../components"
import "ToastPolicy.js" as ToastPolicy

Scope {
    id: root

    required property var config
    required property var targetScreen
    required property var notificationService

    // Active toasts, newest first. Delegates are keyed by the notification
    // object, so each toast keeps its own timer while others come and go.
    property var toasts: []
    // Retain outgoing delegates until their exit has completed.
    property var renderedToasts: []
    property var pendingFinish: []
    onToastsChanged: {
        const retained = ToastPolicy.retainForExit(toasts, renderedToasts, maxToasts);
        const dropped = renderedToasts.filter(item => retained.indexOf(item) === -1);
        renderedToasts = retained;
        // Bursts must not create an unbounded number of retiring windows.
        for (const notification of dropped)
            finishExit(notification);
    }

    function finishExit(notification) {
        const finish = pendingFinish.indexOf(notification) !== -1;
        pendingFinish = pendingFinish.filter(item => item !== notification);
        renderedToasts = renderedToasts.filter(item => item !== notification);
        if (finish)
            notificationService.finishToast(notification);
    }
    // Non-transient toasts bumped off the stack remain in the center.
    property var overflowedNotifications: []
    readonly property int overflowCount: overflowedNotifications.length

    signal openNotificationCenterRequested

    readonly property int maxToasts: 3
    readonly property int toastWidth: 380
    readonly property int toastHeight: 100
    readonly property int toastSpacing: 8
    readonly property int chipHeight: 24
    readonly property int defaultToastTimeoutMs: 5000

    function toastOffset(index) {
        return index * (toastHeight + toastSpacing);
    }

    // expireTimeout is the raw D-Bus value in milliseconds (despite what the
    // Quickshell docs say): -1 = unspecified, 0 = never expire.
    function toastTimeoutMs(notification): int {
        if (!notification || notification.expireTimeout < 0)
            return defaultToastTimeoutMs;

        return Math.round(notification.expireTimeout);
    }

    function show(newNotification): void {
        if (!newNotification || toasts.indexOf(newNotification) !== -1)
            return;
        const next = [newNotification].concat(toasts);

        while (next.length > maxToasts) {
            const overflowed = next.pop();

            if (overflowed.transient || notificationService.isHistoryExcluded(overflowed))
                pendingFinish = pendingFinish.concat([overflowed]);
            else
                overflowedNotifications = overflowedNotifications.concat([overflowed]);
        }

        toasts = next;
    }

    // Remove from the stack only (e.g. the notification was closed elsewhere).
    function removeToast(notification): void {
        toasts = toasts.filter(toast => toast !== notification);

        // The "+N more" count belongs to the current burst of toasts. Once
        // the stack is empty, forget it so it doesn't reappear on the next one.
        if (toasts.length === 0)
            overflowedNotifications = [];
    }

    function removeOverflowed(notification): void {
        overflowedNotifications = overflowedNotifications.filter(item => item !== notification);
    }

    // Remove from the stack and let the service finish it (expires transients).
    function dismissToast(notification): void {
        if (toasts.indexOf(notification) === -1)
            return;
        pendingFinish = pendingFinish.concat([notification]);
        removeToast(notification);
    }

    // Hides every toast; notifications stay in the center.
    function hide(): void {
        const current = toasts;

        pendingFinish = pendingFinish.concat(current);
        toasts = [];
        overflowedNotifications = [];
    }

    Connections {
        target: root.notificationService

        function onDndChanged(): void {
            if (root.notificationService.dnd)
                root.hide();
        }
    }

    // One layer surface per toast, each exactly card-sized. Compositor effects
    // (a niri shadow, say) then wrap each card, and the gaps between cards stay
    // empty instead of being filled by one big surface.
    Variants {
        model: root.renderedToasts

        // Each toast is its own card-sized surface so shadows follow its shape.
        delegate: PanelWindow {
            id: toastWindow

            required property var modelData

            // Position in the stack (0 = newest, at the top).
            readonly property int slot: Math.max(0, root.renderedToasts.indexOf(modelData))
            readonly property int activeSlot: root.toasts.indexOf(modelData)
            readonly property bool toastActive: activeSlot >= 0
            visible: toastMotion.surfaceVisible

            PopupMotion {
                id: toastMotion
                duration: 150
                surfaceHeight: toastWindow.height
                shown: toastWindow.toastActive
                animationsEnabled: root.config.popupAnimations
                animationType: "slide"
                onClosed: root.finishExit(toastWindow.modelData)
            }

            screen: root.targetScreen
            anchors.top: true
            anchors.left: true
            margins.top: root.config.popupGap + root.toastOffset(slot)
            margins.left: root.targetScreen ? Math.max(0, Math.round((root.targetScreen.width - root.toastWidth) / 2)) : 0

            WlrLayershell.namespace: "slim-notifications"
            WlrLayershell.layer: WlrLayer.Overlay

            exclusiveZone: 0
            implicitWidth: root.toastWidth
            implicitHeight: root.toastHeight
            color: "transparent"

            HoverHandler {
                id: hover
                onHoveredChanged: {
                    if (hovered) {
                        if (expiry.running)
                            toastWindow.remainingMs = Math.max(1, toastWindow.remainingMs - (Date.now() - toastWindow.startedAt));
                        expiry.stop();
                    } else if (toastWindow.toastActive && toastWindow.remainingMs > 0) {
                        toastWindow.startedAt = Date.now();
                        expiry.restart();
                    }
                }
            }

            NotificationCard {
                id: card

                width: parent.width
                height: root.toastHeight
                opacity: toastMotion.contentOpacity
                transform: Translate {
                    y: toastMotion.contentOffset
                }

                config: root.config
                notification: toastWindow.modelData
            }

            MouseArea {
                anchors.fill: parent
                enabled: toastWindow.toastActive
                cursorShape: Qt.PointingHandCursor

                onClicked: root.dismissToast(toastWindow.modelData)
            }

            property int remainingMs: root.toastTimeoutMs(modelData)
            property double startedAt: 0
            Component.onCompleted: {
                if (activeSlot < 0)
                    Qt.callLater(() => root.finishExit(toastWindow.modelData));
                if (remainingMs > 0 && !hover.hovered) {
                    startedAt = Date.now();
                    expiry.start();
                }
            }
            onToastActiveChanged: if (!toastActive)
                expiry.stop()

            // Hovering preserves the remaining countdown.
            Timer {
                id: expiry
                interval: Math.max(1, toastWindow.remainingMs)
                repeat: false

                onTriggered: root.dismissToast(toastWindow.modelData)
            }

            Connections {
                target: toastWindow.modelData

                function onClosed(): void {
                    // Closed notification objects cannot safely be retained
                    // for an exit; drop their surfaces immediately.
                    root.pendingFinish = root.pendingFinish.filter(item => item !== toastWindow.modelData);
                    root.renderedToasts = root.renderedToasts.filter(item => item !== toastWindow.modelData);
                    root.removeToast(toastWindow.modelData);
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
        margins.top: root.config.popupGap + root.toastOffset(root.renderedToasts.length)
        margins.left: root.targetScreen ? Math.max(0, Math.round((root.targetScreen.width - root.toastWidth) / 2)) : 0

        WlrLayershell.namespace: "slim-notifications"
        WlrLayershell.layer: WlrLayer.Overlay

        exclusiveZone: 0
        implicitWidth: root.toastWidth
        implicitHeight: root.chipHeight
        visible: chipMotion.surfaceVisible
        color: "transparent"

        PopupMotion {
            id: chipMotion
            duration: 150
            surfaceHeight: root.chipHeight
            shown: root.toasts.length > 0 && root.overflowCount > 0
            animationsEnabled: root.config.popupAnimations
            animationType: "slide"
        }

        // Stop tracking bumped notifications once they are closed elsewhere.
        Repeater {
            model: root.overflowedNotifications

            delegate: Item {
                required property var modelData

                visible: false

                Connections {
                    target: modelData

                    function onClosed(): void {
                        root.removeOverflowed(modelData);
                    }
                }
            }
        }

        PanelSurface {
            anchors.fill: parent
            config: root.config
            enabled: chipMotion.shown
            opacity: chipMotion.contentOpacity
            transform: Translate {
                y: chipMotion.contentOffset
            }
            border.color: root.config.selectionBackground

            Text {
                renderType: Text.NativeRendering
                anchors.centerIn: parent
                color: root.config.muted
                font.pointSize: root.config.textSizeSmall
                text: "+" + root.overflowCount + " more in notification center"
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor

                onClicked: {
                    root.hide();
                    root.openNotificationCenterRequested();
                }
            }
        }
    }
}
