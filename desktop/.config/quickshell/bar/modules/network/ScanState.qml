import QtQuick
import "ScanOwners.js" as ScanOwners

Item {
    id: root

    required property var wifiDevice
    required property bool allowed
    readonly property bool canScan: !!wifiDevice && allowed
    property bool requested: false
    property bool resultsVisible: false
    property var managedDevice: null

    visible: false
    onWifiDeviceChanged: {
        if (managedDevice && managedDevice !== wifiDevice)
            ScanOwners.update(managedDevice, root, false);
        managedDevice = wifiDevice;
        requested = false;
        resultsVisible = false;
        updateScanner();
    }
    onCanScanChanged: updateScanner()
    Component.onCompleted: updateScanner()
    Component.onDestruction: {
        if (managedDevice)
            ScanOwners.update(managedDevice, root, false);
    }

    function updateScanner() {
        if (!canScan) {
            requested = false;
            resultsVisible = false;
        }
        if (wifiDevice)
            ScanOwners.update(wifiDevice, root, requested && canScan);
    }

    function toggle() {
        if (!canScan)
            return;
        requested = !requested;
        if (requested)
            resultsVisible = true;
        updateScanner();
    }

    function handleKey(key, modifiers) {
        if (key !== Qt.Key_S || modifiers !== Qt.ControlModifier || !canScan)
            return false;
        toggle();
        return true;
    }
}
