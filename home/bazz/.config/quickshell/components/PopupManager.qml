import QtQuick
import Quickshell
import Quickshell.Wayland

Item {
    id: manager

    required property var barWindow
    required property var config

    width: 0
    height: 0

    property bool hostVisible: false
    property string activeKey: ""
    readonly property bool barPopupActive: ["audio", "bluetooth", "network"].includes(activeKey)
    property var hostComponent: null
    property real hostAnchorCenter: -1
    property var anchorRightOffsets: new Map()
    property bool hostFocusable: false
    property bool hostCentered: false

    function openHost(key, component, anchorItem, focusable, centered) {
        activeKey = key
        hostComponent = component
        // The bar's backing window can disappear or lose its geometry while
        // hidden. Keep a snapshot instead of querying that window in popupX().
        const screenWidth = barWindow.screen ? barWindow.screen.width : 0
        const savedOffset = anchorRightOffsets.get(key)
        hostAnchorCenter = anchorItem && screenWidth > 0 && Number.isFinite(savedOffset)
            ? screenWidth - savedOffset : -1
        if (anchorItem && barWindow.visible && barWindow.backingWindowVisible) {
            try {
                const pos = barWindow.itemPosition(anchorItem)
                if (Number.isFinite(pos.x)) {
                    hostAnchorCenter = pos.x + anchorItem.width / 2
                    if (screenWidth > 0)
                        anchorRightOffsets.set(key, screenWidth - hostAnchorCenter)
                }
            } catch (_) {}
        }
        hostFocusable = focusable === true
        hostCentered = centered === true
        hostVisible = true
    }

    function toggleHost(key, component, anchorItem, focusable, centered) {
        if (hostVisible && activeKey === key) {
            closeHost()
            return
        }

        openHost(key, component, anchorItem, focusable, centered)
    }

    function closeHost(key) {
        if (key !== undefined && key !== "" && activeKey !== key)
            return

        hostVisible = false
        hostFocusable = false
        hostCentered = false
        activeKey = ""
        hostComponent = null
        hostAnchorCenter = -1
    }

    function popupX(popupWidth) {
        const screenWidth = barWindow.screen
            ? barWindow.screen.width
            : popupWidth

        if (hostCentered)
            return Math.round((screenWidth - popupWidth) / 2)

        if (hostAnchorCenter >= 0)
            return Math.max(config.popupGap, Math.min(
                screenWidth - popupWidth - config.popupGap,
                hostAnchorCenter - popupWidth / 2
            ))

        if (barPopupActive)
            return Math.max(config.popupGap, screenWidth - popupWidth - config.popupGap)

        return Math.round((screenWidth - popupWidth) / 2)
    }

    component PopupSurface: PanelWindow {
        id: popupSurface

        required property var managerRef
        required property string hostKey
        required property string surfaceNamespace

        screen: managerRef.barWindow.screen
        visible: managerRef.hostVisible
            && (hostKey === ""
                ? managerRef.activeKey !== "weather"
                    && managerRef.activeKey !== "notificationCenter"
                    && !managerRef.barPopupActive
                : hostKey === "barPopup" ? managerRef.barPopupActive
                : managerRef.activeKey === hostKey)
        color: "transparent"
        exclusiveZone: 0
        focusable: managerRef.hostFocusable
        implicitWidth: popupLoader.item
            ? popupLoader.item.implicitWidth
            : 0
        implicitHeight: popupLoader.item
            ? popupLoader.item.implicitHeight
            : 0

        anchors {
            top: true
            left: true
        }

        margins.top: managerRef.config.popupGap
        margins.left: managerRef.popupX(implicitWidth)

        WlrLayershell.namespace: surfaceNamespace
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: visible
            ? WlrKeyboardFocus.Exclusive
            : WlrKeyboardFocus.None

        Item {
            anchors.fill: parent

            Loader {
                id: popupLoader

                anchors.fill: parent
                active: popupSurface.visible
                sourceComponent: managerRef.hostComponent
            }
        }
    }

    PopupSurface {
        managerRef: manager
        hostKey: "weather"
        surfaceNamespace: "quickshell-weather"
    }

    PopupSurface {
        managerRef: manager
        hostKey: "notificationCenter"
        surfaceNamespace: "quickshell-notification-center"
    }

    PopupSurface {
        managerRef: manager
        hostKey: "barPopup"
        surfaceNamespace: "quickshell-barpopup"
    }

    PopupSurface {
        managerRef: manager
        hostKey: ""
        surfaceNamespace: "quickshell-submenu"
    }

    // The full-screen surface only catches outside clicks. It lives below the
    // card-sized overlay surfaces and intentionally has no shadow namespace.
    PanelWindow {
        screen: manager.barWindow.screen
        visible: manager.hostVisible
        color: "transparent"
        exclusiveZone: 0
        focusable: false

        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }

        WlrLayershell.namespace: "quickshell-popup-catcher"
        WlrLayershell.layer: WlrLayer.Top
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

        MouseArea {
            anchors.fill: parent
            onClicked: manager.closeHost()
        }
    }

}
