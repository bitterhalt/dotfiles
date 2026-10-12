.pragma library

function tokenize(text) {
    return String(text || "")
        .toLowerCase()
        .trim()
        .split(/[\s\-_]+/)
        .filter(word => word.length > 0)
}

function wordBoundaryMatch(text, query) {
    const words = tokenize(text)
    const queryWords = tokenize(query)

    if (queryWords.length === 0 || queryWords.length > words.length)
        return false

    for (let i = 0; i <= words.length - queryWords.length; ++i) {
        let matches = true

        for (let j = 0; j < queryWords.length; ++j) {
            if (!words[i + j].startsWith(queryWords[j])) {
                matches = false
                break
            }
        }

        if (matches)
            return true
    }

    return false
}

function levenshteinDistance(left, right) {
    const previous = new Array(right.length + 1)
    const current = new Array(right.length + 1)

    for (let j = 0; j <= right.length; ++j)
        previous[j] = j

    for (let i = 1; i <= left.length; ++i) {
        current[0] = i

        for (let j = 1; j <= right.length; ++j) {
            const cost = left[i - 1] === right[j - 1] ? 0 : 1
            current[j] = Math.min(
                previous[j] + 1,
                current[j - 1] + 1,
                previous[j - 1] + cost
            )
        }

        for (let j = 0; j <= right.length; ++j)
            previous[j] = current[j]
    }

    return previous[right.length]
}

function fuzzyScore(text, query) {
    if (query.length < 3)
        return 0

    const maxDistance = query.length === 3
        ? 1
        : query.length <= 6 ? 2 : 3
    let best = 0

    for (const candidate of [text].concat(tokenize(text))) {
        if (Math.abs(candidate.length - query.length) > maxDistance)
            continue

        const distance = levenshteinDistance(candidate, query)
        if (distance <= maxDistance) {
            best = Math.max(
                best,
                1 - distance / Math.max(candidate.length, query.length)
            )
        }
    }

    return best
}

function scoreApplication(entry, query) {
    const name = String(entry.name || "").toLowerCase()
    const generic = String(entry.genericName || "").toLowerCase()
    const comment = String(entry.comment || "").toLowerCase()
    const id = String(entry.id || "").toLowerCase()
    const keywords = [...(entry.keywords || [])]
        .join(" ").toLowerCase()

    if (name === query)
        return 10000
    if (name.startsWith(query))
        return 5000
    if (wordBoundaryMatch(name, query))
        return 3000
    if (generic.startsWith(query))
        return 800
    if (name.includes(query))
        return 500
    if (generic.includes(query))
        return 400
    if (id.includes(query))
        return 350
    if (keywords.includes(query))
        return 300
    if (comment.includes(query))
        return 50

    return fuzzyScore(name, query) * 100
}

// Generic single-string scorer (used for binaries in run mode).
function scoreText(text, query) {
    const value = String(text || "").toLowerCase()

    if (value === query)
        return 10000
    if (value.startsWith(query))
        return 5000
    if (wordBoundaryMatch(value, query))
        return 3000
    if (value.includes(query))
        return 500

    return fuzzyScore(value, query) * 100
}

// Emoji names are short and numerous; fuzzy matching creates unrelated hits.
function scoreEmoji(name, query) {
    const value = String(name || "").toLowerCase()

    if (value === query)
        return 10000
    if (value.startsWith(query))
        return 5000
    if (wordBoundaryMatch(value, query))
        return 3000
    if (value.includes(query))
        return 500

    return 0
}
