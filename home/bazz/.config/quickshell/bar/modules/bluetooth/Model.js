.pragma library

function row(device) {
    return {
        address: String(device.address || ""),
        name: String(device.name || device.deviceName || device.address || "Unknown device"),
        icon: String(device.icon || ""),
        paired: !!device.paired,
        connected: !!device.connected,
        pairing: !!device.pairing,
        batteryAvailable: !!device.batteryAvailable,
        battery: Number(device.battery || 0)
    }
}

function rows(devices) {
    var result = []

    for (var i = 0; i < devices.length; ++i) {
        if (devices[i])
            result.push(row(devices[i]))
    }

    result.sort(function(a, b) {
        if (a.connected !== b.connected)
            return a.connected ? -1 : 1
        if (a.paired !== b.paired)
            return a.paired ? -1 : 1
        return a.name.localeCompare(b.name)
    })

    return result
}
