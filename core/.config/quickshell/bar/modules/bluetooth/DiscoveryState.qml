import QtQuick

Item {
    id: root

    required property var bluetoothService
    readonly property var adapter: bluetoothService.adapter
    property bool requested: false

    visible: false
    onAdapterChanged: stop()
    Component.onDestruction: stop()

    function stop() {
        if (requested) {
            requested = false;
            bluetoothService.endDiscovery();
        }
    }

    function toggleDiscovery() {
        if (requested) {
            stop();
        } else if (adapter && adapter.enabled) {
            requested = true;
            bluetoothService.beginDiscovery();
        }
    }

    function handleKey(key, modifiers) {
        if (key === Qt.Key_S && modifiers === Qt.ControlModifier) {
            if (!adapter || !adapter.enabled)
                return false;
            toggleDiscovery();
            return true;
        }
        return false;
    }

    Connections {
        target: root.adapter
        function onEnabledChanged() {
            if (!root.adapter.enabled)
                root.stop();
        }
    }
}
