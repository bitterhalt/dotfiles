import QtQuick
import Quickshell.Networking
import "../bar/modules/network/Model.js" as Model

// Adapter selection and network rows are shared, popup navigation is local.
Item {
    id: root
    visible: false

    readonly property var networkDevices: Networking.devices ? Networking.devices.values : []
    readonly property var wifiDevice: findDevice(DeviceType.Wifi)
    readonly property var wiredDevice: findDevice(DeviceType.Wired)
    readonly property var wifiNetworkObjects: wifiDevice && wifiDevice.networks ? wifiDevice.networks.values : []
    readonly property var networkRows: Model.rows(wifiNetworkObjects)
    readonly property bool wiredConnected: wiredDevice !== null && wiredDevice.connected
    readonly property bool wifiBrowsingAvailable: Model.shouldScanWifi(Networking.wifiEnabled, wiredConnected)
    readonly property var connectedWifi: wifiNetworkObjects.find(network => network && network.connected) || null
    readonly property string connectionKind: wiredConnected ? "ethernet" : connectedWifi ? "wifi" : "disconnected"
    readonly property string icon: {
        if (wiredConnected)
            return "󰈀";
        if (!Networking.wifiHardwareEnabled || !Networking.wifiEnabled)
            return "󰤭";
        return connectedWifi ? Model.strengthIcon(connectedWifi.signalStrength) : "󰤯";
    }

    function findDevice(type) {
        const devices = networkDevices.filter(device => device && device.type === type);
        return devices.find(device => device.connected) || devices[0] || null;
    }

    function networkForSsid(ssid) {
        return Model.networkForSsid(wifiNetworkObjects, ssid);
    }
}
