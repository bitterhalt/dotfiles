import QtQuick
import Quickshell
import Quickshell.Io
import "FileSearch.js" as FileSearch

// File search, MIME detection and safe editor launching; no window ownership.
Item {
    id: root
    visible: false

    required property bool active
    required property string needle
    property var results: []
    property int generation: 0
    property bool pending: false
    readonly property bool busy: search.running || debounce.running
    signal resultsReady
    signal fileOpened

    onActiveChanged: refresh()
    onNeedleChanged: refresh()

    function refresh(): void {
        generation += 1;
        pending = active && needle.length >= 2;
        results = [];
        debounce.stop();
        if (search.running) {
            search.signal(15);
            return;
        }
        if (pending)
            debounce.restart();
    }

    function fileItem(path): var {
        const parts = path.split("/");
        return {
            type: "file",
            path: path,
            text: parts[parts.length - 1] || path,
            subtitle: path,
            icon: ""
        };
    }

    function open(path): void {
        if (mimeProcess.running)
            return;
        mimeProcess.path = path;
        mimeProcess.command = ["file", "--mime-type", "-b", "--", path];
        mimeProcess.running = true;
    }

    function launchFile(path, mime): void {
        const home = Quickshell.env("HOME") || "";
        const editor = Quickshell.env("EDITOR") || "nvim";
        const terminal = Quickshell.env("TERMINAL") || "foot";
        const isText = mime.startsWith("text/") || /\.(sh|py|conf)$/.test(path);
        if (!isText) {
            Quickshell.execDetached(["xdg-open", path]);
        } else if (home === "" || !path.startsWith(home + "/")) {
            Quickshell.execDetached([terminal, "-e", "sh", "-c", 'printf "File: %s\\n\\nEnter: edit normally\\ns: sudoedit (administrator)\\nAnything else: cancel\\n> " "$1"; ' + 'IFS= read -r choice || exit 0; ' + 'case "$choice" in ' + '"") exec "$2" "$1" ;; ' + 's|S) exec sudoedit -- "$1" ;; ' + '*) exit 0 ;; esac', "launcher-edit", path, editor]);
        } else {
            Quickshell.execDetached([terminal, "-e", editor, path]);
        }
    }

    Timer {
        id: debounce
        interval: 180
        onTriggered: {
            if (search.running || !root.active || root.needle.length < 2)
                return;
            root.pending = false;
            search.generation = root.generation;
            search.command = FileSearch.command(root.needle, Quickshell.env("HOME") || "");
            search.running = true;
        }
    }

    Process {
        id: search
        property int generation: -1
        stdout: StdioCollector {
            onStreamFinished: {
                if (!root.active || search.generation !== root.generation)
                    return;
                root.results = text.trim().split("\n").filter(path => path.length > 0).map(path => root.fileItem(path));
                root.resultsReady();
            }
        }
        stderr: StdioCollector {}
        onExited: {
            if (root.pending && root.active && root.needle.length >= 2)
                debounce.restart();
        }
    }

    Process {
        id: mimeProcess
        property string path: ""
        stdout: StdioCollector {
            onStreamFinished: {
                const mime = text.trim();
                if (mime !== "")
                    root.launchFile(mimeProcess.path, mime);
                root.fileOpened();
            }
        }
    }
}
