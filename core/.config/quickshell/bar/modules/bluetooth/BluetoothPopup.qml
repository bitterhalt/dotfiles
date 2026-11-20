import "../../../components"
import "Model.js" as Model
import QtQuick

PopoutPanel {
    id: root

    required property var popupManager
    required property var bluetoothService
    readonly property var adapter: bluetoothService.adapter
    readonly property var deviceObjects: bluetoothService.devices
    readonly property var deviceRows: Model.rows(deviceObjects)
    readonly property var connectedRows: deviceRows.filter(row => {
        return row.connected;
    })
    readonly property var pairedRows: deviceRows.filter(row => {
        return row.paired && !row.connected;
    })
    readonly property var availableRows: discoveryState.requested ? deviceRows.filter(row => {
        return !row.paired && !row.connected;
    }) : []
    readonly property var popupRows: connectedRows.concat(pairedRows, availableRows)
    property string selectedAddress: ""
    property bool confirmForget: false
    property string forgetAddress: ""
    readonly property var forgetTarget: popupRows.find(row => {
        return row.address === forgetAddress;
    }) || null
    property bool helpOpen: false

    function selectDevice(index) {
        if (popupRows.length === 0) {
            selectedAddress = "";
            return;
        }
        selectedAddress = popupRows[Math.max(0, Math.min(popupRows.length - 1, index))].address;
    }

    function selectedDevice() {
        return popupRows.find(row => {
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
            const index = popupRows.findIndex(row => {
                return row.address === selectedAddress;
            });
            selectDevice(index <= 0 ? 0 : index - 1);
        } else if (event.key === Qt.Key_Down || event.key === Qt.Key_J) {
            const index = popupRows.findIndex(row => {
                return row.address === selectedAddress;
            });
            selectDevice(index < 0 ? 0 : Math.min(popupRows.length - 1, index + 1));
        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            const row = selectedDevice();
            if (row)
                toggleDevice(row);
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

    onPopupRowsChanged: {
        if (confirmForget && !forgetTarget)
            cancelForget();

        if (popupRows.length > 0 && !popupRows.some(row => {
            return row.address === selectedAddress;
        }))
            selectedAddress = popupRows[0].address;
    }
    focus: true
    Component.onCompleted: {
        root.cancelForget();
        root.helpOpen = false;
        Qt.callLater(() => {
            return forceActiveFocus();
        });
        if (root.popupRows.length > 0 && !root.popupRows.some(row => {
            return row.address === root.selectedAddress;
        }))
            root.selectedAddress = root.popupRows[0].address;
    }
    Component.onDestruction: {
        root.cancelForget();
        root.helpOpen = false;
    }
    Keys.onPressed: event => {
        if (!root.confirmForget && discoveryState.handleKey(event.key, event.modifiers)) {
            root.helpOpen = false;
            event.accepted = true;
            return;
        }
        return root.handlePopupKey(event);
    }

    DiscoveryState {
        id: discoveryState

        bluetoothService: root.bluetoothService
    }

    Text {
        renderType: Text.NativeRendering
        width: parent.width
        visible: !root.adapter || !root.adapter.enabled
        horizontalAlignment: Text.AlignHCenter
        color: config.muted
        font.pointSize: config.textSizeMedium
        text: root.adapter ? "Bluetooth is turned off" : "No Bluetooth adapter found"
        topPadding: 10
        bottomPadding: 10
    }

    Column {
        id: deviceList
        objectName: "bluetoothDeviceList"
        width: parent.width
        spacing: 2
        visible: root.adapter && root.adapter.enabled && !root.helpOpen

        // Connected devices, then paired devices, then nearby devices.
        Repeater {
            model: root.connectedRows

            delegate: BluetoothDeviceRow {
                required property var modelData

                width: parent ? parent.width : 0
                config: root.config
                row: modelData
                highlighted: true
                trusted: modelData.trusted
                selected: modelData.address === root.selectedAddress
                onFocused: root.selectedAddress = modelData.address
                onActivated: root.toggleDevice(modelData)
            }
        }

        Repeater {
            model: root.pairedRows

            delegate: BluetoothDeviceRow {
                required property var modelData

                width: parent ? parent.width : 0
                config: root.config
                row: modelData
                actionText: ""
                trusted: modelData.trusted
                selected: modelData.address === root.selectedAddress
                onFocused: root.selectedAddress = modelData.address
                onActivated: root.toggleDevice(modelData)
            }
        }

        Repeater {
            model: root.availableRows

            delegate: BluetoothDeviceRow {
                required property var modelData

                width: parent ? parent.width : 0
                config: root.config
                row: modelData
                actionText: modelData.pairing ? "Cancel" : ""
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
            font.pointSize: config.textSizeMedium
            text: root.adapter && root.adapter.discovering ? "Scanning for devices…" : "No devices found"
            topPadding: 10
            bottomPadding: 10
        }
    }

    // Forget confirmation and keyboard help replace the normal footer.
    Text {
        renderType: Text.NativeRendering
        width: parent.width
        visible: root.confirmForget
        color: root.config.urgent
        font.pointSize: root.config.textSizeSmall
        text: "Forget " + (root.forgetTarget ? root.forgetTarget.name : "device") + "? Enter Confirm · Esc Cancel"
        wrapMode: Text.WordWrap
    }

    KeyboardHelp {
        id: bluetoothHelp
        objectName: "bluetoothKeyboardHelp"
        width: parent.width
        visible: root.helpOpen
        config: root.config
        entries: [
            {
                name: "Select device",
                key: "↑ / ↓   j / k"
            },
            {
                name: "Connect / pair",
                key: "Enter"
            },
            {
                name: "Trust / untrust",
                key: "t"
            },
            {
                name: "Forget paired device",
                key: "f"
            },
            {
                name: "Start / stop scanning",
                key: "Ctrl+S"
            },
            {
                name: "Back / close help",
                key: "Esc"
            }
        ]
    }

    // Device count/status and discovery controls.
    Item {
        objectName: "bluetoothFooter"
        width: parent.width
        height: Math.max(footerStatus.implicitHeight, scanButton.height) + root.spacing
        visible: !!root.adapter && root.adapter.enabled && !root.confirmForget && !root.helpOpen

        PanelSeparator {
            config: root.config
            anchors.top: parent.top
        }

        Text {
            id: footerStatus

            anchors.left: parent.left
            anchors.verticalCenter: scanButton.verticalCenter
            renderType: Text.NativeRendering
            color: root.config.muted
            font.pointSize: root.config.textSizeSmall
            text: root.adapter && root.adapter.discovering ? "Scanning…" : "? Help"
        }

        ShellIconButton {
            id: scanButton
            iconText: "󰑐"
            objectName: "bluetoothScanButton"
            filled: true
            opacity: hovered ? 0.8 : 1
            config: root.config

            anchors.right: parent.right
            anchors.top: parent.top
            anchors.topMargin: root.spacing
            compact: true
            iconSize: root.config.iconSize * 0.78
            text: discoveryState.requested ? "Stop" : "Scan"
            onClicked: discoveryState.toggleDiscovery()
        }
    }
}
