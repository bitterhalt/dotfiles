import QtQuick

Item {
    id: root

    required property var config
    required property var barWindow
    required property var popupManager
    required property var uiService
    required property var networkService

    width: 24
    height: barWindow.height

    Connections {
        target: root.uiService

        function onNetworkActionRequested(action) {
            if (action === "close" || root.barWindow.screen !== root.uiService.targetScreen) {
                root.popupManager.closeHost("network");
                return;
            }
            if (action === "open")
                root.popupManager.openHost("network", networkPopupComponent, root, true);
            else if (action === "toggle")
                root.popupManager.toggleHost("network", networkPopupComponent, root, true);
        }
    }

    Text {
        objectName: "networkIcon"
        anchors.centerIn: parent
        color: root.networkService.connectionKind === "disconnected" || networkMouse.containsMouse ? root.config.muted : root.config.fg
        font.family: root.config.iconFontFamily
        font.pointSize: root.config.iconSize
        text: root.networkService.icon
    }

    // Left-click opens the network popup.
    MouseArea {
        id: networkMouse

        anchors.fill: parent
        acceptedButtons: Qt.LeftButton
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.popupManager.toggleHost("network", networkPopupComponent, root, true)
    }

    Component {
        id: networkPopupComponent

        NetworkPopup {
            config: root.config
            popupManager: root.popupManager
            networkService: root.networkService
        }
    }
}
