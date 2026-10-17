pragma ComponentBehavior: Bound

import "../../../components"
import "Model.js" as Model
import QtQuick
import QtQuick.Controls
import Quickshell.Networking

PopoutPanel {
    id: root

    required property var network
    property bool passwordMode: false
    property bool actionMode: false
    property string selectedSsid: ""
    property string errorText: ""
    property int selectedNetworkIndex: 0
    property int selectedActionIndex: 0
    property bool helpOpen: false
    readonly property var selectableRows: network.selectableRows

    function resetState() {
        const previousSsid = selectedSsid;
        passwordMode = false;
        actionMode = false;
        selectedSsid = "";
        errorText = "";
        helpOpen = false;
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
            item.forget();
        }
        resetState();
    }

    function handlePopupKey(event) {
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
        if (event.key === Qt.Key_Escape) {
            if (helpOpen)
                helpOpen = false;
            else if (actionMode) {
                resetState();
            } else {
                network.popupManager.closeHost("network");
            }
        } else if (event.key === Qt.Key_Question || event.text === "?") {
            helpOpen = !helpOpen;
        } else if (helpOpen) {
            return false;
        } else if (event.key === Qt.Key_Up || event.key === Qt.Key_K) {
            if (actionMode)
                focusAction(Math.max(0, selectedActionIndex - 1));
            else
                selectNetwork(selectedNetworkIndex - 1);
        } else if (event.key === Qt.Key_Down || event.key === Qt.Key_J) {
            if (actionMode)
                focusAction(Math.min(2, selectedActionIndex + 1));
            else
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
        selectedActionIndex = index;
        if (index === 0) connectAction.forceActiveFocus();
        else if (index === 1) forgetAction.forceActiveFocus();
        else cancelAction.forceActiveFocus();
    }

    function openRow(row) {
        var item = network.networkForSsid(row.ssid);
        if (!item || item.stateChanging)
            return ;

        errorText = "";
        if (item.connected || item.known) {
            selectedSsid = row.ssid;
            selectedActionIndex = 0;
            actionMode = true;
            Qt.callLater(() => connectAction.forceActiveFocus());
            return ;
        }
        if (item.security === WifiSecurityType.Open) {
            item.connect();
            return ;
        }
        selectedSsid = row.ssid;
        network.popupManager.hostFocusable = true;
        passwordMode = true;
        Qt.callLater(() => {
            return wifiPassword.forceActiveFocus();
        });
    }

    config: network.config
    contentWidth: 240
    focus: true
    Component.onCompleted: {
        if (network.wifiDevice)
            network.wifiDevice.scannerEnabled = Networking.wifiEnabled;
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
    Component.onDestruction: {
        if (network.wifiDevice)
            network.wifiDevice.scannerEnabled = false;

    }

    Item {
        width: parent.width
        height: 28

        Text {
            renderType: Text.NativeRendering
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            color: root.config.fg
            font.pointSize: root.config.fontSize(1)
            font.weight: Font.DemiBold
            text: root.passwordMode ? "Connect to Wi-Fi" : (root.actionMode ? "Wi-Fi network" : "Network")
        }

        Row {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: 8
            visible: !root.passwordMode && !root.actionMode && root.network.wifiDevice !== null

            Text {
                renderType: Text.NativeRendering
                anchors.verticalCenter: parent.verticalCenter
                color: root.config.muted
                font.pointSize: root.config.fontSize(0.85)
                text: Networking.wifiEnabled ? "Wi-Fi On" : "Wi-Fi Off"
            }

            ToggleSwitch {
                config: root.config
                checked: Networking.wifiEnabled
                onToggled: Networking.wifiEnabled = !Networking.wifiEnabled
            }

        }

    }

    PanelSeparator {
        config: root.config
    }

    Column {
        width: parent.width
        spacing: 2
        visible: !root.passwordMode && !root.actionMode

        SectionHeader {
            renderType: Text.NativeRendering
            config: root.config
            visible: root.network.connectionKind !== "disconnected"
            text: "CONNECTED"
        }

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
                    color: root.config.accent
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
                    font.pointSize: root.config.fontSize(0.92)
                    font.weight: Font.DemiBold
                    text: "Ethernet"
                }

                Text {
                    renderType: Text.NativeRendering
                    color: root.config.muted
                    font.pointSize: root.config.fontSize(0.77)
                    text: root.network.wiredDevice ? root.network.wiredDevice.name : ""
                }

            }

        }

        Item {
            width: parent.width
            height: root.network.connectedWifi ? 30 : 0
            visible: height > 0

            Rectangle {
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                anchors.topMargin: 3
                anchors.bottomMargin: 3
                width: 2
                radius: 1
                color: root.config.accent
                visible: root.selectedSsid === root.network.connectedWifi?.name && !root.actionMode
            }

            Item {
                x: 4
                width: 28
                height: parent.height

                Text {
                    anchors.centerIn: parent
                    color: root.config.accent
                    font.family: root.config.iconFontFamily
                    font.pointSize: root.config.iconSize
                    text: root.network.connectedWifi ? Model.strengthIcon(root.network.connectedWifi.signalStrength) : ""
                }
            }

            Column {
                x: 38
                width: parent.width - 44
                anchors.verticalCenter: parent.verticalCenter
                spacing: 0

                Text {
                    renderType: Text.NativeRendering
                    width: parent.width
                    color: root.config.fg
                    font.pointSize: root.config.fontSize(0.92)
                    font.weight: Font.DemiBold
                    elide: Text.ElideRight
                    text: root.network.connectedWifi ? root.network.connectedWifi.name : ""
                }

            }

            MouseArea {
                id: connectedWifiMouse

                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    if (!root.network.connectedWifi)
                        return ;

                    root.openRow({ssid: root.network.connectedWifi.name});
                }
                onEntered: {
                    if (root.network.connectedWifi) {
                        root.selectedSsid = root.network.connectedWifi.name;
                        root.selectedNetworkIndex = root.network.selectableRows.findIndex(
                            row => row.ssid === root.selectedSsid);
                    }
                }
            }

        }

        SectionHeader {
            renderType: Text.NativeRendering
            config: root.config
            visible: Networking.wifiEnabled && root.network.wifiDevice !== null
            text: "AVAILABLE NETWORKS"
        }

        Repeater {
            model: root.network.networkRows.filter((row) => {
                return !row.connected;
            })

            delegate: NetworkRow {
                required property var modelData
                required property int index

                width: parent ? parent.width : 0
                height: 30
                config: root.config
                row: modelData
                enabled: !modelData.stateChanging
                selected: modelData.ssid === root.selectedSsid
                onFocused: root.selectNetwork(root.network.selectableRows.findIndex(
                    row => row.ssid === modelData.ssid))
                onActivated: root.openRow(modelData)
            }

        }

        Text {
            renderType: Text.NativeRendering
            width: parent.width
            visible: !root.network.wifiDevice
            horizontalAlignment: Text.AlignHCenter
            color: root.config.muted
            font.pointSize: root.config.fontSize(0.85)
            text: "No Wi-Fi device found"
            topPadding: 10
            bottomPadding: 10
        }

        Text {
            renderType: Text.NativeRendering
            width: parent.width
            visible: root.network.wifiDevice && !Networking.wifiEnabled
            horizontalAlignment: Text.AlignHCenter
            color: root.config.muted
            font.pointSize: root.config.fontSize(0.85)
            text: "Wi-Fi is turned off"
            topPadding: 10
            bottomPadding: 10
        }

        Text {
            renderType: Text.NativeRendering
            width: parent.width
            visible: root.network.wifiDevice && Networking.wifiEnabled && root.network.networkRows.length === 0
            horizontalAlignment: Text.AlignHCenter
            color: root.config.muted
            font.pointSize: root.config.fontSize(0.85)
            text: root.network.wifiDevice && root.network.wifiDevice.scannerEnabled ? "Scanning…" : "No networks found"
            topPadding: 10
            bottomPadding: 10
        }

    }

    Column {
        id: actionPage

        readonly property var selectedNetwork: root.network.networkForSsid(root.selectedSsid)

        width: parent.width
        spacing: 8
        visible: root.actionMode

        Text {
            renderType: Text.NativeRendering
            width: parent.width
            color: root.config.fg
            font.pointSize: root.config.fontSize(0.92)
            font.weight: Font.DemiBold
            elide: Text.ElideRight
            text: root.selectedSsid
        }

        Text {
            renderType: Text.NativeRendering
            color: root.config.muted
            font.pointSize: root.config.fontSize(0.77)
            text: parent.selectedNetwork && parent.selectedNetwork.connected ? "Connected" : "Saved network"
        }

        Row {
            width: parent.width
            height: 30
            spacing: 6

            Button {
                id: connectAction
                KeyNavigation.tab: forgetAction
                KeyNavigation.backtab: cancelAction
                onActiveFocusChanged: if (activeFocus) root.selectedActionIndex = 0
                width: (parent.width - 6) / 2
                height: parent.height
                text: actionPage.selectedNetwork && actionPage.selectedNetwork.connected ? "Disconnect" : "Connect"
                onClicked: root.activateAction(0)

                background: Rectangle {
                    radius: 3
                    color: connectAction.hovered || connectAction.activeFocus || (root.actionMode && root.selectedActionIndex === 0)
                        ? root.config.borderColor : "transparent"
                    border.color: root.config.borderColor
                    border.width: 1
                }

                contentItem: Text {
                    renderType: Text.NativeRendering
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    color: root.config.fg
                    font.pointSize: root.config.fontSize(0.85)
                    text: connectAction.text
                }

            }

            Button {
                id: forgetAction
                KeyNavigation.tab: cancelAction
                KeyNavigation.backtab: connectAction
                onActiveFocusChanged: if (activeFocus) root.selectedActionIndex = 1
                width: (parent.width - 6) / 2
                height: parent.height
                text: "Forget"
                onClicked: root.activateAction(1)

                background: Rectangle {
                    radius: 3
                    color: forgetAction.hovered || forgetAction.activeFocus || (root.actionMode && root.selectedActionIndex === 1)
                        ? root.config.borderColor : "transparent"
                    border.color: root.config.borderColor
                    border.width: 1
                }

                contentItem: Text {
                    renderType: Text.NativeRendering
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    color: root.config.urgent
                    font.pointSize: root.config.fontSize(0.85)
                    text: forgetAction.text
                }

            }

        }

        Button {
            id: cancelAction
            KeyNavigation.tab: connectAction
            KeyNavigation.backtab: forgetAction
            onActiveFocusChanged: if (activeFocus) root.selectedActionIndex = 2
            width: parent.width
            height: 30
            text: "Cancel"
            onClicked: root.activateAction(2)

            background: Rectangle {
                radius: 3
                color: cancelAction.hovered || cancelAction.activeFocus || (root.actionMode && root.selectedActionIndex === 2)
                    ? root.config.borderColor : "transparent"
                border.color: root.config.borderColor
                border.width: 1
            }

            contentItem: Text {
                renderType: Text.NativeRendering
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                color: root.config.fg
                font.pointSize: root.config.fontSize(0.85)
                text: cancelAction.text
            }

        }

    }

    Column {
        width: parent.width
        spacing: 8
        visible: root.passwordMode

        Text {
            renderType: Text.NativeRendering
            width: parent.width
            color: root.config.fg
            font.pointSize: root.config.fontSize(0.92)
            font.weight: Font.DemiBold
            elide: Text.ElideRight
            text: root.selectedSsid
        }

        Text {
            renderType: Text.NativeRendering
            color: root.config.muted
            font.pointSize: root.config.fontSize(0.77)
            text: "Enter network password"
        }

        TextField {
            renderType: Text.NativeRendering
            id: wifiPassword
            KeyNavigation.tab: cancelPassword
            KeyNavigation.backtab: connectButton

            width: parent.width
            height: 32
            focus: root.passwordMode
            onVisibleChanged: {
                if (visible)
                    Qt.callLater(() => {
                    return forceActiveFocus();
                });

            }
            echoMode: TextInput.Password
            passwordCharacter: "•"
            placeholderText: "Password"
            color: root.config.fg
            placeholderTextColor: root.config.muted
            selectionColor: root.config.accent
            selectedTextColor: root.config.fg
            font.pointSize: root.config.fontSize(0.92)
            Keys.onReturnPressed: if (connectButton.enabled) connectButton.clicked()
            Keys.onEnterPressed: if (connectButton.enabled) connectButton.clicked()

            background: Rectangle {
                color: root.config.bg
                border.color: wifiPassword.activeFocus ? root.config.accent : root.config.borderColor
                border.width: 1
                radius: root.config.popupRadius
            }

        }

        Text {
            renderType: Text.NativeRendering
            width: parent.width
            visible: root.errorText !== ""
            color: root.config.urgent
            font.pointSize: root.config.fontSize(0.77)
            text: root.errorText
        }

        Row {
            width: parent.width
            height: 30
            spacing: 6

            Button {
                id: cancelPassword
                KeyNavigation.tab: connectButton
                KeyNavigation.backtab: wifiPassword
                width: (parent.width - 6) / 2
                height: parent.height
                text: "Cancel"
                onClicked: root.resetState()

                background: Rectangle {
                    radius: 3
                    color: cancelPassword.hovered || cancelPassword.activeFocus ? root.config.borderColor : "transparent"
                    border.color: root.config.borderColor
                    border.width: 1
                }

                contentItem: Text {
                    renderType: Text.NativeRendering
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    color: root.config.fg
                    font.pointSize: root.config.fontSize(0.85)
                    text: cancelPassword.text
                }

            }

            Button {
                id: connectButton
                KeyNavigation.tab: wifiPassword
                KeyNavigation.backtab: cancelPassword

                width: (parent.width - 6) / 2
                height: parent.height
                text: "Connect"
                enabled: root.selectedSsid !== "" && wifiPassword.text.length > 0
                onClicked: {
                    var item = root.network.networkForSsid(root.selectedSsid);
                    if (!item)
                        return ;

                    root.errorText = "";
                    item.connectWithPsk(wifiPassword.text);
                    root.passwordMode = false;
                    wifiPassword.text = "";
                    Qt.callLater(() => root.forceActiveFocus());
                }

                background: Rectangle {
                    radius: 3
                    color: connectButton.activeFocus ? root.config.borderColor : (connectButton.enabled ? root.config.accent : root.config.borderColor)
                }

                contentItem: Text {
                    renderType: Text.NativeRendering
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    color: root.config.fg
                    opacity: connectButton.enabled ? 1 : 0.5
                    font.pointSize: root.config.fontSize(0.85)
                    text: connectButton.text
                }

            }

        }

    }

    Text {
        renderType: Text.NativeRendering
        width: parent.width
        visible: root.helpOpen && !root.passwordMode
        color: root.config.muted
        font.pointSize: root.config.fontSize(0.74)
        wrapMode: Text.WordWrap
        text: "↑/↓ or j/k Select · Enter Connect · ?/Esc Help/Close"
    }

}
