pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Bluetooth
import "bluetooth/BatteryWarning.js" as BatteryWarning

Item {
    id: root

    visible: false

    required property var config
    property var batteryStates: new Map()
    signal batteryWarning(var device, int percent, bool critical)

    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property var devices:
        adapter && adapter.devices ? adapter.devices.values : []
    property int discoveryUsers: 0
    property var discoveryAdapter: null

    onAdapterChanged: updateDiscovery()

    function checkBattery(device): void {
        if (!device || !device.connected || !device.batteryAvailable)
            return
        const key = device.address || device
        const result = BatteryWarning.evaluate(batteryStates.get(key), device.battery,
            config.bluetoothBatteryWarningPercent, config.bluetoothBatteryCriticalPercent,
            config.bluetoothBatteryRearmMargin)
        if (!result)
            return
        batteryStates.set(key, result.state)
        if (result.warning !== "")
            batteryWarning(device, result.percent, result.warning === "critical")
    }

    function checkBatteries(): void {
        for (const device of devices)
            checkBattery(device)
    }

    Repeater {
        model: root.devices
        delegate: Item {
            id: watcher
            required property var modelData
            visible: false
            Component.onCompleted: batteryCheck.restart()

            // Coalesce connect/availability/percentage signals. This also lets
            // a low-battery warning take priority over the connection toast.
            Timer {
                id: batteryCheck
                interval: 0
                onTriggered: root.checkBattery(watcher.modelData)
            }

            Connections {
                target: watcher.modelData
                function onConnectedChanged() { batteryCheck.restart() }
                function onBatteryAvailableChanged() { batteryCheck.restart() }
                function onBatteryChanged() { batteryCheck.restart() }
            }
        }
    }

    Connections {
        target: root.config
        function onBluetoothBatteryWarningPercentChanged() { Qt.callLater(root.checkBatteries) }
        function onBluetoothBatteryCriticalPercentChanged() { Qt.callLater(root.checkBatteries) }
        function onBluetoothBatteryRearmMarginChanged() { Qt.callLater(root.checkBatteries) }
    }

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

    function toggleTrust(row): void {
        const device = deviceForAddress(row.address)
        if (device && device.paired)
            device.trusted = !device.trusted
    }

    function forgetDevice(row): void {
        const device = deviceForAddress(row.address)
        if (device && device.paired)
            device.forget()
    }

    Connections {
        target: root.adapter
        ignoreUnknownSignals: true

        function onEnabledChanged(): void {
            root.updateDiscovery()
        }
    }
}
