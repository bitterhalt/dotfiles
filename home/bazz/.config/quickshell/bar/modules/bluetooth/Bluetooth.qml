import "../../../components"
import "Model.js" as Model
import QtQuick
import Quickshell
import Quickshell.Widgets

Item {
    id: root

    required property var config
    required property var barWindow
    required property var popupManager
    required property var bluetoothService
    readonly property var adapter: bluetoothService.adapter
    readonly property var deviceObjects: bluetoothService.devices
    readonly property var deviceRows: Model.rows(deviceObjects)
    readonly property var connectedRows: deviceRows.filter((row) => {
        return row.connected;
    })
    readonly property var pairedRows: deviceRows.filter((row) => {
        return row.paired && !row.connected;
    })
    readonly property var availableRows: deviceRows.filter((row) => {
        return !row.paired && !row.connected;
    })
    readonly property int connectedCount: connectedRows.length

    function toggleDevice(row) {
        bluetoothService.toggleDevice(row)
    }

    width: 24
    height: barWindow.height

    Text {
        anchors.centerIn: parent
        color: config.fg
        opacity: adapter && adapter.enabled ? (connectedCount > 0 ? 1 : 0.55) : 0.4
        font.family: config.iconFontFamily
        font.pointSize: config.iconSize
        text: adapter && adapter.enabled ? "󰂯" : "󰂲"
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: Qt.PointingHandCursor
        onClicked: (mouse) => {
            if (mouse.button === Qt.LeftButton)
                popupManager.toggleHost("bluetooth", bluetoothPopupComponent, root);
            else if (root.adapter)
                root.adapter.enabled = !root.adapter.enabled;
        }
    }

    Component {
        id: bluetoothPopupComponent

        PopoutPanel {
            id: bluetoothPopup

            config: root.config
            contentWidth: 330
            Component.onCompleted: root.bluetoothService.beginDiscovery()
            Component.onDestruction: root.bluetoothService.endDiscovery()

            Item {
                width: parent.width
                height: 28

                Text {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    color: config.fg
                    font.pointSize: config.fontSize(1.08)
                    font.weight: Font.DemiBold
                    text: "Bluetooth"
                }

                Row {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 8

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        color: config.muted
                        font.pointSize: config.fontSize(0.85)
                        text: root.adapter && root.adapter.enabled ? "On" : "Off"
                    }

                    ToggleSwitch {
                        config: root.config
                        checked: root.adapter && root.adapter.enabled
                        enabled: root.adapter !== null
                        onToggled: {
                            if (root.adapter)
                                root.adapter.enabled = !root.adapter.enabled;

                        }
                    }

                }

            }

            PanelSeparator {
                config: root.config
            }

            Text {
                width: parent.width
                visible: !root.adapter || !root.adapter.enabled
                horizontalAlignment: Text.AlignHCenter
                color: config.muted
                font.pointSize: config.fontSize(0.85)
                text: root.adapter ? "Bluetooth is turned off" : "No Bluetooth adapter found"
                topPadding: 10
                bottomPadding: 10
            }

            Column {
                width: parent.width
                spacing: 4
                visible: root.adapter && root.adapter.enabled

                SectionHeader {
                    config: root.config
                    visible: root.connectedRows.length > 0
                    text: "CONNECTED"
                }

                Repeater {
                    model: root.connectedRows

                    delegate: DeviceRow {
                        required property var modelData

                        width: parent ? parent.width : 0
                        config: root.config
                        row: modelData
                        actionText: "Disconnect"
                        highlighted: true
                        onActivated: root.toggleDevice(modelData)
                    }

                }

                SectionHeader {
                    config: root.config
                    visible: root.pairedRows.length > 0
                    text: "PAIRED"
                }

                Repeater {
                    model: root.pairedRows

                    delegate: DeviceRow {
                        required property var modelData

                        width: parent ? parent.width : 0
                        config: root.config
                        row: modelData
                        actionText: modelData.pairing ? "Cancel" : "Connect"
                        onActivated: root.toggleDevice(modelData)
                    }

                }

                Item {
                    width: parent.width
                    height: 20

                    Text {
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        color: config.muted
                        font.pointSize: config.fontSize(0.77)
                        font.weight: Font.DemiBold
                        font.letterSpacing: 0.4
                        text: "AVAILABLE"
                    }

                    Text {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        color: config.muted
                        font.pointSize: config.fontSize(0.77)
                        text: root.adapter && root.adapter.discovering ? "Scanning…" : ""
                    }

                }

                Repeater {
                    model: root.availableRows

                    delegate: DeviceRow {
                        required property var modelData

                        width: parent ? parent.width : 0
                        config: root.config
                        row: modelData
                        actionText: modelData.pairing ? "Cancel" : "Pair"
                        onActivated: root.toggleDevice(modelData)
                    }

                }

                Text {
                    width: parent.width
                    visible: root.deviceRows.length === 0
                    horizontalAlignment: Text.AlignHCenter
                    color: config.muted
                    font.pointSize: config.fontSize(0.85)
                    text: root.adapter && root.adapter.discovering ? "Scanning for devices…" : "No devices found"
                    topPadding: 10
                    bottomPadding: 10
                }

            }

        }

    }

    component DeviceRow: Item {
        id: deviceRow

        required property var config
        required property var row
        property string actionText: ""
        property bool highlighted: false

        signal activated()

        implicitHeight: 42

        Rectangle {
            anchors.fill: parent
            radius: 3
            color: deviceMouse.containsMouse ? deviceRow.config.borderColor : "transparent"
        }

        Item {
            x: 4
            width: 28
            height: parent.height

            IconImage {
                anchors.centerIn: parent
                implicitSize: 18
                source: deviceRow.row.icon ? Quickshell.iconPath(deviceRow.row.icon) : ""
                visible: source.toString() !== ""
            }

            Text {
                anchors.centerIn: parent
                visible: !deviceRow.row.icon
                color: deviceRow.highlighted ? deviceRow.config.accent : deviceRow.config.fg
                font.family: deviceRow.config.iconFontFamily
                font.pointSize: deviceRow.config.iconSize
                text: "󰂯"
            }

        }

        Column {
            x: 38
            width: parent.width - 112
            anchors.verticalCenter: parent.verticalCenter
            spacing: 0

            Text {
                width: parent.width
                color: deviceRow.config.fg
                font.pointSize: deviceRow.config.fontSize(0.92)
                font.weight: Font.DemiBold
                elide: Text.ElideRight
                text: deviceRow.row.name
            }

            Text {
                width: parent.width
                color: deviceRow.config.muted
                font.pointSize: deviceRow.config.fontSize(0.77)
                elide: Text.ElideRight
                text: {
                    if (deviceRow.row.pairing)
                        return "Pairing…";

                    if (deviceRow.row.connected) {
                        if (deviceRow.row.batteryAvailable)
                            return `Connected  ·  ${Math.round(deviceRow.row.battery * 100)}%`;

                        return "Connected";
                    }
                    return deviceRow.row.paired ? "Paired" : "Not paired";
                }
            }

        }

        Text {
            anchors.right: parent.right
            anchors.rightMargin: 6
            anchors.verticalCenter: parent.verticalCenter
            color: deviceRow.highlighted ? deviceRow.config.accent : deviceRow.config.muted
            font.pointSize: deviceRow.config.fontSize(0.77)
            text: deviceRow.actionText
        }

        MouseArea {
            id: deviceMouse

            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: deviceRow.activated()
        }

    }

}
