import "../../../components"
import QtQuick

// Standalone Bluetooth popup. The page owns all state and key handling; this
// wrapper only supplies the panel surface and forwards lifecycle signals.
PopoutPanel {
    id: root

    required property var popupManager
    required property var bluetoothService
    property string selectedAddress: ""

    readonly property var page: bluetoothPage

    focus: true
    Component.onCompleted: Qt.callLater(() => root.forceActiveFocus())

    // The page gets the first look at every key.
    Keys.onPressed: event => root.page && root.page.handleKey(event)

    BluetoothPage {
        id: bluetoothPage

        width: root.width - root.padding * 2
        config: root.config
        bluetoothService: root.bluetoothService
        selectedAddress: root.selectedAddress
        onSelectedAddressChanged: root.selectedAddress = selectedAddress
        onCloseRequested: root.popupManager.closeHost("bluetooth")
        onFocusRequested: Qt.callLater(() => {
            if (root)
                root.forceActiveFocus();
        })
    }
}
