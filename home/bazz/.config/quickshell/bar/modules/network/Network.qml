import "Model.js" as Model
import QtQuick
import Quickshell
import Quickshell.Networking

Item {
    id: root

    required property var config
    required property var barWindow
    required property var popupManager
    required property var uiService
    readonly property var networkDevices: Networking.devices ? Networking.devices.values : []
    readonly property var wifiDevice: findDevice(DeviceType.Wifi)
    readonly property var wiredDevice: findDevice(DeviceType.Wired)
    readonly property var wifiNetworkObjects: wifiDevice && wifiDevice.networks ? wifiDevice.networks.values : []
    readonly property var networkRows: Model.rows(wifiNetworkObjects)
    readonly property var selectableRows: networkRows
    readonly property var connectedWifi: {
        for (var i = 0; i < wifiNetworkObjects.length; ++i) {
            if (wifiNetworkObjects[i] && wifiNetworkObjects[i].connected)
                return wifiNetworkObjects[i];

        }
        return null;
    }
    readonly property string connectionKind: {
        if (wiredDevice && wiredDevice.connected)
            return "ethernet";

        if (connectedWifi)
            return "wifi";

        return "disconnected";
    }
    readonly property string icon: {
        if (connectionKind === "ethernet")
            return "󰈀";

        if (!Networking.wifiHardwareEnabled || !Networking.wifiEnabled)
            return "󰤭";

        if (connectedWifi)
            return Model.strengthIcon(connectedWifi.signalStrength);

        return "󰤯";
    }

    Connections {
        target: root.uiService
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
    }

    function findDevice(type) {
        var fallback = null;
        for (var i = 0; i < networkDevices.length; ++i) {
            var device = networkDevices[i];
            if (!device || device.type !== type)
                continue;

            if (device.connected)
                return device;

            if (!fallback)
                fallback = device;

        }
        return fallback;
    }

    function networkForSsid(ssid) {
        return Model.networkForSsid(wifiNetworkObjects, ssid);
    }

    width: 24
    height: barWindow.height

    Text {
        anchors.centerIn: parent
        color: config.fg
        opacity: connectionKind === "disconnected" ? 0.55 : 1
        font.family: config.iconFontFamily
        font.pointSize: config.iconSize
        text: root.icon
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: Qt.PointingHandCursor
        onClicked: (mouse) => {
            if (mouse.button === Qt.LeftButton)
                popupManager.toggleHost("network", networkPopupComponent, root, true);
            else if (wifiDevice)
                Networking.wifiEnabled = !Networking.wifiEnabled;
        }
    }

    Component {
        id: networkPopupComponent

        NetworkPopup {
            network: root
        }

    }

}
