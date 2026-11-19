.pragma library

// Low urgency still gets a toast; only DND and notification updates suppress it.
function shouldShow(notification, dnd) {
    return !!notification && !dnd && !notification.lastGeneration
}

// Keep outgoing cards in their stack slots until their exit finishes.
function retainForExit(active, rendered, maxRetiring = 3) {
    let retiring = 0
    const kept = rendered.filter(item => {
        if (active.indexOf(item) !== -1)
            return true
        return retiring++ < maxRetiring
    })
    return active.filter(item => kept.indexOf(item) === -1).concat(kept)
}
