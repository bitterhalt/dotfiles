import QtQuick
import Quickshell
import Quickshell.Wayland

Item {
    id: manager

    required property var barWindow
    required property var config
    property bool hostRequested: false
    readonly property bool hostVisible: hostMotion.surfaceVisible
    readonly property bool hostClosing: hostMotion.closing
    property string activeKey: ""
    readonly property bool barPopupActive: ["audio", "bluetooth", "network"].includes(activeKey)
    property var hostComponent: null
    property real hostAnchorCenter: -1
    property var anchorRightOffsets: new Map()
    property bool hostFocusable: false
    property bool hostCentered: false
    readonly property bool hostMotionActive: config.popupAnimations && (barPopupActive || activeKey === "notificationCenter" || activeKey === "weather")

    function openHost(key, component, anchorItem, focusable, centered) {
        const wasRequested = hostRequested;
        const switching = activeKey !== key;
        // Cancel a pending exit before changing its animation policy.
        if (hostClosing)
            hostRequested = true;

        activeKey = key;
        hostComponent = component;
        // The bar's backing window may be hidden. Preserve its last anchor.
        const screenWidth = barWindow.screen ? barWindow.screen.width : 0;
        const savedOffset = anchorRightOffsets.get(key);
        hostAnchorCenter = anchorItem && screenWidth > 0 && Number.isFinite(savedOffset) ? screenWidth - savedOffset : -1;
        if (anchorItem && barWindow.visible && barWindow.backingWindowVisible) {
            try {
                const pos = barWindow.itemPosition(anchorItem);
                if (Number.isFinite(pos.x)) {
                    hostAnchorCenter = pos.x + anchorItem.width / 2;
                    if (screenWidth > 0)
                        anchorRightOffsets.set(key, screenWidth - hostAnchorCenter);
                }
            } catch (_) {}
        }
        hostFocusable = focusable === true;
        hostCentered = centered === true;
        // Reopening reverses an exit from its current progress. Switching an
        // already-open host starts a fresh entrance without unmapping it.
        if (wasRequested || (hostRequested && switching))
            hostMotion.restartEnter();
        else
            hostRequested = true;
    }

    function toggleHost(key, component, anchorItem, focusable, centered) {
        if (hostRequested && activeKey === key)
            closeHost();
        else
            openHost(key, component, anchorItem, focusable, centered);
    }

    function closeHost(key) {
        if (key !== undefined && key !== "" && activeKey !== key)
            return;

        hostRequested = false;
    }

    function finishClose() {
        hostFocusable = false;
        hostCentered = false;
        activeKey = "";
        hostComponent = null;
        hostAnchorCenter = -1;
    }

    function popupX(popupWidth) {
        const screenWidth = barWindow.screen ? barWindow.screen.width : popupWidth;
        if (hostCentered)
            return Math.round((screenWidth - popupWidth) / 2);

        if (hostAnchorCenter >= 0)
            return Math.max(config.popupGap, Math.min(screenWidth - popupWidth - config.popupGap, hostAnchorCenter - popupWidth / 2));

        if (barPopupActive)
            return Math.max(config.popupGap, screenWidth - popupWidth - config.popupGap);

        return Math.round((screenWidth - popupWidth) / 2);
    }

    width: 0
    height: 0

    PopupMotion {
        id: hostMotion

        duration: 150
        surfaceHeight: manager.activeKey === "notificationCenter" ? notificationSurface.height : manager.barPopupActive ? barSurface.height : submenuSurface.height
        shown: manager.hostRequested
        animationsEnabled: manager.hostMotionActive
        animationType: "fade"
        onClosed: manager.finishClose()
    }

    PopupSurface {
        id: notificationSurface

        managerRef: manager
        motion: hostMotion
        hostKey: "notificationCenter"
        surfaceNamespace: "slim-notification-center"
    }

    PopupSurface {
        id: barSurface

        managerRef: manager
        motion: hostMotion
        hostKey: "barPopup"
        surfaceNamespace: "slim-barpopup"
    }

    PopupSurface {
        id: submenuSurface

        managerRef: manager
        motion: hostMotion
        hostKey: ""
        surfaceNamespace: "slim-submenu"
    }

    // Outside clicks are caught below the bounded overlay surfaces.
    PanelWindow {
        screen: manager.barWindow.screen
        visible: manager.hostVisible
        color: "transparent"
        exclusiveZone: 0
        focusable: false
        WlrLayershell.namespace: "slim-popup-catcher"
        WlrLayershell.layer: WlrLayer.Top
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }

        MouseArea {
            anchors.fill: parent
            onClicked: manager.closeHost()
        }
    }

    component PopupSurface: PanelWindow {
        id: popupSurface

        required property var managerRef
        required property var motion
        required property string hostKey
        required property string surfaceNamespace

        screen: managerRef.barWindow.screen
        visible: managerRef.hostVisible && (hostKey === "" ? managerRef.activeKey !== "notificationCenter" && !managerRef.barPopupActive : hostKey === "barPopup" ? managerRef.barPopupActive : managerRef.activeKey === hostKey)
        color: "transparent"
        exclusiveZone: 0
        focusable: managerRef.hostFocusable && managerRef.hostRequested
        implicitWidth: popupLoader.item ? popupLoader.item.implicitWidth : 0
        implicitHeight: popupLoader.item ? popupLoader.item.implicitHeight : 0
        margins.top: managerRef.config.popupGap
        margins.left: managerRef.popupX(implicitWidth)
        WlrLayershell.namespace: surfaceNamespace
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: visible && managerRef.hostRequested ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

        anchors {
            top: true
            left: true
        }

        Item {
            anchors.fill: parent
            enabled: popupSurface.managerRef.hostRequested
            opacity: popupSurface.motion.contentOpacity

            Loader {
                id: popupLoader

                anchors.fill: parent
                active: popupSurface.visible
                sourceComponent: popupSurface.managerRef.hostComponent
            }

            transform: Translate {
                y: popupSurface.motion.contentOffset
            }
        }
    }
}
