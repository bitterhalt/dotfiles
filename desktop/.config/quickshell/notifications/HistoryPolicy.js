.pragma library

function isExcluded(notification, excludedApps) {
    if (!notification)
        return false

    // `notify-send -a nohistory ...` is a convenient per-notification opt-out.
    if (String(notification.appName || "").trim().toLowerCase() === "nohistory")
        return true

    const excluded = new Set((excludedApps || []).map(value => String(value).trim()))
    return excluded.has(String(notification.desktopEntry || ""))
        || excluded.has(String(notification.appName || ""))
}

function visibleNotifications(notifications, excludedApps) {
    return (notifications || []).filter(notification =>
        !notification.transient && !isExcluded(notification, excludedApps))
}
