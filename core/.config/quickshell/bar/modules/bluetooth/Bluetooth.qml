import "Model.js" as Model
import QtQuick

Item {
    id: root

    required property var config
    required property var barWindow
    required property var popupManager
    required property var uiService
    required property var bluetoothService

    readonly property var adapter: bluetoothService.adapter
    readonly property bool hasBluetooth: !!adapter
    readonly property int connectedCount: Model.rows(bluetoothService.devices).filter(row => row.connected).length
    // Keep selection when the disposable popup is closed and recreated.
    property string selectedAddress: ""

    width: hasBluetooth ? 24 : 0
    height: barWindow.height

    // Without an adapter the Bluetooth page no longer exists, so ignore actions.
    function handleAction(action) {
        if (!root.hasBluetooth)
            return;
        if (action === "close" || root.barWindow.screen !== root.uiService.targetScreen) {
            root.popupManager.closeHost("bluetooth");
            return;
        }
        if (action === "open")
            root.popupManager.openHost("bluetooth", bluetoothPopupComponent, root, true);
        else if (action === "toggle")
            root.popupManager.toggleHost("bluetooth", bluetoothPopupComponent, root, true);
    }

    Connections {
        target: root.uiService

        function onBluetoothActionRequested(action) {
            root.handleAction(action);
        }
    }

    Text {
        objectName: "bluetoothIcon"
        visible: root.hasBluetooth
        anchors.centerIn: parent
        color: !root.adapter || !root.adapter.enabled || root.connectedCount === 0 || bluetoothMouse.containsMouse ? root.config.muted : root.config.fg
        font.family: root.config.iconFontFamily
        font.pointSize: root.config.iconSize
        text: root.adapter && root.adapter.enabled ? "󰂯" : "󰂲"
    }

    // Left-click opens the Bluetooth popup, right-click toggles the adapter.
    MouseArea {
        id: bluetoothMouse

        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: mouse => {
            if (mouse.button === Qt.LeftButton && root.hasBluetooth)
                root.popupManager.toggleHost("bluetooth", bluetoothPopupComponent, root, true);
            else if (root.adapter)
                root.adapter.enabled = !root.adapter.enabled;
        }
    }

    Component {
        id: bluetoothPopupComponent

        BluetoothPopup {
            config: root.config
            popupManager: root.popupManager
            bluetoothService: root.bluetoothService
            selectedAddress: root.selectedAddress
            onSelectedAddressChanged: root.selectedAddress = selectedAddress
        }
    }
}
