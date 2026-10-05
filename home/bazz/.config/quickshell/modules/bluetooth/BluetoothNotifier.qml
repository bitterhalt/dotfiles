import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets

Item {
    id: root

    required property var config
    required property var barWindow
    required property var devices
    property string deviceName: ""
    property string deviceIcon: ""

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
        if (!device || shouldIgnore(device))
            return ;

        deviceName = deviceLabel(device);
        deviceIcon = device.icon || "";
        toast.visible = true;
        toastTimer.restart();
    }

    visible: false

    Repeater {
        model: root.devices

        delegate: Item {
            required property var modelData

            visible: false
            width: 0
            height: 0

            Connections {
                function onConnectedChanged() {
                    if (modelData.connected)
                        root.showConnected(modelData);

                }

                target: modelData
            }

        }

    }

    PanelWindow {
        id: toast

        screen: root.barWindow.screen
        margins.top: root.config.popupGap
        WlrLayershell.layer: WlrLayer.Overlay
        exclusiveZone: 0
        implicitHeight: 62
        visible: false
        color: "transparent"

        anchors {
            top: true
            left: true
            right: true
        }

        Rectangle {
            width: 200
            height: parent.height
            anchors.horizontalCenter: parent.horizontalCenter
            radius: root.config.popupRadius
            color: root.config.surface
            border.color: root.config.borderColor
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
                    visible: source.toString() !== ""
                }

                Text {
                    anchors.centerIn: parent
                    visible: !imageIcon.visible
                    color: root.config.accent
                    font.family: root.config.iconFontFamily
                    font.pointSize: root.config.iconSize
                    text: "󰂯"
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
                    color: root.config.fg
                    font.pointSize: root.config.fontSize(0.92)
                    font.weight: Font.DemiBold
                    elide: Text.ElideRight
                    text: root.deviceName
                }

                Text {
                    color: root.config.muted
                    font.pointSize: root.config.fontSize(0.8)
                    text: "Connected"
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
        onTriggered: toast.visible = false
    }

}
