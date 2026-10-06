import QtQuick
import Quickshell
import Quickshell.Wayland

Item {
    id: manager

    required property var barWindow
    required property var config

    width: 0
    height: 0

    // Existing PopupWindow/PopoutPanel support. Audio/network/bluetooth/tray
    // can keep using popupManager.toggle(...) while we migrate gradually.
    property var current: null

    // Shared shell-managed popup host.
    property bool hostVisible: false
    property string activeKey: ""
    property var hostComponent: null
    property var hostAnchor: null
    property bool hostFocusable: false

    function toggle(popup) {
        closeHost()

        const opening = !popup.visible

        if (current && current !== popup)
            current.visible = false

        popup.visible = opening
        current = opening ? popup : null
    }

    function close(popup) {
        popup.visible = false

        if (current === popup)
            current = null
    }

    function closeAll() {
        if (current)
            current.visible = false

        current = null
        closeHost()
    }

    function openHost(key, component, anchorItem, focusable) {
        if (current)
            current.visible = false

        current = null
        activeKey = key
        hostComponent = component
        hostAnchor = anchorItem
        hostFocusable = focusable === true
        hostVisible = true
    }

    function toggleHost(key, component, anchorItem) {
        if (hostVisible && activeKey === key) {
            closeHost()
            return
        }

        openHost(key, component, anchorItem)
    }

    function closeHost(key) {
        if (key !== undefined && key !== "" && activeKey !== key)
            return

        hostVisible = false
        hostFocusable = false
        activeKey = ""
        hostComponent = null
        hostAnchor = null
    }

    function popupX(popupWidth) {
        if (hostAnchor) {
            try {
                const pos = barWindow.itemPosition(hostAnchor)
                const centered =
                    pos.x + hostAnchor.width / 2 - popupWidth / 2

                return Math.max(
                    config.popupGap,
                    Math.min(
                        barWindow.width - popupWidth - config.popupGap,
                        centered
                    )
                )
            } catch (_) {
            }
        }

        return Math.round((barWindow.width - popupWidth) / 2)
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
