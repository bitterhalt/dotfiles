.pragma library

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
    var strongest = {}

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
        if (!old || row.connected || row.strength > old.strength)
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
