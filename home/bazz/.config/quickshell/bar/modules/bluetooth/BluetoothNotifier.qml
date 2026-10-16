pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets

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
    // Match critical notification cards, regardless of the current theme.
    readonly property color criticalBorderColor: "#af3029"
    readonly property color criticalTextColor: "#ad8301"
    property var batteryQueue: []

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
        if (!device || shouldIgnore(device) || (toast.visible && batteryAlert))
            return ;

        deviceName = deviceLabel(device);
        deviceIcon = device.icon || "";
        statusText = "Connected";
        batteryAlert = false;
        toast.visible = true;
        toastTimer.restart();
    }

    function showBatteryWarning(device, percent, critical) {
        const warning = {
            name: deviceLabel(device), icon: device.icon || "",
            status: (critical ? "Battery critical" : "Battery low") + " · " + percent + "%"
        }
        if (toast.visible && batteryAlert) {
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
        toast.visible = true;
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

        delegate: Item {
            id: connectionWatcher
            required property var modelData

            visible: false
            width: 0
            height: 0

            Connections {
                function onConnectedChanged() {
                    if (connectionWatcher.modelData.connected)
                        root.showConnected(connectionWatcher.modelData);

                }

                target: connectionWatcher.modelData
            }

        }

    }

    PanelWindow {
        id: toast

        screen: root.targetScreen
        margins.top: root.config.popupGap
        WlrLayershell.namespace: "quickshell-notifications"
        WlrLayershell.layer: WlrLayer.Overlay
        exclusiveZone: 0
        implicitWidth: root.batteryAlert ? 200 : 200
        implicitHeight: 62
        visible: false
        color: "transparent"

        // Anchored to the top edge only and sized to the card, so compositor
        // effects (a niri shadow) wrap the card, not a full-width strip.
        anchors.top: true

        Rectangle {
            anchors.fill: parent
            radius: root.config.popupRadius
            color: root.batteryAlert ? root.config.bg : root.config.surface
            border.color: root.batteryAlert ? root.criticalBorderColor : root.config.borderColor
            border.width: 1

            Item {
                id: iconBox

                anchors.left: parent.left
                anchors.leftMargin: 12
                anchors.verticalCenter: parent.verticalCenter
                width: 34
                height: 34

                IconImage {
                    id: imageIcon

                    anchors.centerIn: parent
                    implicitSize: 26
                    source: root.deviceIcon ? Quickshell.iconPath(root.deviceIcon) : ""
                    visible: !root.batteryAlert && source.toString() !== ""
                }

                Text {
                    anchors.centerIn: parent
                    visible: !imageIcon.visible
                    color: root.batteryAlert ? root.criticalTextColor : root.config.accent
                    font.family: root.config.iconFontFamily
                    font.pointSize: root.config.iconSize
                    text: root.batteryAlert ? "󰀧" : "󰂯"
                }

            }

            Column {
                anchors.left: iconBox.right
                anchors.leftMargin: 10
                anchors.right: parent.right
                anchors.rightMargin: 12
                anchors.verticalCenter: parent.verticalCenter
                spacing: 1

                Text {
                    width: parent.width
                    color: root.batteryAlert ? root.criticalTextColor : root.config.fg
                    font.pointSize: root.config.fontSize(0.92)
                    font.weight: Font.DemiBold
                    elide: Text.ElideRight
                    text: root.deviceName
                }

                Text {
                    color: root.batteryAlert ? root.criticalTextColor : root.config.muted
                    font.pointSize: root.config.fontSize(0.8)
                    text: root.statusText
                }

            }

        }

        mask: Region {
        }

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
                toast.visible = false;
                root.batteryAlert = false;
            }
        }
    }

}
