.pragma library

function escapeHtml(value) {
    return String(value)
        .replace(/&/g, "&amp;")
        .replace(/</g, "&lt;")
        .replace(/>/g, "&gt;")
        .replace(/\"/g, "&quot;")
        .replace(/'/g, "&#39;")
}

function isPrivateUse(codePoint) {
    return (codePoint >= 0xE000 && codePoint <= 0xF8FF)
        || (codePoint >= 0xF0000 && codePoint <= 0xFFFFD)
        || (codePoint >= 0x100000 && codePoint <= 0x10FFFD)
}

// Keep regular row text proportional and shape private-use Nerd Font glyphs
// with the icon face. A nonbreaking space preserves visible spacing after icons.
function richTextWithSymbols(text, symbolFont) {
    const value = String(text || "")
    const font = escapeHtml(symbolFont || "")
    let output = ""
    let inSymbols = false

    for (const character of value) {
        const useSymbols = isPrivateUse(character.codePointAt(0))
        if (useSymbols !== inSymbols) {
            output += useSymbols ? `<font face=\"${font}\">` : "</font>&nbsp;"
            inSymbols = useSymbols
        }
        output += escapeHtml(character)
    }

    if (inSymbols)
        output += "</font>"

    return output
}

function outputValue(text, indexMode, inputIndex) {
    return indexMode ? String(inputIndex === undefined ? -1 : inputIndex) : text
}

// Size from the original input, not the filtered matches, to avoid resizing
// while typing. Keep oversized requests within the available screen space.
function visibleRows(lines, minimal, itemCount, availableRows) {
    const requested = Math.max(0, lines)
    const count = minimal ? Math.min(requested, itemCount) : requested
    return Math.min(count, Math.max(0, availableRows))
}
