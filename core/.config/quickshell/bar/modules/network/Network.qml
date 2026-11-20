import QtQuick
import Quickshell

Item {
    id: root

    required property var config
    required property var barWindow
    required property var popupManager
    required property var uiService
    required property var networkService

    width: 24
    height: barWindow.height

    // IPC actions open/close the popup on the screen that owns the bar.
    Connections {
        function onNetworkActionRequested(action) {
            if (root.barWindow.screen !== root.uiService.targetScreen) {
                root.popupManager.closeHost("network");
                return;
            }
            if (action === "open")
                root.popupManager.openHost("network", networkPopupComponent, root, true);
            else if (action === "toggle")
                root.popupManager.toggleHost("network", networkPopupComponent, root, true);
            else if (action === "close")
                root.popupManager.closeHost("network");
        }

        target: root.uiService
    }

    Text {
        anchors.centerIn: parent
        color: config.fg
        opacity: root.networkService.connectionKind === "disconnected" ? 0.55 : 1
        font.family: config.iconFontFamily
        font.pointSize: config.iconSize
        text: root.networkService.icon
    }

    // Click the bar icon to open the network popup.
    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton
        cursorShape: Qt.PointingHandCursor
        onClicked: popupManager.toggleHost("network", networkPopupComponent, root, true)
    }

    Component {
        id: networkPopupComponent

        NetworkPopup {
            network: root.networkService
            config: root.config
            popupManager: root.popupManager
        }
    }
}
