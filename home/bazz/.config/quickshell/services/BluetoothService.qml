import QtQuick
import Quickshell.Bluetooth

Item {
    id: root

    visible: false

    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property var devices:
        adapter && adapter.devices ? adapter.devices.values : []
    property int discoveryUsers: 0
    property var discoveryAdapter: null

    onAdapterChanged: updateDiscovery()

    function updateDiscovery(): void {
        if (discoveryAdapter && discoveryAdapter !== adapter)
            discoveryAdapter.discovering = false

        discoveryAdapter = adapter

        if (discoveryAdapter) {
            discoveryAdapter.discovering =
                discoveryAdapter.enabled && discoveryUsers > 0
        }
    }

    function beginDiscovery(): void {
        discoveryUsers += 1
        updateDiscovery()
    }

    function endDiscovery(): void {
        discoveryUsers = Math.max(0, discoveryUsers - 1)
        updateDiscovery()
    }

    function deviceForAddress(address) {
        for (let i = 0; i < devices.length; ++i) {
            const device = devices[i]

            if (device && device.address === address)
                return device
        }

        return null
    }

    function toggleDevice(row): void {
        const device = deviceForAddress(row.address)

        if (!device)
            return

        if (device.connected)
            device.disconnect()
        else if (device.paired)
            device.connect()
        else if (device.pairing)
            device.cancelPair()
        else
            device.pair()
    }

    Connections {
        target: root.adapter
        ignoreUnknownSignals: true

        function onEnabledChanged(): void {
            root.updateDiscovery()
        }
    }
}
