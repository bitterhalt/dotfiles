.pragma library

function shouldScanWifi(wifiEnabled, wiredConnected) {
    return wifiEnabled && !wiredConnected
}

function selectableRows(rows, showNearby) {
    return rows.filter(row => row.connected || showNearby)
}

function actionShortcut(text, connected) {
    const key = String(text || "").toLowerCase()
    if (key === (connected ? "d" : "c"))
        return 0
    if (key === "f")
        return 1
    return -1
}

function strengthIcon(strength) {
    if (strength >= 0.75)
        return "󰤨"
    if (strength >= 0.50)
        return "󰤥"
    if (strength >= 0.25)
        return "󰤢"
    return "󰤟"
}

function rows(networks) {
    var strongest = Object.create(null)

    for (var i = 0; i < networks.length; ++i) {
        var network = networks[i]
        if (!network || !network.name)
            continue

        var row = {
            ssid: String(network.name),
            connected: !!network.connected,
            known: !!network.known,
            stateChanging: !!network.stateChanging,
            strength: Number(network.signalStrength || 0),
            security: network.security
        }

        var old = strongest[row.ssid]
        if (!old || (row.connected && !old.connected)
                || (row.connected === old.connected && row.strength > old.strength))
            strongest[row.ssid] = row
    }

    var result = []
    for (var ssid in strongest)
        result.push(strongest[ssid])

    result.sort(function(a, b) {
        if (a.connected !== b.connected)
            return a.connected ? -1 : 1
        if (a.known !== b.known)
            return a.known ? -1 : 1
        if (a.strength !== b.strength)
            return b.strength - a.strength
        return a.ssid.localeCompare(b.ssid)
    })

    return result
}

function networkForSsid(networks, ssid) {
    var best = null
    for (const network of networks) {
        if (!network || network.name !== ssid)
            continue
        if (!best || (network.connected && !best.connected)
                || (!!network.connected === !!best.connected
                    && network.signalStrength > best.signalStrength))
            best = network
    }
    return best
}
