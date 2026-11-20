pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import "../../../components"

Item {
    id: root

    required property var config
    required property var targetScreen
    required property var bluetoothService
    readonly property var devices: bluetoothService.devices
    property string deviceName: ""
    property string deviceIcon: ""
    property string statusText: "Connected"
    property bool batteryAlert: false
    property var batteryQueue: []
    property bool toastShown: false

    function deviceLabel(device) {
        if (!device)
            return "";

        return device.name || device.deviceName || device.address || "Bluetooth device";
    }

    function shouldIgnore(device) {
        var name = deviceLabel(device).toLowerCase();
        return name.includes("mouse") || name.includes("keyboard");
    }

    function showConnected(device) {
        if (!device || !device.connected || !device.paired || device.pairing || shouldIgnore(device) || (toastShown && batteryAlert))
            return;

        deviceName = deviceLabel(device);
        deviceIcon = device.icon || "";
        statusText = "Connected";
        batteryAlert = false;
        toastShown = true;
        toastTimer.restart();
    }

    function showBatteryWarning(device, percent, critical) {
        const warning = {
            name: deviceLabel(device),
            icon: device.icon || "",
            status: (critical ? "Battery critical" : "Battery low") + " · " + percent + "%"
        };
        if (toastShown && batteryAlert) {
            batteryQueue = batteryQueue.concat([warning]);
            return;
        }
        showBatteryToast(warning);
    }

    function showBatteryToast(warning) {
        deviceName = warning.name;
        deviceIcon = warning.icon;
        statusText = warning.status;
        batteryAlert = true;
        toastShown = true;
        toastTimer.restart();
    }

    Connections {
        target: root.bluetoothService
        function onBatteryWarning(device, percent, critical) {
            root.showBatteryWarning(device, percent, critical);
        }
    }

    visible: false

    Repeater {
        model: root.devices

        delegate: ConnectionWatcher {
            required property var modelData
            device: modelData
            onConnectionReady: device => root.showConnected(device)
        }
    }

    BarToast {
        config: root.config
        targetScreen: root.targetScreen
        shown: root.toastShown
        surfaceWidth: 200
        iconSource: root.deviceIcon ? Quickshell.iconPath(root.deviceIcon) : ""
        iconText: root.batteryAlert ? "󰀧" : "󰂯"
        title: root.deviceName
        subtitle: root.statusText
        critical: root.batteryAlert
        onClosed: root.batteryAlert = false
    }

    Timer {
        id: toastTimer

        interval: 5000
        repeat: false
        onTriggered: {
            if (root.batteryQueue.length > 0) {
                const next = root.batteryQueue[0];
                root.batteryQueue = root.batteryQueue.slice(1);
                root.showBatteryToast(next);
            } else {
                root.toastShown = false;
            }
        }
    }
}
