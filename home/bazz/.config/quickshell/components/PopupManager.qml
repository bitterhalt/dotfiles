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
        if (hostCentered)
            return Math.round((popupHost.width - popupWidth) / 2)

        if (hostAnchor) {
            try {
                const pos = barWindow.itemPosition(hostAnchor)
                const centeredX =
                    pos.x + hostAnchor.width / 2 - popupWidth / 2

                return Math.max(
                    config.popupGap,
                    Math.min(
                        popupHost.width - popupWidth - config.popupGap,
                        centeredX
                    )
                )
            } catch (_) {
            }
        }

        return Math.round((popupHost.width - popupWidth) / 2)
    }

    PanelWindow {
        id: popupHost

        screen: manager.barWindow.screen
        visible: manager.hostVisible
        color: "transparent"
        exclusiveZone: 0
        focusable: manager.hostFocusable

        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }

        WlrLayershell.layer: WlrLayer.Overlay

        // Declared before the popup card so interactive controls inside the
        // loaded content stay on top. Any click outside the card closes it.
        MouseArea {
            anchors.fill: parent

            onClicked: mouse => {
                const inside =
                    mouse.x >= popupContainer.x
                    && mouse.x <= popupContainer.x + popupContainer.width
                    && mouse.y >= popupContainer.y
                    && mouse.y <= popupContainer.y + popupContainer.height

                if (!inside)
                    manager.closeHost()
            }
        }

        Item {
            id: popupContainer

            x: manager.popupX(width)
            y: manager.config.popupGap

            width: popupLoader.item
                ? popupLoader.item.implicitWidth
                : 0

            height: popupLoader.item
                ? popupLoader.item.implicitHeight
                : 0

            Loader {
                id: popupLoader

                anchors.fill: parent
                active: manager.hostVisible
                sourceComponent: manager.hostComponent
            }
        }
    }
}
