import QtQuick
import Quickshell
import Quickshell.Io
import "Emoji.js" as Emoji

Item {
    id: root
    visible: false

    required property bool active
    required property string query
    property var entries: []
    property bool dataRequested: false
    property var history: []
    property bool historyReady: false
    readonly property var browseEntries: Emoji.browse(entries, history, 100)
    readonly property var results: {
        if (!active)
            return [];
        const value = query.trim().toLowerCase();
        return (value === "" ? browseEntries : Emoji.search(entries, value, 100)).map(entry => ({
                    type: "emoji",
                    text: entry.name,
                    emoji: entry.emoji,
                    subtitle: "",
                    icon: "",
                    score: 0
                }));
    }
    signal entriesLoaded

    onActiveChanged: {
        if (!active)
            return;
        if (!dataRequested)
            dataRequested = true;
        else if (entries.length === 0)
            emojiFile.reload();
    }

    function restoreHistory(value): void {
        const stored = Emoji.parseHistory(value);
        const pending = !historyReady && history.length > 0;
        history = Emoji.normalizeHistory(historyReady ? stored : history.concat(stored));
        historyReady = true;
        if (pending)
            historyFile.setText(JSON.stringify(history));
    }

    function record(character): void {
        history = Emoji.normalizeHistory([character].concat(history));
        if (historyReady)
            historyFile.setText(JSON.stringify(history));
    }

    FileView {
        id: emojiFile
        path: root.dataRequested ? (Quickshell.env("HOME") || "") + "/.config/quickshell/components/emoji/emoji.txt" : ""
        watchChanges: root.dataRequested
        printErrors: false
        onLoaded: {
            root.entries = text().split("\n").map(line => {
                const value = line.trim();
                const separator = value.search(/\s/);
                if (separator < 1)
                    return null;
                return {
                    emoji: value.slice(0, separator),
                    name: value.slice(separator).trim()
                };
            }).filter(entry => entry !== null);
            if (root.active)
                root.entriesLoaded();
        }
        onLoadFailed: root.entries = []
    }

    FileView {
        id: historyFile
        path: (Quickshell.env("XDG_CACHE_HOME") || Quickshell.env("HOME") + "/.cache") + "/quickshell-emoji-history.json"
        atomicWrites: true
        printErrors: false
        onLoaded: root.restoreHistory(text())
        onLoadFailed: {
            root.historyReady = true;
            if (root.history.length > 0)
                setText(JSON.stringify(root.history));
        }
    }
}
