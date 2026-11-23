.pragma library

.import "../services/config/Value.js" as Value

const pages = ["user-menu1", "user-menu2", "user-menu3", "user-menu4"]
const actions = ["settings", "wallpaper", "lock", "suspend", "updates"]

function parse(text) {
    const document = JSON.parse(text)
    if (!Value.isObject(document) || Object.keys(document).some(key => !pages.includes(key)))
        throw new Error("Expected user-menu1 through user-menu4 lists")
    const result = {}
    for (const page of pages) {
        const entries = document[page] === undefined ? [] : document[page]
        if (!Array.isArray(entries))
            throw new Error(page + " must be a list")
        const shortcuts = new Set()
        result[page] = entries.map((entry, index) => {
            const location = page + "[" + index + "]"
            if (!Value.isObject(entry) || Object.keys(entry).some(key =>
                    !["label", "icon", "shortcut", "command", "action", "page", "confirm"].includes(key)))
                throw new Error(location + ": invalid menu entry")
            if (typeof entry.label !== "string" || entry.label.trim() === "")
                throw new Error(location + ": label is required")
            if (entry.icon !== undefined && typeof entry.icon !== "string")
                throw new Error(location + ": icon must be text")
            const shortcut = entry.shortcut === undefined ? "" : entry.shortcut
            if (typeof shortcut !== "string" || (shortcut !== "" && !/^[a-z0-9]$/i.test(shortcut)))
                throw new Error(location + ": shortcut must be one letter or digit")
            const key = shortcut.toLowerCase()
            if (key && shortcuts.has(key))
                throw new Error(location + ": duplicate shortcut " + key)
            if (key)
                shortcuts.add(key)
            const targets = ["command", "action", "page"].filter(key => entry[key] !== undefined)
            if (targets.length !== 1)
                throw new Error(location + ": choose exactly one command, action, or page")
            if (entry.command !== undefined && (typeof entry.command !== "string" || entry.command.trim() === ""))
                throw new Error(location + ": command must not be empty")
            if (entry.action !== undefined && !actions.includes(entry.action))
                throw new Error(location + ": unknown action")
            if (entry.page !== undefined && !["power"].concat(pages).includes(entry.page))
                throw new Error(location + ": unknown page")
            if (entry.confirm !== undefined && (typeof entry.confirm !== "boolean"
                    || (entry.confirm && entry.command === undefined)))
                throw new Error(location + ": confirmation is supported for commands only")
            return Object.assign({}, entry, {shortcut: key, icon: entry.icon || ""})
        })
    }
    return result
}
