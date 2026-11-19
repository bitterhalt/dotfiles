pragma ComponentBehavior: Bound

import "../../../components"
import "Model.js" as Model
import QtQuick
import Quickshell.Networking

PopoutPanel {
    id: root

    required property var network
    required property var popupManager
    property bool passwordMode: false
    property bool actionMode: false
    property bool confirmForget: false
    property string selectedSsid: ""
    property string errorText: ""
    property int selectedNetworkIndex: 0
    property int selectedActionIndex: 0
    property bool helpOpen: false
    onSelectedSsidChanged: confirmForget = false
    onActionModeChanged: confirmForget = false
    readonly property bool showNearby: scanState.resultsVisible && network.wifiBrowsingAvailable
    readonly property var selectableRows: Model.selectableRows(network.networkRows, showNearby)

    ScanState {
        id: scanState
        wifiDevice: root.network.wifiDevice
        allowed: root.network.wifiBrowsingAvailable
    }

    function resetState() {
        const previousSsid = selectedSsid;
        passwordMode = false;
        actionMode = false;
        selectedSsid = "";
        errorText = "";
        helpOpen = false;
        confirmForget = false;
        selectedActionIndex = 0;
        wifiPassword.text = "";
        Qt.callLater(() => {
            const index = root.selectableRows.findIndex(row => row.ssid === previousSsid);
            root.selectNetwork(index < 0 ? root.selectedNetworkIndex : index);
            root.forceActiveFocus();
        });
    }

    function selectNetwork(index) {
        if (selectableRows.length === 0) {
            selectedSsid = "";
            selectedNetworkIndex = 0;
            return;
        }
        selectedNetworkIndex = Math.max(0, Math.min(selectableRows.length - 1, index));
        selectedSsid = selectableRows[selectedNetworkIndex].ssid;
    }

    function openSelectedNetwork() {
        const row = selectableRows.find(row => row.ssid === selectedSsid);
        if (row)
            openRow(row);
    }

    function activateAction(index) {
        selectedActionIndex = index;
        if (index === 2) {
            resetState();
            return;
        }
        const item = actionPage.selectedNetwork;
        if (!item) {
            resetState();
            return;
        }
        if (index === 0) {
            if (item.connected)
                item.disconnect();
            else
                item.connect();
        } else if (index === 1) {
            if (!confirmForget) {
                confirmForget = true;
                actionPage.focusAction(1);
                return;
            }
            item.forget();
        }
        resetState();
    }

    function handlePopupKey(event) {
        if (!passwordMode && !actionMode && scanState.handleKey(event.key, event.modifiers)) {
            helpOpen = false;
            event.accepted = true;
            return true;
        }
        if (event.modifiers & (Qt.ControlModifier | Qt.AltModifier | Qt.MetaModifier))
            return false;
        if (passwordMode) {
            if (event.key === Qt.Key_Escape) {
                resetState();
                event.accepted = true;
                return true;
            }
            return false;
        }
        if (actionMode && !helpOpen) {
            const index = Model.actionShortcut(event.text, !!actionPage.selectedNetwork && actionPage.selectedNetwork.connected);
            if (index >= 0) {
                // Repeated shortcut presses must not confirm credential removal.
                if (index !== 1 || !confirmForget)
                    activateAction(index);
                event.accepted = true;
                return true;
            }
        }
        if (event.key === Qt.Key_Escape) {
            if (helpOpen)
                helpOpen = false;
            else if (confirmForget)
                confirmForget = false;
            else if (actionMode) {
                resetState();
            } else {
                popupManager.closeHost("network");
            }
        } else if (event.key === Qt.Key_Question || event.text === "?") {
            helpOpen = !helpOpen;
        } else if (helpOpen) {
            return false;
        } else if (actionMode && (event.key === Qt.Key_Left || event.key === Qt.Key_Right)) {
            const order = [2, 0, 1];
            const position = order.indexOf(selectedActionIndex);
            const direction = event.key === Qt.Key_Left ? -1 : 1;
            focusAction(order[Math.max(0, Math.min(order.length - 1, position + direction))]);
        } else if (!actionMode && (event.key === Qt.Key_Up || event.key === Qt.Key_K)) {
            selectNetwork(selectedNetworkIndex - 1);
        } else if (!actionMode && (event.key === Qt.Key_Down || event.key === Qt.Key_J)) {
            selectNetwork(selectedNetworkIndex + 1);
        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            if (actionMode)
                activateAction(selectedActionIndex);
            else
                openSelectedNetwork();
        } else {
            return false;
        }
        event.accepted = true;
        return true;
    }

    function focusAction(index) {
        if (index !== 1)
            confirmForget = false;
        selectedActionIndex = index;
        actionPage.focusAction(index);
    }

    function openRow(row) {
        var item = network.networkForSsid(row.ssid);
        if (!item || item.stateChanging)
            return;

        errorText = "";
        confirmForget = false;
        if (item.connected || item.known) {
            selectedSsid = row.ssid;
            selectedActionIndex = 0;
            actionMode = true;
            Qt.callLater(() => actionPage.focusAction(0));
            return;
        }
        if (item.security === WifiSecurityType.Open) {
            item.connect();
            return;
        }
        selectedSsid = row.ssid;
        popupManager.hostFocusable = true;
        passwordMode = true;
        Qt.callLater(() => {
            return wifiPassword.focusInput();
        });
    }

    focus: true
    Component.onCompleted: {
        if (selectableRows.length > 0)
            selectNetwork(0);
        Qt.callLater(() => forceActiveFocus());
    }
    Keys.onPressed: event => root.handlePopupKey(event)
    onSelectableRowsChanged: {
        if (!actionMode && !passwordMode) {
            const index = selectableRows.findIndex(row => row.ssid === selectedSsid);
            selectNetwork(index < 0 ? 0 : index);
        }
    }

    // Page title shown for connect/password/action subpages.
    Item {
        width: parent.width
        height: root.passwordMode ? 28 : 0
        visible: height > 0

        Text {
            renderType: Text.NativeRendering
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            color: root.config.fg
            font.pointSize: root.config.textSizeNormal
            font.weight: Font.DemiBold
            text: "Connect to Wi-Fi"
        }
    }

    // Connected Ethernet/Wi-Fi and nearby access points.
    Column {
        objectName: "networkDeviceList"
        width: parent.width
        spacing: 2
        visible: !root.passwordMode && !root.actionMode && !root.helpOpen

        Item {
            width: parent.width
            height: root.network.wiredDevice && root.network.wiredDevice.connected ? 36 : 0
            visible: height > 0

            Item {
                x: 4
                width: 28
                height: parent.height

                Text {
                    anchors.centerIn: parent
                    color: root.config.selectionBackground
                    font.family: root.config.iconFontFamily
                    font.pointSize: root.config.iconSize
                    text: "󰈀"
                }
            }

            Column {
                x: 38
                width: parent.width - 44
                anchors.verticalCenter: parent.verticalCenter
                spacing: 0

                Text {
                    renderType: Text.NativeRendering
                    color: root.config.fg
                    font.pointSize: root.config.textSizeMedium
                    font.weight: Font.DemiBold
                    text: "Ethernet"
                }

                Text {
                    renderType: Text.NativeRendering
                    color: root.config.muted
                    font.pointSize: root.config.textSizeSmall
                    text: root.network.wiredDevice ? root.network.wiredDevice.name : ""
                }
            }
        }

        NetworkRow {
            width: parent.width
            height: root.network.connectedWifi ? 40 : 0
            visible: height > 0
            config: root.config
            row: root.network.connectedWifi ? ({
                    ssid: root.network.connectedWifi.name,
                    strength: root.network.connectedWifi.signalStrength,
                    connected: true,
                    known: true
                }) : ({
                    ssid: "",
                    strength: 0,
                    connected: true
                })
            secured: root.network.connectedWifi ? root.network.connectedWifi.security !== WifiSecurityType.Open : true
            selected: root.network.connectedWifi !== null && root.selectedSsid === root.network.connectedWifi.name
            onFocused: {
                if (root.network.connectedWifi) {
                    root.selectedSsid = root.network.connectedWifi.name;
                    root.selectedNetworkIndex = root.selectableRows.findIndex(row => row.ssid === root.selectedSsid);
                }
            }
            onActivated: {
                if (root.network.connectedWifi)
                    root.openRow({
                        ssid: root.network.connectedWifi.name
                    });
            }
        }

        Repeater {
            model: root.showNearby ? root.network.networkRows.filter(row => {
                return !row.connected;
            }) : []

            delegate: NetworkRow {
                required property var modelData
                required property int index

                width: parent ? parent.width : 0
                height: 40
                config: root.config
                row: modelData
                secured: modelData.security !== WifiSecurityType.Open
                enabled: !modelData.stateChanging
                selected: modelData.ssid === root.selectedSsid
                onFocused: root.selectNetwork(root.selectableRows.findIndex(row => row.ssid === modelData.ssid))
                onActivated: root.openRow(modelData)
            }
        }

        Text {
            renderType: Text.NativeRendering
            width: parent.width
            visible: !root.network.wifiDevice
            horizontalAlignment: Text.AlignHCenter
            color: root.config.muted
            font.pointSize: root.config.textSizeMedium
            text: "No Wi-Fi device found"
            topPadding: 10
            bottomPadding: 10
        }

        Text {
            renderType: Text.NativeRendering
            width: parent.width
            visible: !root.network.wiredConnected && root.network.wifiDevice && !Networking.wifiEnabled
            horizontalAlignment: Text.AlignHCenter
            color: root.config.muted
            font.pointSize: root.config.textSizeMedium
            text: "Wi-Fi is turned off"
            topPadding: 10
            bottomPadding: 10
        }

        Text {
            renderType: Text.NativeRendering
            width: parent.width
            visible: root.showNearby && root.network.wifiDevice && root.network.networkRows.length === 0
            horizontalAlignment: Text.AlignHCenter
            color: root.config.muted
            font.pointSize: root.config.textSizeMedium
            text: root.network.wifiDevice && root.network.wifiDevice.scannerEnabled ? "Scanning…" : "No networks found"
            topPadding: 10
            bottomPadding: 10
        }

        Text {
            renderType: Text.NativeRendering
            width: parent.width
            visible: !root.showNearby && root.network.connectionKind === "disconnected" && scanState.canScan
            horizontalAlignment: Text.AlignHCenter
            color: root.config.muted
            font.pointSize: root.config.textSizeMedium
            text: "Not connected"
            topPadding: 10
            bottomPadding: 10
        }
    }

    // Connect, forget, and back actions for a selected network.
    NetworkActions {
        id: actionPage
        objectName: "networkActions"

        config: root.config
        selectedNetwork: root.network.networkForSsid(root.selectedSsid)
        onSelectedNetworkChanged: root.confirmForget = false
        confirmForget: root.confirmForget
        selectedIndex: root.selectedActionIndex
        onFocused: index => {
            root.selectedActionIndex = index;
            if (index !== 1)
                root.confirmForget = false;
        }
        onActivated: index => root.activateAction(index)
        width: parent.width
        visible: root.actionMode && !root.helpOpen
    }

    Text {
        width: parent.width
        visible: root.actionMode && root.confirmForget && !root.helpOpen
        renderType: Text.NativeRendering
        color: root.config.urgent
        font.pointSize: root.config.textSizeSmall
        wrapMode: Text.WordWrap
        text: "Forget saved network? Enter Confirm · Esc Cancel"
    }

    // Password entry and connection feedback.
    NetworkPasswordForm {
        id: wifiPassword
        config: root.config
        ssid: root.selectedSsid
        errorText: root.errorText
        width: parent.width
        visible: root.passwordMode
        onCancelled: root.resetState()
        onSubmitted: password => {
            const item = root.network.networkForSsid(root.selectedSsid);
            if (!item)
                return;
            root.errorText = "";
            item.connectWithPsk(password);
            root.passwordMode = false;
            wifiPassword.text = "";
            Qt.callLater(() => root.forceActiveFocus());
        }
    }

    // Keyboard help for the scan and popup shortcuts.
    KeyboardHelp {
        objectName: "networkKeyboardHelp"
        width: parent.width
        visible: root.helpOpen && !root.passwordMode
        config: root.config
        entries: root.actionMode ? [
            {
                name: "Select action",
                key: "← / →"
            },
            {
                name: actionPage.selectedNetwork && actionPage.selectedNetwork.connected ? "Disconnect" : "Connect",
                key: actionPage.selectedNetwork && actionPage.selectedNetwork.connected ? "d" : "c"
            },
            {
                name: "Forget network",
                key: "f"
            },
            {
                name: "Back / close",
                key: "Esc"
            }
        ] : [
            {
                name: "Select network",
                key: "↑ / ↓   j / k"
            },
            {
                name: "Connect",
                key: "Enter"
            },
            {
                name: "Start / stop scanning",
                key: "Ctrl+S"
            },
            {
                name: "Close",
                key: "Esc"
            }
        ]
    }

    // Bottom connection status and scan controls.
    Item {
        objectName: "networkFooter"
        width: parent.width
        height: Math.max(footerStatus.implicitHeight, scanButton.height) + root.spacing
        visible: !root.passwordMode && !root.actionMode && !root.helpOpen

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
            text: !root.network.wifiDevice ? "No Wi-Fi adapter" : !Networking.wifiEnabled ? "Wi-Fi off" : root.network.wiredConnected ? "Ethernet connected" : scanState.requested ? "Scanning…" : "? Help"
        }

        ShellIconButton {
            id: scanButton
            iconText: "󰑐"
            objectName: "networkScanButton"
            filled: true
            opacity: hovered ? 0.8 : 1
            config: root.config
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.topMargin: root.spacing
            compact: true
            iconSize: root.config.iconSize * 0.78
            enabled: scanState.canScan
            text: scanState.requested ? "Stop" : "Scan"
            onClicked: scanState.toggle()
        }
    }
}
