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
    required property var uiService
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
    readonly property var popupRows: connectedRows.concat(pairedRows, availableRows)
    property string selectedAddress: ""
    property bool confirmForget: false
    property string forgetAddress: ""
    readonly property var forgetTarget: popupRows.find(row => row.address === forgetAddress) || null
    property bool helpOpen: false

    function selectDevice(index) {
        if (popupRows.length === 0) {
            selectedAddress = "";
            return ;
        }
        selectedAddress = popupRows[Math.max(0, Math.min(popupRows.length - 1, index))].address;
    }

    function selectedDevice() {
        return popupRows.find((row) => {
            return row.address === selectedAddress;
        }) || null;
    }

    function handlePopupKey(event) {
        if (event.modifiers & (Qt.ControlModifier | Qt.AltModifier | Qt.MetaModifier))
            return false;

        if (confirmForget) {
            if (event.key === Qt.Key_Escape) {
                cancelForget();
            } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                const row = forgetTarget;
                cancelForget();
                if (adapter && adapter.enabled && row && row.paired)
                    bluetoothService.forgetDevice(row);
            }
            event.accepted = true;
            return true;
        }
        if (event.key === Qt.Key_Escape) {
            if (helpOpen)
                helpOpen = false;
            else
                popupManager.closeHost("bluetooth");
        } else if (event.key === Qt.Key_Question || event.text === "?") {
            helpOpen = !helpOpen;
        } else if (helpOpen || !adapter || !adapter.enabled) {
            return false;
        } else if (event.key === Qt.Key_Up || event.key === Qt.Key_K) {
            const index = popupRows.findIndex((row) => {
                return row.address === selectedAddress;
            });
            selectDevice(index <= 0 ? 0 : index - 1);
        } else if (event.key === Qt.Key_Down || event.key === Qt.Key_J) {
            const index = popupRows.findIndex((row) => {
                return row.address === selectedAddress;
            });
            selectDevice(index < 0 ? 0 : Math.min(popupRows.length - 1, index + 1));
        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            const row = selectedDevice();
            if (row) {
                toggleDevice(row);
            }
        } else if (event.key === Qt.Key_T) {
            const row = selectedDevice();
            if (row && row.paired)
                bluetoothService.toggleTrust(row);

        } else if (event.key === Qt.Key_F) {
            const row = selectedDevice();
            if (row && row.paired) {
                forgetAddress = row.address;
                confirmForget = true;
            }

        } else {
            return false;
        }
        event.accepted = true;
        return true;
    }

    function toggleDevice(row) {
        if (confirmForget || helpOpen || !adapter || !adapter.enabled)
            return;
        bluetoothService.toggleDevice(row);
    }

    function cancelForget() {
        confirmForget = false;
        forgetAddress = "";
    }

    onPopupRowsChanged: Qt.callLater(() => {
        if (confirmForget && !forgetTarget)
            cancelForget();
        if (popupRows.length > 0 && !popupRows.some((row) => {
            return row.address === selectedAddress;
        }))
            selectedAddress = popupRows[0].address;

    })
    width: 24
    height: barWindow.height

    Connections {
        function onBluetoothActionRequested(action) {
            if (root.barWindow.screen !== root.uiService.targetScreen) {
                root.popupManager.closeHost("bluetooth");
                return ;
            }
            if (action === "open")
                root.popupManager.openHost("bluetooth", bluetoothPopupComponent, root, true);
            else if (action === "toggle")
                root.popupManager.toggleHost("bluetooth", bluetoothPopupComponent, root, true);
            else if (action === "close")
                root.popupManager.closeHost("bluetooth");
        }

        target: root.uiService
    }

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
                popupManager.toggleHost("bluetooth", bluetoothPopupComponent, root, true);
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
            focus: true
            Component.onCompleted: {
                root.cancelForget();
                root.helpOpen = false;
                root.bluetoothService.beginDiscovery();
                Qt.callLater(() => {
                    return forceActiveFocus();
                });
                if (root.popupRows.length > 0 && !root.popupRows.some((row) => {
                    return row.address === root.selectedAddress;
                }))
                    root.selectedAddress = root.popupRows[0].address;

            }
            Component.onDestruction: {
                root.cancelForget();
                root.helpOpen = false;
                root.bluetoothService.endDiscovery();
            }
            Keys.onPressed: (event) => {
                return root.handlePopupKey(event);
            }

            Item {
                width: parent.width
                height: 28

                Text {
                    renderType: Text.NativeRendering
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    color: config.fg
                    font.pointSize: config.fontSize(1)
                    font.weight: Font.DemiBold
                    text: "Bluetooth"
                }

                Row {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 8

                    Text {
                        renderType: Text.NativeRendering
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
                renderType: Text.NativeRendering
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
                spacing: 2
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
                        trusted: modelData.trusted
                        selected: modelData.address === root.selectedAddress
                        onFocused: root.selectedAddress = modelData.address
                        onActivated: root.toggleDevice(modelData)
                    }

                }

                SectionHeader {
                    renderType: Text.NativeRendering
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
                        trusted: modelData.trusted
                        selected: modelData.address === root.selectedAddress
                        onFocused: root.selectedAddress = modelData.address
                        onActivated: root.toggleDevice(modelData)
                    }

                }

                Item {
                    width: parent.width
                    height: 18

                    Text {
                        renderType: Text.NativeRendering
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        color: config.muted
                        font.pointSize: config.fontSize(0.77)
                        font.weight: Font.DemiBold
                        font.letterSpacing: 0.4
                        text: "AVAILABLE"
                    }

                    Text {
                        renderType: Text.NativeRendering
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
                        trusted: modelData.trusted
                        selected: modelData.address === root.selectedAddress
                        onFocused: root.selectedAddress = modelData.address
                        onActivated: root.toggleDevice(modelData)
                    }

                }

                Text {
                    renderType: Text.NativeRendering
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

            Text {
                renderType: Text.NativeRendering
                width: parent.width
                visible: root.confirmForget
                color: root.config.urgent
                font.pointSize: root.config.fontSize(0.8)
                text: "Forget " + (root.forgetTarget ? root.forgetTarget.name : "device") + "? Enter Confirm · Esc Cancel"
                wrapMode: Text.WordWrap
            }

            Text {
                renderType: Text.NativeRendering
                width: parent.width
                visible: root.helpOpen
                color: root.config.muted
                font.pointSize: root.config.fontSize(0.78)
                text: "↑/↓ or j/k Select · Enter Connect/Pair · t Trust/Untrust · f Forget · ?/Esc Back"
                wrapMode: Text.WordWrap
            }

        }

    }

    component DeviceRow: Item {
        id: deviceRow

        required property var config
        required property var row
        property string actionText: ""
        property bool highlighted: false
        property bool trusted: false
        property bool selected: false
        readonly property string detailText: {
            if (deviceRow.row.pairing)
                return "Pairing…";

            if (deviceRow.row.connected) {
                if (deviceRow.row.batteryAvailable)
                    return `Connected  ·  ${Math.round(deviceRow.row.battery * 100)}%`;

                return "Connected";
            }
            return "";
        }

        signal activated()
        signal focused()

        implicitHeight: detailText === "" ? 28 : 36

        Rectangle {
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.topMargin: 3
            anchors.bottomMargin: 3
            width: 2
            radius: 1
            color: deviceRow.config.accent
            visible: deviceRow.selected
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
            width: Math.max(0, parent.width - x - actionColumn.width - 12)
            anchors.verticalCenter: parent.verticalCenter
            spacing: 0

            Row {
                width: parent.width
                spacing: 4

                Text {
                    id: trustedStar
                    width: deviceRow.trusted ? 12 : 0
                    color: deviceRow.config.accent
                    font.pointSize: deviceRow.config.fontSize(0.78)
                    font.weight: Font.DemiBold
                    text: "★"
                    visible: deviceRow.trusted
                }

                Text {
                    renderType: Text.NativeRendering
                    width: Math.max(0, parent.width - trustedStar.width - (deviceRow.trusted ? 4 : 0))
                    color: deviceMouse.containsMouse ? Qt.lighter(deviceRow.config.fg, 1.15) : deviceRow.config.fg
                    font.pointSize: deviceRow.config.fontSize(0.92)
                    font.weight: deviceRow.selected || deviceRow.highlighted ? Font.DemiBold : Font.Normal
                    elide: Text.ElideRight
                    text: deviceRow.row.name
                }

            }

            Text {
                renderType: Text.NativeRendering
                width: parent.width
                visible: deviceRow.detailText !== ""
                color: deviceRow.config.muted
                font.pointSize: deviceRow.config.fontSize(0.77)
                elide: Text.ElideRight
                text: deviceRow.detailText
            }

        }

        Item {
            id: actionColumn

            anchors.right: parent.right
            anchors.rightMargin: 6
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: 72

            Text {
                renderType: Text.NativeRendering
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width
                horizontalAlignment: Text.AlignRight
                color: deviceRow.highlighted ? deviceRow.config.accent : deviceRow.config.muted
                font.pointSize: deviceRow.config.fontSize(0.77)
                elide: Text.ElideRight
                text: deviceRow.actionText
            }

        }

        MouseArea {
            id: deviceMouse

            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onEntered: deviceRow.focused()
            onClicked: {
                deviceRow.focused();
                deviceRow.activated();
            }
        }

    }

}
