.pragma library

.import "../services/config/Value.js" as Value

const fields = ["category", "label", "keyword", "command", "confirm"]

// All personal actions live in launcher/actions.json; each entry carries its category.
function parse(text) {
    const document = JSON.parse(text);
    if (!Array.isArray(document))
        throw new Error("Expected a list of launcher actions");

    return document.map((entry, index) => {
        const location = "actions[" + index + "]";
        if (!Value.isObject(entry) || Object.keys(entry).some(key => !fields.includes(key)))
            throw new Error(location + ": invalid action entry");
        if (typeof entry.category !== "string" || entry.category.trim() === "")
            throw new Error(location + ": category is required");
        if (typeof entry.label !== "string" || entry.label.trim() === "")
            throw new Error(location + ": label is required");
        if (typeof entry.keyword !== "string" || entry.keyword.trim() === "")
            throw new Error(location + ": keyword is required");
        if (typeof entry.command !== "string" || entry.command.trim() === "")
            throw new Error(location + ": command must not be empty");

        const confirm = entry.confirm === undefined ? true : entry.confirm;
        if (typeof confirm !== "boolean")
            throw new Error(location + ": confirm must be true or false");

        return {
            label: entry.label,
            keyword: entry.keyword.trim().toLowerCase(),
            command: entry.command,
            confirm: confirm,
            category: entry.category.trim()
        };
    });
}
