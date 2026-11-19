.pragma library
.import "Scorer.js" as Scorer

function normalizeHistory(values) {
    if (!Array.isArray(values))
        return []
    const seen = new Set()
    const recent = []
    for (const character of values) {
        if (typeof character !== "string" || character === "" || seen.has(character))
            continue
        seen.add(character)
        recent.push(character)
        if (recent.length === 20)
            break
    }
    return recent
}

function parseHistory(text) {
    try {
        return normalizeHistory(JSON.parse(text))
    } catch (error) {
        return []
    }
}

// Cached separately by the launcher, so typing doesn't rebuild this list.
function browse(entries, history, limit) {
    if (history.length === 0)
        return entries.slice(0, limit)
    const byCharacter = new Map()
    for (const entry of entries) {
        if (!byCharacter.has(entry.emoji))
            byCharacter.set(entry.emoji, entry)
    }
    const result = []
    const seen = new Set()
    for (const character of history) {
        if (!byCharacter.has(character) || seen.has(character))
            continue
        result.push(byCharacter.get(character))
        seen.add(character)
        if (result.length === limit)
            return result
    }
    for (const entry of entries) {
        if (seen.has(entry.emoji))
            continue
        result.push(entry)
        seen.add(entry.emoji)
        if (result.length === limit)
            break
    }
    return result
}

function search(entries, query, limit) {
    const value = query.trim().toLowerCase()
    return entries.map((entry, index) => ({
        entry: entry,
        index: index,
        score: entry.emoji === value ? 11000
            : entry.emoji.includes(value) ? 10000 : Scorer.scoreEmoji(entry.name, value)
    })).filter(item => item.score > 0)
        .sort((a, b) => b.score - a.score || a.index - b.index)
        .slice(0, limit)
        .map(item => item.entry)
}
