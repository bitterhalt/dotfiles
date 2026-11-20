.pragma library

function threshold(value) {
    const number = Number(value)
    return Number.isFinite(number) ? Math.max(0, Math.min(100, Math.round(number))) : 0
}

// Pure state transition: unknown battery values never count as an empty battery.
function evaluate(previous, battery, low, critical, rearm) {
    if (typeof battery !== "number" || !Number.isFinite(battery) || battery < 0 || battery > 1)
        return null
    const percent = Math.round(battery * 100)
    low = threshold(low)
    critical = threshold(critical)
    rearm = Math.max(0, Number(rearm) || 0)
    const state = {
        lowThreshold: low,
        criticalThreshold: critical,
        low: previous && previous.lowThreshold === low ? previous.low : false,
        critical: previous && previous.criticalThreshold === critical ? previous.critical : false
    }
    if (!low || (percent > low && percent >= low + rearm))
        state.low = false
    if (!critical || (percent > critical && percent >= critical + rearm))
        state.critical = false

    let warning = ""
    if (critical > 0 && percent <= critical && !state.critical) {
        warning = "critical"
        state.critical = true
        state.low = true // Don't follow a critical warning with a less urgent one.
    } else if (low > 0 && percent <= low && !state.low && !state.critical) {
        warning = "low"
        state.low = true
    }
    return {state: state, warning: warning, percent: percent}
}
