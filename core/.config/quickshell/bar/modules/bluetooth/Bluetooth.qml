import "Model.js" as Model
import QtQuick

Item {
    id: root

    required property var config
    required property var barWindow
    required property var popupManager
    required property var bluetoothService
    required property var uiService
    readonly property var adapter: bluetoothService.adapter
    readonly property int connectedCount: Model.rows(bluetoothService.devices).filter(row => row.connected).length
    // Keep selection when the disposable popup is closed and recreated.
    property string selectedAddress: ""

    width: 24
    height: barWindow.height

    Connections {
        target: root.uiService
        function onBluetoothActionRequested(action) {
            if (action === "close" || root.barWindow.screen !== root.uiService.targetScreen) {
                root.popupManager.closeHost("bluetooth");
                return;
            }
            if (action === "open")
                root.popupManager.openHost("bluetooth", bluetoothPopupComponent, root, true);
            else if (action === "toggle")
                root.popupManager.toggleHost("bluetooth", bluetoothPopupComponent, root, true);
        }
    }

    Text {
        anchors.centerIn: parent
        color: root.config.fg
        opacity: root.adapter && root.adapter.enabled ? (root.connectedCount > 0 ? 1 : 0.55) : 0.4
        font.family: root.config.iconFontFamily
        font.pointSize: root.config.iconSize
        text: root.adapter && root.adapter.enabled ? "󰂯" : "󰂲"
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: Qt.PointingHandCursor
        onClicked: mouse => {
            if (mouse.button === Qt.LeftButton)
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
