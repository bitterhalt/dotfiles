import "../bluetooth/Model.js" as BluetoothModel
import QtQuick

// One bar module for Bluetooth and network. Each icon dims on hover and opens
// the combined popup on its own tab. IPC targets `bluetooth` and `network`
// keep working: each opens the same popup on its tab, and toggling the tab
// that is already shown closes it.
Item {
    id: root

    required property var config
    required property var barWindow
    required property var popupManager
    required property var uiService
    required property var networkService
    required property var bluetoothService

    readonly property string hostKey: "connections"
    readonly property var adapter: bluetoothService.adapter
    readonly property int connectedCount: BluetoothModel.rows(bluetoothService.devices).filter(row => row.connected).length
    readonly property bool popupOpen: popupManager.hostRequested && popupManager.activeKey === hostKey
    // Tab shown by the popup; the popup asks for changes via tabRequested.
    property string tab: "network"
    // Keep selection when the disposable popup is closed and recreated.
    property string selectedAddress: ""

    readonly property int cellWidth: 24

    function show(next) {
        tab = next;
        if (!popupOpen)
            popupManager.openHost(hostKey, popupComponent, root, true);
    }

    function toggleTab(next) {
        if (popupOpen && tab === next)
            popupManager.closeHost(hostKey);
        else
            show(next);
    }

    function handleAction(next, action) {
        if (action === "close" || barWindow.screen !== uiService.targetScreen) {
            popupManager.closeHost(hostKey);
            return;
        }
        if (action === "open")
            show(next);
        else if (action === "toggle")
            toggleTab(next);
    }

    // Matches the old separate widgets: two 24 px cells with the bar's 8 px gap.
    width: cellWidth * 2 + root.config.spacingControl
    height: barWindow.height

    Connections {
        target: root.uiService
        function onBluetoothActionRequested(action) {
            root.handleAction("bluetooth", action);
        }
        function onNetworkActionRequested(action) {
            root.handleAction("network", action);
        }
    }

    // Individual icons only: hover dims the icon itself, no shared card.
    Row {
        anchors.centerIn: parent
        spacing: root.config.spacingControl

        // Network: left-click opens its tab.
        Item {
            width: root.cellWidth
            height: root.barWindow.height

            Text {
                anchors.centerIn: parent
                color: networkMouse.containsMouse ? root.config.muted : root.config.fg
                opacity: root.networkService.connectionKind === "disconnected" ? 0.55 : 1
                font.family: root.config.iconFontFamily
                font.pointSize: root.config.iconSize
                text: root.networkService.icon
            }

            MouseArea {
                id: networkMouse

                anchors.fill: parent
                acceptedButtons: Qt.LeftButton
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.toggleTab("network")
            }
        }

        // Bluetooth: left-click opens its tab, right-click toggles the adapter.
        Item {
            width: root.cellWidth
            height: root.barWindow.height

            Text {
                anchors.centerIn: parent
                color: bluetoothMouse.containsMouse ? root.config.muted : root.config.fg
                opacity: root.adapter && root.adapter.enabled ? (root.connectedCount > 0 ? 1 : 0.55) : 0.4
                font.family: root.config.iconFontFamily
                font.pointSize: root.config.iconSize
                text: root.adapter && root.adapter.enabled ? "󰂯" : "󰂲"
            }

            MouseArea {
                id: bluetoothMouse

                anchors.fill: parent
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: mouse => {
                    if (mouse.button === Qt.LeftButton)
                        root.toggleTab("bluetooth");
                    else if (root.adapter)
                        root.adapter.enabled = !root.adapter.enabled;
                }
            }
        }
    }

    Component {
        id: popupComponent

        ConnectionsPopup {
            config: root.config
            popupManager: root.popupManager
            bluetoothService: root.bluetoothService
            networkService: root.networkService
            tab: root.tab
            selectedAddress: root.selectedAddress
            onSelectedAddressChanged: root.selectedAddress = selectedAddress
            onTabRequested: next => root.tab = next
        }
    }
}
