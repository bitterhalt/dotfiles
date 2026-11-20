// Pure report-to-layout helpers for the updates popup.

function packages(report) {
    if (!report || !Array.isArray(report.managers))
        return [];
    const result = [];
    for (const manager of report.managers) {
        if (!manager || !Array.isArray(manager.packages))
            continue;
        for (const pkg of manager.packages)
            result.push(pkg);
    }
    return result;
}

function total(report) {
    return packages(report).length;
}

function hasErrorNotice(report) {
    return !!report && Array.isArray(report.notices) && report.notices.some(notice => notice.level === "error");
}

function headerLabel(report, busy) {
    if (!report)
        return busy ? "Checking for updates…" : "Updates";
    const count = total(report);
    if (count > 0)
        return count + (count === 1 ? " Update Available" : " Updates Available");
    if (hasErrorNotice(report))
        return "Could not check all managers";
    return "System up to date";
}

function rows(report) {
    const result = [];
    if (!report)
        return result;

    if (Array.isArray(report.managers)) {
        for (const manager of report.managers) {
            const managerPackages = manager && Array.isArray(manager.packages) ? manager.packages : [];
            for (const pkg of managerPackages) {
                result.push({
                    kind: "package",
                    name: String(pkg.name || ""),
                    old: pkg.old == null ? "" : String(pkg.old),
                    new: pkg.new == null ? "" : String(pkg.new)
                });
            }
        }
    }

    const notices = Array.isArray(report.notices) ? report.notices : [];
    for (const notice of notices) {
        result.push({
            kind: "notice",
            text: String(notice.text || ""),
            level: notice.level === "error" ? "error" : "note"
        });
    }

    return result;
}

function rowHeight(config, kind) {
    const medium = Number(config && config.textSizeMedium) || 12;
    const small = Number(config && config.textSizeSmall) || 10;
    switch (kind) {
    case "notice":
        return Math.max(22, Math.ceil(small * 2.2));
    default:
        // Package rows stay compact: the list is a dense report, and the
        // popup height math reuses this value for every row.
        return Math.max(20, Math.ceil(medium * 1.8));
    }
}

function listHeight(list, config, spacing) {
    if (!Array.isArray(list) || list.length === 0)
        return 0;
    let height = 0;
    for (const row of list)
        height += rowHeight(config, row.kind);
    return height + Math.max(0, spacing) * (list.length - 1);
}

// Three quarters of the screen, leaving the popup gap above and below.
// A fixed fallback keeps the first frame sized before a screen is known.
function popupMaxHeight(screenHeight, gap) {
    const height = Number(screenHeight) || 0;
    if (!height)
        return 640;
    const margin = Math.max(0, Number(gap) || 0);
    return Math.max(220, Math.min(Math.round(height * 0.75), height - margin * 2));
}

// Width-independent header/footer heights leave this much room for rows.
function listMaxHeight(maxHeight, config, headerHeight, footerHeight) {
    const padding = Number(config && config.panelPadding) || 0;
    const spacing = Number(config && config.spacingControl) || 0;
    return Math.max(24, (Number(maxHeight) || 0) - padding * 2 - (Number(headerHeight) || 0) - (Number(footerHeight) || 0) - spacing * 2);
}

function listViewportHeight(list, config, maxListHeight, spacing) {
    const medium = Number(config && config.textSizeMedium) || 12;
    if (!Array.isArray(list) || list.length === 0)
        return Math.max(48, Math.ceil(medium * 4));
    return Math.max(rowHeight(config, list[0].kind), Math.min(listHeight(list, config, spacing), Number(maxListHeight) || 0));
}

// Keep a Flickable inside its bounds after a keyboard scroll.
function clampScroll(target, contentHeight, viewHeight) {
    const travel = Math.max(0, (Number(contentHeight) || 0) - (Number(viewHeight) || 0));
    return Math.max(0, Math.min(Number(target) || 0, travel));
}

// A page keeps one row of context, but always moves at least one row.
function pageStep(viewHeight, rowHeight) {
    const view = Math.max(0, Number(viewHeight) || 0);
    const row = Math.max(1, Number(rowHeight) || 1);
    return Math.max(row, view - row);
}
