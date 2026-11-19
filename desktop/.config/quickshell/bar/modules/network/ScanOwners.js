.pragma library

// All per-screen popups share the same adapter. Only the last owner may stop it.
const owners = new Map()

function update(device, owner, requested) {
    if (!device)
        return
    let users = owners.get(device)
    if (!users) {
        if (!requested)
            return
        users = new Set()
        owners.set(device, users)
    }
    if (requested)
        users.add(owner)
    else
        users.delete(owner)
    device.scannerEnabled = users.size > 0
    if (users.size === 0)
        owners.delete(device)
}
