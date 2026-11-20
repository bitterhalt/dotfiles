.pragma library

function iconFromImage(image) {
    image = String(image || "")
    return image.startsWith("image://icon/") ? image.substring(13) : ""
}

function iconSource(icon, resolveIcon) {
    icon = String(icon || "")
    if (!icon)
        return ""
    return icon.startsWith("/") || icon.startsWith("file:") ? icon : resolveIcon(icon, true)
}

// Toasts and history must resolve the same hint the same way: the app icon
// wins, and an image hint only contributes when it is an image://icon/ path.
function appIconSource(notification, resolveIcon) {
    const icon = notification ? (notification.appIcon || iconFromImage(notification.image)) : ""
    return iconSource(icon, resolveIcon)
}

function collapsedCardHeight(config) {
    // One summary line, one reserved body-preview line, compact spacing and
    // padding. Keep this shared with NotificationCenter's size estimate.
    return Math.ceil(Math.max(56, Number(config.fontSize || 14) * 3.2 + 22))
}

function historyWindowHeight(config, count, footerHeight, padding, spacing, maxHeight) {
    const rows = Math.max(0, Number(count) || 0)
    const cardSpacing = Math.max(0, rows - 1) * spacing
    // Reserve room for expanded body/actions without resizing on selection.
    const expandedRoom = rows > 0 ? 120 : 0
    const contentHeight = padding * 2 + 8 + footerHeight
        + rows * collapsedCardHeight(config) + cardSpacing + expandedRoom
    return Math.min(maxHeight, Math.max(Math.min(140, maxHeight), contentHeight))
}

function actionLabel(action) {
    return action.text || (action.identifier === "default" ? "Open" : "Action")
}

function isCloseAction(action) {
    return actionLabel(action).replace(/&/g, "").trim().toLowerCase() === "close"
}

function actionsFor(actions) {
    const used = new Set(["x", "j", "k"])
    const seen = new Set()
    const entries = []
    for (let i = 0; i < (actions || []).length; ++i) {
        const action = actions[i]
        const label = actionLabel(action)
        const normalized = label.replace(/&/g, "").trim().toLowerCase()
        if (isCloseAction(action) || seen.has(normalized))
            continue
        seen.add(normalized)
        const candidates = label.toLowerCase().replace(/[^a-z0-9]/g, "")
            + "abcdefghijklmnopqrstuvwxyz0123456789"
        const key = candidates.split("").find(letter => !used.has(letter)) || ""
        if (key !== "")
            used.add(key)
        entries.push({label: label, key: key, action: action})
    }
    return entries
}

function selectionIndex(rows, id, fallback) {
    const index = rows.findIndex(row => String(row.id) === id)
    return index >= 0 ? index : rows.length ? Math.max(0, Math.min(rows.length - 1, fallback)) : -1
}
