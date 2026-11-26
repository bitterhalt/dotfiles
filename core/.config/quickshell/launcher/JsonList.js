.pragma library

// Shared parsing for the launcher's JSON string arrays (history and pins).
function parse(text) {
    try {
        const parsed = JSON.parse(text);
        if (Array.isArray(parsed))
            return parsed;
    } catch (error) {}
    return [];
}

// Keep unique non-empty string IDs, optionally capped.
function normalize(ids, limit) {
    const seen = new Set();
    const next = [];
    for (const id of ids) {
        if (typeof id !== "string" || id === "" || seen.has(id))
            continue;
        seen.add(id);
        next.push(id);
        if (limit > 0 && next.length === limit)
            break;
    }
    return next;
}
