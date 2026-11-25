import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "../components"

import "Scorer.js" as Scorer
import "Dmenu.js" as Dmenu
import "ModeIcons.js" as ModeIcons

Item {
    id: root

    visible: false

    required property var config
    required property var targetScreen

    property bool opened: false
    property bool quitOnClose: false
    // Mode order for Ctrl+← / Ctrl+→ cycling.
    readonly property var modes: ["apps", "emoji", "files"]
    property string mode: "apps"
    readonly property bool emojiMode: mode === "emoji"
    readonly property bool fileMode: mode === "files"
    // dmenu mode is entered only through `qs ipc call launcher dmenu`, so it
    // is not part of `modes` and can't be reached by cycling.
    readonly property bool dmenuMode: mode === "dmenu"
    property var dmenuItems: []
    property string dmenuPrompt: ""
    property int dmenuLines: 7
    property bool dmenuMinimalLines: false
    property bool dmenuIndexMode: false
    // Result file awaited by the caller; empty when no request is pending.
    property string dmenuOutPath: ""
    readonly property string dmenuSessionId: Date.now().toString() + "-" + Math.random().toString()

    // App IDs only, newest first.
    property var appHistory: []
    property bool appHistoryReady: false
    readonly property int appHistoryKept: 50
    readonly property string appHistoryPath: (Quickshell.env("HOME") || "") + "/.cache/quickshell-app-history.json"
    // Pinned app IDs in pin order. Stored with the other user data, so pins
    // survive a cache clean.
    property var appPins: []
    property bool appPinsReady: false
    readonly property string appPinsPath: (Quickshell.env("XDG_DATA_HOME") || (Quickshell.env("HOME") || "") + "/.local/share") + "/quickshell-launcher-pins.json"
    readonly property var appPinRanks: {
        const ranks = new Map();
        for (let i = 0; i < appPins.length; ++i)
            ranks.set(appPins[i], i);
        return ranks;
    }

    readonly property var appHistoryRanks: {
        const ranks = new Map();
        for (let i = 0; i < appHistory.length; ++i)
            ranks.set(appHistory[i], i);
        return ranks;
    }

    // Marker icon for custom command results; change here to theme it.
    readonly property string actionIcon: "utilities-terminal"
    readonly property string placeholder: dmenuMode ? (dmenuPrompt !== "" ? dmenuPrompt : "Select") : emojiMode ? "Search emojis" : fileMode ? "Search files" : "Search applications"
    readonly property string modePrefixIcon: ModeIcons.icon(mode)

    property string query: ""
    readonly property string calculatorResult: calculator.result
    property int selectedIndex: 0

    readonly property int maxVisibleRows: 7
    readonly property int rowHeight: 36
    readonly property int panelInset: config.panelPadding
    readonly property int inputHeight: panelInset + rowHeight
    readonly property int contentWidth: 380
    readonly property int contentSpacing: config.panelPadding
    readonly property string fileNeedle: fileMode ? query.trim() : ""

    // "=" prefix hands everything after it to qalc, so units, functions and
    // words work too ("=5 km to miles", "=sqrt(2)", "=1x3").
    readonly property bool calcPrefix: !emojiMode && !fileMode && !dmenuMode && query.trim().startsWith("=")
    readonly property string calcExpression: calcPrefix ? query.trim().slice(1).trim() : query.trim()

    // ":" shows only custom actions; text after it filters that list.
    readonly property bool actionListPrefix: !emojiMode && !fileMode && !dmenuMode && query.trim().startsWith(":")
    readonly property string actionNeedle: actionListPrefix ? query.trim().slice(1).trim().toLowerCase() : ""

    // Plain math without the prefix is still detected automatically.
    readonly property bool calculatorQuery: {
        if (calcPrefix)
            return calcExpression.length > 0;

        const value = query.trim();
        return !emojiMode && !fileMode && !dmenuMode && /[0-9]/.test(value) && (/[+\-*/%^×÷]/.test(value) || /\d\s*[xX]\s*[\d(.]/.test(value)) && /^[0-9\s+\-*/%^().,xX×÷]+$/.test(value);
    }

    readonly property var applications: {
        const seen = new Set();

        return [...DesktopEntries.applications.values].filter(entry => {
            if (!entry || !entry.id || seen.has(entry.id))
                return false;

            seen.add(entry.id);
            return true;
        });
    }

    readonly property var dmenuResults: {
        if (!opened || !dmenuMode)
            return [];

        const toItem = (line, index, score) => ({
                    type: "dmenu",
                    text: line,
                    subtitle: "",
                    icon: "",
                    index: index,
                    score: score
                });

        const value = query.trim().toLowerCase();

        // Keep the caller's order until something is typed.
        if (value === "")
            return dmenuItems.map((line, i) => toItem(line, i, 0));

        return dmenuItems.map((line, i) => toItem(line, i, Scorer.scoreLine(line, value))).filter(item => item.score > 0).sort((a, b) => b.score - a.score || a.index - b.index);
    }

    readonly property var results: {
        if (!opened)
            return [];

        if (pendingAction)
            return [
                {
                    type: "action",
                    text: "Yes, " + pendingAction.label,
                    icon: "dialog-ok",
                    confirmAction: true
                },
                {
                    type: "action",
                    text: "No",
                    icon: "dialog-cancel",
                    confirmAction: false
                }
            ];

        const value = query.trim().toLowerCase();
        let entries = [];

        if (actionListPrefix) {
            const actions = actionConfig.actions.map(action => ({
                        type: "action",
                        entry: action,
                        text: "[action] " + action.label,
                        icon: root.actionIcon,
                        score: actionNeedle === "" ? 0 : Scorer.scoreLine(action.keyword + " " + action.label, actionNeedle)
                    }));
            return actionNeedle === "" ? actions : actions.filter(item => item.score > 0).sort((a, b) => b.score - a.score || a.text.localeCompare(b.text));
        }

        if (dmenuMode) {
            entries = dmenuResults;
        } else if (emojiMode) {
            entries = emojiState.results;
        } else if (calcPrefix) {
            entries = [];
        } else if (fileMode) {
            entries = files.results;
        } else if (value === "") {
            // Pinned apps first (in pin order), then recently used, then A-Z.
            entries = applications.map(entry => ({
                        type: "application",
                        entry: entry,
                        text: entry.name || entry.id,
                        subtitle: entry.genericName || entry.comment || "",
                        icon: entry.icon || "",
                        pinned: appPinRanks.has(entry.id),
                        score: 0
                    })).sort((a, b) => pinRank(a.entry.id) - pinRank(b.entry.id) || applicationRank(a.entry.id) - applicationRank(b.entry.id) || a.text.localeCompare(b.text));
        } else {
            entries = applications.map(entry => ({
                        type: "application",
                        entry: entry,
                        text: entry.name || entry.id,
                        subtitle: entry.genericName || entry.comment || "",
                        icon: entry.icon || "",
                        pinned: appPinRanks.has(entry.id),
                        score: Scorer.scoreApplication(entry, value)
                    })).filter(item => item.score > 0).sort((a, b) => b.score - a.score || pinRank(a.entry.id) - pinRank(b.entry.id) || applicationRank(a.entry.id) - applicationRank(b.entry.id) || a.text.localeCompare(b.text));

            // Custom commands are always marked with an icon so they cannot be
            // confused with a .desktop app of the same name.
            entries = actionConfig.actions.map(action => ({
                        type: "action",
                        entry: action,
                        text: "[action] " + action.label,
                        icon: root.actionIcon,
                        score: Scorer.scoreLine(action.keyword + " " + action.label, value)
                    })).filter(item => item.score > 0).sort((a, b) => b.score - a.score || a.text.localeCompare(b.text)).concat(entries);
        }

        if (!fileMode && !dmenuMode && calculatorResult !== "") {
            entries.unshift({
                type: "calculator",
                text: calculatorResult,
                subtitle: calcExpression,
                icon: "󰃬"
            });
        }

        if (dmenuMode)
            return entries;

        return value === "" ? entries : entries.slice(0, 100);
    }

    onResultsChanged: selectedIndex = Math.max(0, Math.min(selectedIndex, results.length - 1))

    // Normal modes stay fixed; dmenu can choose a row count per request.
    readonly property bool fileSearching: files.busy
    readonly property int dmenuChromeHeight: inputHeight + contentSpacing + panelInset
    readonly property int availableDmenuRows: targetScreen ? Math.max(0, Math.floor((targetScreen.height - config.popupGap * 2 - dmenuChromeHeight) / rowHeight)) : maxVisibleRows
    readonly property int visibleRows: dmenuMode ? Dmenu.visibleRows(dmenuLines, dmenuMinimalLines, dmenuItems.length, availableDmenuRows) : maxVisibleRows

    readonly property int cardHeight: dmenuChromeHeight + visibleRows * rowHeight

    function close(): void {
        finalizeClose();
    }

    function finalizeClose(): void {
        // Closing without a pick (Esc, toggle, ...) must still release the
        // process waiting on the FIFO.
        cancelDmenu();
        opened = false;
        reset();

        if (quitOnClose)
            Qt.quit();
    }

    LauncherActions {
        id: actionConfig
    }

    // Confirmation for a pending command action; null outside the confirmation step.
    property var pendingAction: null

    function reset(): void {
        mode = "apps";
        query = "";
        selectedIndex = 0;
        pendingAction = null;
        searchInput.text = "";
    }

    function openApplications(): void {
        cancelDmenu();
        reset();
        opened = true;

        Qt.callLater(() => searchInput.forceActiveFocus());
    }

    function toggleApplications(): void {
        opened ? close() : openApplications();
    }

    function toggleMode(name): void {
        if (!modes.concat(["calculator"]).includes(name))
            return;
        const currentMode = calcPrefix || calculatorQuery ? "calculator" : mode;
        if (opened && currentMode === name) {
            close();
            return;
        }
        // Cancel any pending dmenu request before replacing its UI.
        cancelDmenu();
        reset();
        opened = true;
        setMode(name === "calculator" ? "apps" : name);
        if (name === "calculator") {
            searchInput.text = "=";
            searchInput.cursorPosition = searchInput.text.length;
        }
        Qt.callLater(() => searchInput.forceActiveFocus());
    }

    // Called from IPC: the items are read from itemsPath, and the result is
    // written atomically to outPath, awaited by launcher/dmenu-runner.
    function requestDmenu(itemsPath, outPath, prompt, lines, minimalLines, indexMode): void {
        // Hide and clear the previous request before loading new choices.
        finalizeClose();
        dmenuOutPath = outPath;
        dmenuPrompt = prompt;
        dmenuLines = Math.max(0, lines);
        dmenuMinimalLines = minimalLines;
        dmenuIndexMode = indexMode;
        dmenuFile.path = "";
        dmenuFile.path = itemsPath;
    }

    function beginDmenu(items): void {
        dmenuItems = items;
        reset();
        mode = "dmenu";
        opened = true;

        Qt.callLater(() => searchInput.forceActiveFocus());
    }

    function writeDmenuOutput(path, value): void {
        Quickshell.execDetached(["sh", "-c", 'umask 077; printf "%s" "$2" > "$1.tmp" && mv -- "$1.tmp" "$1"', "dmenu-output", path, value === null ? "cancel\n" : "ok\n" + value + "\n"]);
    }

    function submitDmenu(value, inputIndex): void {
        if (dmenuOutPath === "")
            return;
        writeDmenuOutput(dmenuOutPath, Dmenu.outputValue(value, dmenuIndexMode, inputIndex));
        dmenuOutPath = "";
        dmenuItems = [];
        dmenuPrompt = "";
        finalizeClose();
    }

    function cancelDmenu(): void {
        if (dmenuOutPath === "")
            return;
        writeDmenuOutput(dmenuOutPath, null);
        dmenuOutPath = "";
        dmenuItems = [];
        dmenuPrompt = "";
    }

    function setMode(id): void {
        if (mode === id || dmenuMode)
            return;
        mode = id;
        selectedIndex = 0;

        searchInput.forceActiveFocus();
    }

    function cycleMode(direction): void {
        if (dmenuMode)
            return;
        const currentIndex = modes.indexOf(mode);
        const nextIndex = (currentIndex + direction + modes.length) % modes.length;
        setMode(modes[nextIndex]);
    }

    function navigateResults(direction): void {
        if (direction > 0)
            selectNext();
        else
            selectPrevious();
    }

    function selectNext(): void {
        if (results.length > 0) {
            selectedIndex = (selectedIndex + 1) % results.length;
            resultList.positionViewAtIndex(selectedIndex, ListView.Contain);
        }
    }

    function selectPrevious(): void {
        if (results.length > 0) {
            selectedIndex = (selectedIndex - 1 + results.length) % results.length;
            resultList.positionViewAtIndex(selectedIndex, ListView.Contain);
        }
    }

    function selectPage(direction): void {
        if (results.length === 0)
            return;
        selectedIndex = Math.max(0, Math.min(results.length - 1, selectedIndex + direction * visibleRows));
        resultList.positionViewAtIndex(selectedIndex, ListView.Contain);
    }

    function activateSelected(): void {
        if (selectedIndex < 0 || selectedIndex >= results.length)
            return;
        const item = results[selectedIndex];

        if (item.type === "dmenu") {
            submitDmenu(item.text, item.index);
        } else if (item.type === "application") {
            item.entry.execute();
            recordApplication(item.entry.id);
            finalizeClose();
        } else if (item.type === "calculator") {
            Quickshell.execDetached(["wl-copy", item.text]);
            finalizeClose();
        } else if (item.type === "file") {
            files.open(item.path);
        } else if (item.type === "action") {
            if (root.pendingAction) {
                if (item.confirmAction)
                    root.config.run(root.pendingAction.command);
                root.pendingAction = null;
                if (item.confirmAction)
                    finalizeClose();
            } else if (item.entry.confirm) {
                root.pendingAction = item.entry;
                selectedIndex = 0;
            } else {
                root.config.run(item.entry.command);
                finalizeClose();
            }
        } else if (item.type === "emoji") {
            Quickshell.execDetached(["wl-copy", item.emoji]);
            emojiState.record(item.emoji);
            finalizeClose();
        }
    }

    function pinRank(id): int {
        const rank = appPinRanks.get(id);
        return rank === undefined ? appPins.length : rank;
    }

    function normalizeAppPins(ids): var {
        const seen = new Set();
        const next = [];
        for (const id of ids) {
            if (typeof id !== "string" || id === "" || seen.has(id))
                continue;
            seen.add(id);
            next.push(id);
        }
        return next;
    }

    function restoreAppPins(value): void {
        let stored = [];
        try {
            const parsed = JSON.parse(value);
            if (Array.isArray(parsed))
                stored = parsed;
        } catch (error) {}

        // Keep pins made before the initial asynchronous load finished.
        const pending = !appPinsReady && appPins.length > 0;
        appPins = normalizeAppPins(appPinsReady ? stored : stored.concat(appPins));
        appPinsReady = true;
        if (pending)
            appPinsFile.setText(JSON.stringify(appPins));
    }

    // Ctrl+P: pin or unpin the selected application. The selection follows the
    // app to its new position in the list.
    function togglePinSelected(): void {
        if (selectedIndex < 0 || selectedIndex >= results.length)
            return;
        const item = results[selectedIndex];
        if (item.type !== "application")
            return;

        const id = item.entry.id;
        appPins = appPinRanks.has(id) ? appPins.filter(pinned => pinned !== id) : appPins.concat([id]);
        if (appPinsReady)
            appPinsFile.setText(JSON.stringify(appPins));

        const index = results.findIndex(result => result.type === "application" && result.entry.id === id);
        if (index >= 0) {
            selectedIndex = index;
            resultList.positionViewAtIndex(index, ListView.Contain);
        }
    }

    function applicationRank(id): int {
        const rank = appHistoryRanks.get(id);
        return rank === undefined ? appHistoryKept : rank;
    }

    function normalizeAppHistory(ids): var {
        const seen = new Set();
        const next = [];
        for (const id of ids) {
            if (typeof id !== "string" || id === "" || seen.has(id))
                continue;
            seen.add(id);
            next.push(id);
            if (next.length === appHistoryKept)
                break;
        }
        return next;
    }

    function restoreAppHistory(value): void {
        let stored = [];
        try {
            const parsed = JSON.parse(value);
            if (Array.isArray(parsed))
                stored = parsed;
        } catch (error) {}

        // Preserve launches made before the initial asynchronous load finishes.
        const pending = !appHistoryReady && appHistory.length > 0;
        appHistory = normalizeAppHistory(appHistoryReady ? stored : appHistory.concat(stored));
        appHistoryReady = true;
        if (pending)
            appHistoryFile.setText(JSON.stringify(appHistory));
    }

    function recordApplication(id): void {
        const installed = new Set(applications.map(entry => entry.id));
        if (!installed.has(id))
            return;
        appHistory = normalizeAppHistory([id].concat(appHistory.filter(previous => installed.has(previous))));
        if (appHistoryReady)
            appHistoryFile.setText(JSON.stringify(appHistory));
    }

    CalculatorState {
        id: calculator
        active: root.opened && root.calculatorQuery
        query: root.query.trim()
        expression: root.calcExpression
        onResultReady: root.selectedIndex = 0
    }

    EmojiState {
        id: emojiState
        active: root.opened && root.emojiMode
        query: root.query
        onEntriesLoaded: root.selectedIndex = 0
    }

    FileSearchState {
        id: files
        active: root.opened && root.fileMode
        needle: root.fileNeedle
        onResultsReady: root.selectedIndex = 0
        onFileOpened: root.finalizeClose()
    }

    PanelWindow {
        id: launcherWindow

        screen: root.targetScreen
        visible: root.opened
        color: "transparent"
        implicitWidth: root.contentWidth
        implicitHeight: root.cardHeight
        exclusiveZone: 0
        focusable: true
        WlrLayershell.namespace: "slim-launcher"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
        onVisibleChanged: {
            if (visible)
                Qt.callLater(() => {
                    return searchInput.forceActiveFocus();
                });
        }

        anchors {
            top: true
            left: true
        }

        margins.top: root.config.popupGap
        margins.left: root.targetScreen ? Math.max(0, Math.round((root.targetScreen.width - width) / 2)) : 0

        PanelSurface {
            id: card

            config: root.config
            anchors.fill: parent
            clip: true

            Rectangle {
                id: searchBackground

                anchors.fill: searchInput
                color: root.config.bg
                radius: 4
                border.width: 1
                border.color: root.config.selectionBackground
            }

            Text {
                id: modePrefix

                objectName: "launcherModePrefix"
                visible: root.modePrefixIcon !== ""
                anchors.left: searchInput.left
                anchors.leftMargin: root.config.panelPadding
                anchors.verticalCenter: searchInput.verticalCenter
                color: root.config.selectionBackground
                font.family: root.config.iconFontFamily
                font.pointSize: root.config.iconSize * 1.10
                renderType: Text.NativeRendering
                text: root.modePrefixIcon
            }

            TextInput {
                id: searchInput
                renderType: Text.NativeRendering

                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.topMargin: root.panelInset
                anchors.leftMargin: root.panelInset
                anchors.rightMargin: root.panelInset
                height: root.inputHeight - root.panelInset
                leftPadding: modePrefix.visible ? root.config.panelPadding + modePrefix.implicitWidth + root.config.spacingControl : root.config.spacingControl
                rightPadding: root.config.spacingControl
                topPadding: root.config.spacingTight
                bottomPadding: root.config.spacingTight
                focus: true
                verticalAlignment: TextInput.AlignVCenter
                color: root.config.fg
                selectionColor: root.config.selectionBackground
                selectedTextColor: root.config.selectionForeground
                font.pointSize: root.config.textSizeNormal
                clip: true
                onTextChanged: {
                    root.query = text;
                    root.selectedIndex = 0;
                    root.pendingAction = null;
                }
                Keys.onPressed: event => {
                    const control = event.modifiers & Qt.ControlModifier;
                    switch (event.key) {
                    case Qt.Key_Left:
                        if (control) {
                            root.cycleMode(-1);
                            event.accepted = true;
                        }
                        break;
                    case Qt.Key_Right:
                        if (control) {
                            root.cycleMode(1);
                            event.accepted = true;
                        }
                        break;
                    case Qt.Key_Down:
                        root.navigateResults(1);
                        event.accepted = true;
                        break;
                    case Qt.Key_Up:
                        root.navigateResults(-1);
                        event.accepted = true;
                        break;
                    case Qt.Key_Tab:
                        root.navigateResults(1);
                        event.accepted = true;
                        break;
                    case Qt.Key_Backtab:
                        root.navigateResults(-1);
                        event.accepted = true;
                        break;
                    case Qt.Key_J:
                        if (control) {
                            root.selectNext();
                            event.accepted = true;
                        }
                        break;
                    case Qt.Key_K:
                        if (control) {
                            root.selectPrevious();
                            event.accepted = true;
                        }
                        break;
                    case Qt.Key_A:
                        if (control) {
                            root.setMode("apps");
                            event.accepted = true;
                        }
                        break;
                    case Qt.Key_E:
                        if (control) {
                            root.setMode("emoji");
                            event.accepted = true;
                        }
                        break;
                    case Qt.Key_S:
                        if (control) {
                            root.setMode("files");
                            event.accepted = true;
                        }
                        break;
                    case Qt.Key_P:
                        if (control) {
                            root.togglePinSelected();
                            event.accepted = true;
                        }
                        break;
                    case Qt.Key_PageDown:
                        root.selectPage(1);
                        event.accepted = true;
                        break;
                    case Qt.Key_PageUp:
                        root.selectPage(-1);
                        event.accepted = true;
                        break;
                    case Qt.Key_Return:
                    case Qt.Key_Enter:
                        // Shift+Enter (or Enter with no result rows) returns typed text.
                        if (root.dmenuMode && ((event.modifiers & Qt.ShiftModifier) || root.visibleRows === 0))
                            root.submitDmenu(searchInput.text);
                        else
                            root.activateSelected();
                        event.accepted = true;
                        break;
                    case Qt.Key_Escape:
                        root.close();
                        event.accepted = true;
                        break;
                    }
                }
                Component.onCompleted: forceActiveFocus()
            }

            Text {
                renderType: Text.NativeRendering
                anchors.left: searchInput.left
                anchors.leftMargin: searchInput.leftPadding
                anchors.verticalCenter: searchBackground.verticalCenter
                visible: searchInput.text.length === 0
                color: root.config.muted
                font.pointSize: root.config.textSizeNormal
                text: root.placeholder
            }

            ListView {
                id: resultList

                anchors.top: searchInput.bottom
                anchors.topMargin: root.contentSpacing
                anchors.bottom: parent.bottom
                anchors.bottomMargin: root.panelInset
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.leftMargin: root.panelInset
                anchors.rightMargin: root.panelInset
                clip: true
                interactive: false
                model: root.results
                currentIndex: root.selectedIndex

                delegate: LauncherResultRow {
                    required property var modelData
                    required property int index

                    config: root.config
                    entry: modelData
                    width: ListView.view.width
                    height: root.rowHeight
                    selected: index === root.selectedIndex
                }
            }

            Text {
                renderType: Text.NativeRendering
                anchors.top: searchInput.bottom
                anchors.topMargin: root.config.panelPadding
                anchors.horizontalCenter: parent.horizontalCenter
                visible: root.visibleRows > 0 && root.results.length === 0
                color: root.config.muted
                font.pointSize: root.config.textSizeMedium
                text: root.dmenuMode ? "No matches" : root.calcPrefix ? (root.calcExpression === "" ? "Type an expression" : calculator.busy ? "Calculating…" : "Can't evaluate expression") : root.emojiMode ? "No emoji found" : root.fileMode && root.fileNeedle.length < 2 ? "Type at least two characters to search files" : root.fileMode && root.fileSearching ? "Searching…" : root.fileMode ? "No files found" : "No applications found"
            }
        }
    }

    FileView {
        id: appHistoryFile

        path: root.appHistoryPath
        atomicWrites: true
        printErrors: false
        onLoaded: root.restoreAppHistory(text())
        onLoadFailed: {
            root.appHistoryReady = true;
            if (root.appHistory.length > 0)
                setText(JSON.stringify(root.appHistory));
        }
    }

    FileView {
        id: appPinsFile

        path: root.appPinsPath
        atomicWrites: true
        printErrors: false
        onLoaded: root.restoreAppPins(text())
        onLoadFailed: {
            root.appPinsReady = true;
            if (root.appPins.length > 0)
                setText(JSON.stringify(root.appPins));
        }
    }

    FileView {
        id: dmenuFile

        printErrors: false
        onLoaded: {
            // Ignore a late load for a request that was already cancelled.
            if (root.dmenuOutPath === "")
                return;
            const content = text();
            const lines = content === "" ? [] : content.split("\n");
            // A final newline terminates the last choice, not an extra choice.
            if (content.endsWith("\n"))
                lines.pop();
            root.beginDmenu(lines);
        }
        onLoadFailed: root.close()
    }

    IpcHandler {
        target: "launcher"

        function apps(): void {
            root.toggleMode("apps");
        }
        function search(): void {
            root.toggleMode("files");
        }
        function emoji(): void {
            root.toggleMode("emoji");
        }
        function files(): void {
            root.toggleMode("files");
        }
        function calculator(): void {
            root.toggleMode("calculator");
        }

        function toggle(): void {
            root.toggleApplications();
        }

        function open(): void {
            root.openApplications();
        }

        function close(): void {
            root.close();
        }

        function dmenuSession(): string {
            return root.dmenuSessionId;
        }

        // Used by launcher/dmenu-runner.
        function dmenu(itemsPath: string, outPath: string, prompt: string, lines: int, minimalLines: bool, indexMode: bool): void {
            root.requestDmenu(itemsPath, outPath, prompt, lines, minimalLines, indexMode);
        }
    }
}
