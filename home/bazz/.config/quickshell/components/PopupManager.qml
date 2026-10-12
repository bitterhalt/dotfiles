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
    property var hostComponent: null
    property var hostAnchor: null
    property bool hostFocusable: false
    property bool hostCentered: false

    function openHost(key, component, anchorItem, focusable, centered) {
        activeKey = key
        hostComponent = component
        hostAnchor = anchorItem
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
        hostAnchor = null
    }

    function popupX(popupWidth) {
        const screenWidth = barWindow.screen
            ? barWindow.screen.width
            : popupWidth

        if (hostCentered)
            return Math.round((screenWidth - popupWidth) / 2)

        if (hostAnchor) {
            try {
                const pos = barWindow.itemPosition(hostAnchor)
                const centeredX =
                    pos.x + hostAnchor.width / 2 - popupWidth / 2

                return Math.max(
                    config.popupGap,
                    Math.min(
                        screenWidth - popupWidth - config.popupGap,
                        centeredX
                    )
                )
            } catch (_) {
            }
        }

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
        surfaceNamespace: "weather"
    }

    PopupSurface {
        managerRef: manager
        hostKey: "notificationCenter"
        surfaceNamespace: "notifications"
    }

    PopupSurface {
        managerRef: manager
        hostKey: ""
        surfaceNamespace: "quickshell-popup"
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
