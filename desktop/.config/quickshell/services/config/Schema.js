.pragma library

.import "Value.js" as Value

// QML-facing name: [JSON group, key, fallback, kind, minimum, maximum].
const fields = {
    fontScale: ["appearance", "fontScale", 1, "number", 0.5, 3],
    iconScale: ["appearance", "iconScale", 1, "number", 0.5, 3],
    iconFontFamily: ["appearance", "iconFontFamily", "Symbols Nerd Font Mono", "string"],
    barHeight: ["bar", "height", 32, "integer", 16, 128],
    showTray: ["bar", "showTray", true, "boolean"],
    clockFormat: ["clock", "format", "HH:mm", "string"],
    clockAlternativeFormat: ["clock", "alternativeFormat", "dddd, d MMMM", "string"],
    maxVolume: ["audio", "maxVolume", 1.1, "number", 0, 2],
    launcherEnabled: ["launcher", "enabled", true, "boolean"],
    popupGap: ["popups", "gap", 16, "integer", 0, 256],
    popupRadius: ["popups", "radius", 4, "integer", 0, 64],
    popupAnimations: ["animations", "enabled", true, "boolean"],
    notificationHistoryLimit: ["notifications", "historyLimit", 100, "integer", 1, 10000],
    notificationHistoryExcludedApps: ["notifications", "historyExcludedApps",
        ["time-noti", "niri", "thunar", "Media-notify", "wl-color-picker"], "strings"],
    bluetoothBatteryWarningPercent: ["bluetooth", "batteryWarningPercent", 20, "integer", 0, 100],
    bluetoothBatteryCriticalPercent: ["bluetooth", "batteryCriticalPercent", 10, "integer", 0, 100],
    bluetoothBatteryRearmMargin: ["bluetooth", "batteryRearmMargin", 5, "integer", 0, 100]
}

function defaults() {
    const values = {}
    for (const name in fields) {
        const value = fields[name][2]
        values[name] = Array.isArray(value) ? value.slice() : value
    }
    return values
}

function valid(value, field) {
    const kind = field[3]
    if (Array.isArray(kind))
        return kind.includes(value)
    if (kind === "strings")
        return Array.isArray(value) && value.every(item => typeof item === "string")
    if (kind === "number" || kind === "integer")
        return typeof value === "number" && Number.isFinite(value)
            && (kind !== "integer" || Number.isInteger(value))
            && value >= field[4] && value <= field[5]
    return typeof value === kind
}

function parse(text) {
    const document = JSON.parse(text)
    if (!Value.isObject(document))
        throw new Error("Expected an object")
    const values = defaults()
    const warnings = new Set()
    const groups = {}
    for (const name in fields) {
        const field = fields[name]
        if (!groups[field[0]])
            groups[field[0]] = new Set()
        groups[field[0]].add(field[1])
    }
    for (const group of Object.keys(document)) {
        if (!Object.prototype.hasOwnProperty.call(groups, group)) {
            warnings.add(group + " (unknown)")
        } else if (Value.isObject(document[group])) {
            for (const key of Object.keys(document[group])) {
                if (!groups[group].has(key))
                    warnings.add(group + "." + key + " (unknown)")
            }
        }
    }
    for (const name in fields) {
        const field = fields[name]
        const section = document[field[0]]
        if (section === undefined)
            continue
        if (!Value.isObject(section)) {
            warnings.add(field[0])
            continue
        }
        if (!Object.prototype.hasOwnProperty.call(section, field[1]))
            continue
        const value = section[field[1]]
        if (valid(value, field))
            values[name] = Array.isArray(value) ? value.slice() : value
        else
            warnings.add(field[0] + "." + field[1])
    }
    // Disabled warnings are independent; otherwise critical must be lower.
    if (values.bluetoothBatteryWarningPercent > 0
            && values.bluetoothBatteryCriticalPercent > values.bluetoothBatteryWarningPercent) {
        values.bluetoothBatteryCriticalPercent = Math.min(10, values.bluetoothBatteryWarningPercent)
        warnings.add("bluetooth.batteryCriticalPercent")
    }
    return {values: values, warnings: [...warnings]}
}
