import "../../components"
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

    function resetState() {
        network.popupManager.hostFocusable = false;
        passwordMode = false;
        actionMode = false;
        selectedSsid = "";
        errorText = "";
        wifiPassword.text = "";
    }

    function openRow(row) {
        var item = network.networkForSsid(row.ssid);
        if (!item)
            return ;

        errorText = "";
        if (item.connected || item.known) {
            selectedSsid = row.ssid;
            actionMode = true;
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
    Component.onCompleted: {
        if (network.wifiDevice)
            network.wifiDevice.scannerEnabled = Networking.wifiEnabled;

    }
    Component.onDestruction: {
        if (network.wifiDevice)
            network.wifiDevice.scannerEnabled = false;

        resetState();
    }

    Item {
        width: parent.width
        height: 28

        Text {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            color: root.config.fg
            font.pointSize: root.config.fontSize(1.08)
            font.weight: Font.DemiBold
            text: root.passwordMode ? "Connect to Wi-Fi" : (root.actionMode ? "Wi-Fi network" : "Network")
        }

        Row {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: 8
            visible: !root.passwordMode && !root.actionMode && root.network.wifiDevice !== null

            Text {
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
        spacing: 4
        visible: !root.passwordMode

        SectionHeader {
            config: root.config
            visible: root.network.connectionKind !== "disconnected"
            text: "CONNECTED"
        }

        Item {
            width: parent.width
            height: root.network.wiredDevice && root.network.wiredDevice.connected ? 40 : 0
            visible: height > 0

            Text {
                x: 6
                anchors.verticalCenter: parent.verticalCenter
                color: root.config.accent
                font.family: root.config.iconFontFamily
                font.pointSize: root.config.iconSize
                text: "󰈀"
            }

            Column {
                x: 36
                width: parent.width - 42
                anchors.verticalCenter: parent.verticalCenter
                spacing: 0

                Text {
                    color: root.config.fg
                    font.pointSize: root.config.fontSize(0.92)
                    font.weight: Font.DemiBold
                    text: "Ethernet"
                }

                Text {
                    color: root.config.muted
                    font.pointSize: root.config.fontSize(0.77)
                    text: root.network.wiredDevice ? root.network.wiredDevice.name : ""
                }

            }

        }

        Item {
            width: parent.width
            height: root.network.connectedWifi ? 42 : 0
            visible: height > 0

            Rectangle {
                anchors.fill: parent
                radius: 3
                color: connectedWifiMouse.containsMouse ? root.config.borderColor : "transparent"
            }

            Text {
                x: 6
                anchors.verticalCenter: parent.verticalCenter
                color: root.config.accent
                font.family: root.config.iconFontFamily
                font.pointSize: root.config.iconSize
                text: root.network.connectedWifi ? Model.strengthIcon(root.network.connectedWifi.signalStrength) : ""
            }

            Column {
                x: 36
                width: parent.width - 42
                anchors.verticalCenter: parent.verticalCenter
                spacing: 0

                Text {
                    width: parent.width
                    color: root.config.fg
                    font.pointSize: root.config.fontSize(0.92)
                    font.weight: Font.DemiBold
                    elide: Text.ElideRight
                    text: root.network.connectedWifi ? root.network.connectedWifi.name : ""
                }

                Text {
                    color: root.config.muted
                    font.pointSize: root.config.fontSize(0.77)
                    text: "Connected"
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

                    root.selectedSsid = root.network.connectedWifi.name;
                    root.actionMode = true;
                }
            }

        }

        SectionHeader {
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

                width: parent ? parent.width : 0
                config: root.config
                row: modelData
                enabled: !modelData.stateChanging
                onActivated: root.openRow(modelData)
            }

        }

        Text {
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
            width: parent.width
            color: root.config.fg
            font.pointSize: root.config.fontSize(0.92)
            font.weight: Font.DemiBold
            elide: Text.ElideRight
            text: root.selectedSsid
        }

        Text {
            color: root.config.muted
            font.pointSize: root.config.fontSize(0.77)
            text: parent.selectedNetwork && parent.selectedNetwork.connected ? "Connected" : "Saved network"
        }

        Row {
            width: parent.width
            height: 30
            spacing: 6

            Button {
                width: (parent.width - 6) / 2
                height: parent.height
                text: actionPage.selectedNetwork && actionPage.selectedNetwork.connected ? "Disconnect" : "Connect"
                onClicked: {
                    var item = actionPage.selectedNetwork;
                    if (!item)
                        return ;

                    if (item.connected)
                        item.disconnect();
                    else
                        item.connect();
                    root.actionMode = false;
                    root.selectedSsid = "";
                }

                background: Rectangle {
                    radius: 3
                    color: parent.hovered ? root.config.borderColor : "transparent"
                    border.color: root.config.borderColor
                    border.width: 1
                }

                contentItem: Text {
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    color: root.config.fg
                    font.pointSize: root.config.fontSize(0.85)
                    text: parent.text
                }

            }

            Button {
                width: (parent.width - 6) / 2
                height: parent.height
                text: "Forget"
                onClicked: {
                    var item = actionPage.selectedNetwork;
                    if (!item)
                        return ;

                    item.forget();
                    root.actionMode = false;
                    root.selectedSsid = "";
                }

                background: Rectangle {
                    radius: 3
                    color: parent.hovered ? root.config.borderColor : "transparent"
                    border.color: root.config.borderColor
                    border.width: 1
                }

                contentItem: Text {
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    color: root.config.urgent
                    font.pointSize: root.config.fontSize(0.85)
                    text: parent.text
                }

            }

        }

        Button {
            width: parent.width
            height: 30
            text: "Cancel"
            onClicked: {
                root.actionMode = false;
                root.selectedSsid = "";
            }

            background: Rectangle {
                radius: 3
                color: parent.hovered ? root.config.borderColor : "transparent"
                border.color: root.config.borderColor
                border.width: 1
            }

            contentItem: Text {
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                color: root.config.fg
                font.pointSize: root.config.fontSize(0.85)
                text: parent.text
            }

        }

    }

    Column {
        width: parent.width
        spacing: 8
        visible: root.passwordMode

        Text {
            width: parent.width
            color: root.config.fg
            font.pointSize: root.config.fontSize(0.92)
            font.weight: Font.DemiBold
            elide: Text.ElideRight
            text: root.selectedSsid
        }

        Text {
            color: root.config.muted
            font.pointSize: root.config.fontSize(0.77)
            text: "Enter network password"
        }

        TextField {
            id: wifiPassword

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
            Keys.onReturnPressed: connectButton.clicked()
            Keys.onEnterPressed: connectButton.clicked()

            background: Rectangle {
                color: root.config.bg
                border.color: wifiPassword.activeFocus ? root.config.accent : root.config.borderColor
                border.width: 1
                radius: root.config.popupRadius
            }

        }

        Text {
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
                width: (parent.width - 6) / 2
                height: parent.height
                text: "Cancel"
                onClicked: root.resetState()

                background: Rectangle {
                    radius: 3
                    color: parent.hovered ? root.config.borderColor : "transparent"
                    border.color: root.config.borderColor
                    border.width: 1
                }

                contentItem: Text {
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    color: root.config.fg
                    font.pointSize: root.config.fontSize(0.85)
                    text: parent.text
                }

            }

            Button {
                id: connectButton

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
                    root.network.popupManager.hostFocusable = false;
                    root.passwordMode = false;
                    wifiPassword.text = "";
                }

                background: Rectangle {
                    radius: 3
                    color: parent.enabled ? root.config.accent : root.config.borderColor
                }

                contentItem: Text {
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    color: root.config.fg
                    opacity: parent.enabled ? 1 : 0.5
                    font.pointSize: root.config.fontSize(0.85)
                    text: parent.text
                }

            }

        }

    }

}
