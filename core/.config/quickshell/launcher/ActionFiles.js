.pragma library

.import "LauncherActionsSchema.js" as Schema

// One launcher action list per category file; the file name is the category.
function categoryFor(fileName) {
    return fileName.replace(/\.json$/i, "");
}

// Returns the next file map, or throws without touching the caller's map so a
// bad edit keeps the last valid entries for that file.
function load(files, fileName, text) {
    const next = Object.assign({}, files);
    next[fileName] = Schema.parse(text, categoryFor(fileName));
    return next;
}

// Merge loaded category lists in file-name order.
function merge(fileNames, files) {
    const actions = [];
    for (const name of fileNames) {
        const entries = files[name];
        if (entries)
            actions.push(...entries);
    }
    return actions;
}
