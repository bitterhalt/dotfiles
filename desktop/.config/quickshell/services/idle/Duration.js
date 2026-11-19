.pragma library

function parse(text) {
    const value = String(text).trim().toLowerCase()
    if (value === "0")
        return 0
    if (!/^(?:\d+(?:\.\d+)?\s*[hms]\s*)+$/.test(value))
        return -1
    const pattern = /(\d+(?:\.\d+)?)\s*([hms])/g
    let match
    let seconds = 0
    while ((match = pattern.exec(value)) !== null)
        seconds += Number(match[1]) * ({ h: 3600, m: 60, s: 1 })[match[2]]
    return seconds > 0 && seconds <= 604800 ? Math.ceil(seconds) : -1
}

function format(seconds) {
    if (seconds === 0)
        return "0"
    const parts = []
    for (const unit of [{ name: "h", size: 3600 }, { name: "m", size: 60 }, { name: "s", size: 1 }]) {
        const amount = Math.floor(seconds / unit.size)
        if (amount > 0)
            parts.push(amount + unit.name)
        seconds %= unit.size
    }
    return parts.join(" ")
}

function validate(lock, off, suspend) {
    if ([lock, off, suspend].some(value => !Number.isInteger(value) || value < 0 || value > 604800))
        return "Use durations like 30s, 30m, 2h, or 0 to disable"
    if (lock > 0 && off > 0 && lock > off)
        return "Lock must be no later than monitor-off"
    if (suspend > 0 && ((off > 0 && off > suspend) || (lock > 0 && lock > suspend)))
        return "Suspend must be last"
    return ""
}
