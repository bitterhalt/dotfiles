import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Widgets

import "Scorer.js" as Scorer

Item {
    id: root

    visible: false

    required property var config
    required property var targetScreen

    property bool opened: false
    property bool quitOnClose: false
    property bool forceExpanded: false

    // Modes, switched with Ctrl+<key>.
    readonly property var modes: [
        { id: "apps", label: "Apps", name: "Applications", key: "A" },
        { id: "run", label: "Run", name: "Run binary", key: "B" },
        { id: "emoji", label: "Emoji", name: "Emoji", key: "E" }
    ]
    property string mode: "apps"
    readonly property bool runMode: mode === "run"
    readonly property bool emojiMode: mode === "emoji"
    property var emojiEntries: []

    // Run-mode data
    property var binaries: []
    property var history: []
    readonly property string historyPath:
        (Quickshell.env("HOME") || "") + "/.cache/fuzzel-runhistory"
    readonly property int historyShown: 5
    readonly property int historyKept: 50

    // Nerd font glyphs
    readonly property string iconApps: String.fromCodePoint(0xF003B)
    readonly property string iconRun: String.fromCodePoint(0xF018D)
    readonly property string iconStar: String.fromCodePoint(0xF04CE)

    readonly property string placeholder: runMode
        ? "Search binaries"
        : emojiMode ? "Search emoji"
        : fileMode ? "Search files" : "Search applications"

    property string query: ""
    property string calculatorResult: ""
    property var fileResults: []
    property int selectedIndex: 0

    readonly property int maxVisibleRows: 7
    readonly property int rowHeight: 46
    readonly property int inputHeight: 50
    readonly property int footerHeight: 38
    readonly property int capHeight: 20
    readonly property int contentWidth: 560
    readonly property int maximumCardHeight: inputHeight
        + maxVisibleRows * rowHeight + 9 + footerHeight
    readonly property int expandedTopMargin: Math.max(
        config.popupGap,
        Math.round(((targetScreen ? targetScreen.height : 0)
            - maximumCardHeight) / 2)
            + config.popupGap
    )
    readonly property bool fileMode:
        !runMode && !emojiMode && query.trim().startsWith("/")
    readonly property string fileNeedle:
        fileMode ? query.trim().slice(1).trim() : ""

    // "=" prefix hands everything after it to qalc, so units, functions and
    // words work too ("=5 km to miles", "=sqrt(2)", "=1x3").
    readonly property bool calcPrefix:
        !runMode && !emojiMode && query.trim().startsWith("=")
    readonly property string calcExpression:
        calcPrefix ? query.trim().slice(1).trim() : query.trim()

    // Plain math without the prefix is still detected automatically.
    readonly property bool calculatorQuery: {
        if (calcPrefix)
            return calcExpression.length > 0

        const value = query.trim()
        return !runMode
            && !emojiMode
            && !fileMode
            && /[0-9]/.test(value)
            && (/[+\-*/%^×÷]/.test(value)
                || /\d\s*[xX]\s*[\d(.]/.test(value))
            && /^[0-9\s+\-*/%^().,xX×÷]+$/.test(value)
    }

    readonly property var applications: {
        const seen = new Set()

        return [...DesktopEntries.applications.values]
            .filter(entry => {
                if (!entry || !entry.id || seen.has(entry.id))
                    return false

                seen.add(entry.id)
                return true
            })
    }

    readonly property var binarySet: new Set(binaries)

    // Most recent unique, still-existing binaries (newest first).
    readonly property var recentBinaries: {
        const seen = new Set()
        const out = []

        for (let i = history.length - 1;
                i >= 0 && out.length < historyShown; --i) {
            const name = history[i]

            if (!name || seen.has(name))
                continue

            seen.add(name)

            if (binarySet.size > 0 && !binarySet.has(name))
                continue

            out.push(name)
        }

        return out
    }

    // Run mode: the first word picks the binary, the rest are its arguments
    // ("firefox --private-window"; quotes and backslashes are honored).
    readonly property var runTokens: splitCommand(query)
    readonly property string runName: runTokens.length > 0 ? runTokens[0] : ""
    readonly property var runArgs: runTokens.slice(1)

    readonly property var binaryResults: {
        const value = runName.toLowerCase()
        const recent = new Set(recentBinaries)

        const toItem = (name, score) => ({
            type: "binary",
            text: name,
            subtitle: "",
            icon: "",
            recent: recent.has(name),
            score: score
        })

        if (value === "") {
            const rest = binaries
                .filter(name => !recent.has(name))
                .slice(0, 100)
                .map(name => toItem(name, 0))

            return recentBinaries.map(name => toItem(name, 0)).concat(rest)
        }

        // Filter on the match score first; the recent bonus only reorders.
        return binaries
            .map(name => ({ name: name, base: Scorer.scoreText(name, value) }))
            .filter(entry => entry.base > 0)
            .map(entry => toItem(
                entry.name,
                entry.base + (recent.has(entry.name) ? 200 : 0)
            ))
            .sort((a, b) => b.score - a.score
                || (a.text < b.text ? -1 : 1))
    }

    readonly property var emojiResults: {
        const value = query.trim().toLowerCase()

        return emojiEntries
            .map(entry => ({
                type: "emoji",
                text: entry.name,
                emoji: entry.emoji,
                subtitle: "",
                icon: "",
                score: value === ""
                    ? 0
                    : entry.emoji.includes(value)
                        ? 10000
                        : Scorer.scoreEmoji(entry.name, value)
            }))
            .filter(item => value === "" || item.score > 0)
            .slice(0, 100)
    }

    readonly property var results: {
        const value = query.trim().toLowerCase()
        let entries = []

        if (runMode) {
            entries = binaryResults
        } else if (emojiMode) {
            entries = emojiResults
        } else if (calcPrefix) {
            entries = []
        } else if (fileMode) {
            entries = fileResults
        } else if (value !== "" || forceExpanded) {
            entries = applications
                .map(entry => ({
                    type: "application",
                    entry: entry,
                    text: entry.name || entry.id,
                    subtitle: entry.genericName || entry.comment || "",
                    icon: entry.icon || "",
                    score: Scorer.scoreApplication(entry, value)
                }))
                .filter(item => item.score > 0)
                .sort((a, b) => b.score - a.score
                    || a.text.localeCompare(b.text))

            if (value === "" && forceExpanded) {
                entries = applications
                    .map(entry => ({
                        type: "application",
                        entry: entry,
                        text: entry.name || entry.id,
                        subtitle: entry.genericName || entry.comment || "",
                        icon: entry.icon || "",
                        score: 0
                    }))
                    .sort((a, b) => a.text.localeCompare(b.text))
            }
        }

        if (!runMode && calculatorResult !== "") {
            entries.unshift({
                type: "calculator",
                text: calculatorResult,
                subtitle: calcExpression,
                icon: "󰃬"
            })
        }

        return entries.slice(0, 100)
    }

    // Run mode lists recent binaries even before anything is typed.
    readonly property bool expanded:
        forceExpanded
        || query.trim() !== ""
        || (runMode && results.length > 0)
    readonly property bool fileSearching:
        fileProcess.running || fileSearchDebounce.running
    readonly property int visibleRows:
        expanded
            ? Math.max(1, Math.min(maxVisibleRows, results.length))
            : 0

    readonly property int cardHeight: inputHeight
        + (expanded
            ? visibleRows * rowHeight + 9 + footerHeight
            : 0)


    function close(): void {
        finalizeClose()
    }

    function finalizeClose(): void {
        opened = false
        reset()

        if (quitOnClose)
            Qt.quit()
    }

    function reset(): void {
        mode = "apps"
        forceExpanded = false
        query = ""
        calculatorResult = ""
        fileResults = []
        selectedIndex = 0
        searchInput.text = ""
    }

    function openApplications(): void {
        reset()
        opened = true

        Qt.callLater(() => searchInput.forceActiveFocus())
    }

    function toggleApplications(): void {
        opened ? close() : openApplications()
    }

    function setMode(id): void {
        if (mode === id)
            return

        mode = id
        forceExpanded = id === "emoji"
        selectedIndex = 0
        calculatorResult = ""
        updateCalculator()
        updateFileSearch()

        if (runMode) {
            loadBinaries()
            historyFile.reload()
        }

        if (emojiMode && emojiEntries.length === 0)
            emojiFile.reload()

        searchInput.forceActiveFocus()
    }

    function cycleMode(direction): void {
        const currentIndex = modes.findIndex(item => item.id === mode)
        const nextIndex = (currentIndex + direction + modes.length)
            % modes.length
        setMode(modes[nextIndex].id)
    }

    function navigateResults(direction): void {
        if (!expanded) {
            forceExpanded = true
            selectedIndex = results.length > 0 ? 0 : -1
            return
        }

        if (direction > 0)
            selectNext()
        else
            selectPrevious()
    }

    function selectNext(): void {
        if (results.length > 0) {
            selectedIndex = (selectedIndex + 1) % results.length
            resultList.positionViewAtIndex(selectedIndex, ListView.Contain)
        }
    }

    function selectPrevious(): void {
        if (results.length > 0) {
            selectedIndex =
                (selectedIndex - 1 + results.length) % results.length
            resultList.positionViewAtIndex(selectedIndex, ListView.Contain)
        }
    }

    function selectPage(direction): void {
        if (results.length === 0)
            return

        selectedIndex = Math.max(
            0,
            Math.min(results.length - 1, selectedIndex + direction * visibleRows)
        )
        resultList.positionViewAtIndex(selectedIndex, ListView.Contain)
    }

    function activateSelected(): void {
        if (selectedIndex < 0 || selectedIndex >= results.length)
            return

        const item = results[selectedIndex]

        if (item.type === "application") {
            item.entry.execute()
            finalizeClose()
        } else if (item.type === "calculator") {
            Quickshell.execDetached(["wl-copy", item.text])
            finalizeClose()
        } else if (item.type === "file") {
            openFile(item.path)
        } else if (item.type === "binary") {
            recordRun(item.text)
            Quickshell.execDetached([item.text, ...runArgs])
            finalizeClose()
        } else if (item.type === "emoji") {
            Quickshell.execDetached(["wl-copy", item.emoji])
            finalizeClose()
        }
    }

    // Shell-like word splitting: whitespace separates words, '...' and "..."
    // group them, and a backslash escapes the next character.
    function splitCommand(text): var {
        const tokens = []
        let current = ""
        let quote = ""
        let started = false
        let escaped = false

        for (const ch of String(text || "")) {
            if (escaped) {
                current += ch
                escaped = false
            } else if (ch === "\\" && quote !== "'") {
                escaped = true
                started = true
            } else if (quote !== "") {
                if (ch === quote)
                    quote = ""
                else
                    current += ch
            } else if (ch === "\"" || ch === "'") {
                quote = ch
                started = true
            } else if (/\s/.test(ch)) {
                if (started) {
                    tokens.push(current)
                    current = ""
                    started = false
                }
            } else {
                current += ch
                started = true
            }
        }

        if (started)
            tokens.push(current)

        return tokens
    }

    // Collect every executable on $PATH (replaces `find` in menu_run).
    function loadBinaries(): void {
        if (binaries.length > 0 || binaryProcess.running)
            return

        const dirs = [...new Set(
            (Quickshell.env("PATH") || "")
                .split(":")
                .filter(dir => dir.length > 0)
        )]

        binaryProcess.command = [
            "fd", "-L", "-H", "--no-ignore",
            "--max-depth", "1",
            "-t", "x",
            "-a",
            ".",
            ...dirs
        ]
        binaryProcess.running = true
    }

    // Same history file/format as menu_run: one name per line, newest last.
    function recordRun(name): void {
        const next = history.filter(entry =>
            entry !== name && (binarySet.size === 0 || binarySet.has(entry)))

        next.push(name)
        history = next.slice(-historyKept)
        historyFile.setText(history.join("\n") + "\n")
    }

    // Replaces open-file.sh: detect the mime type, then either edit the file
    // in a terminal (text/config/scripts) or hand it to xdg-open.
    function openFile(path): void {
        if (mimeProcess.running)
            return

        mimeProcess.path = path
        mimeProcess.command = ["file", "--mime-type", "-b", "--", path]
        mimeProcess.running = true
    }

    function launchFile(path, mime): void {
        const home = Quickshell.env("HOME") || ""
        const editor = Quickshell.env("EDITOR") || "nvim"
        const terminal = Quickshell.env("TERMINAL") || "foot"

        const isText = mime.startsWith("text/")
            || /\.(sh|py|conf)$/.test(path)

        if (!isText) {
            Quickshell.execDetached(["xdg-open", path])
        } else if (home !== "" && path.startsWith(home + "/")) {
            Quickshell.execDetached([terminal, "-e", editor, path])
        } else {
            Quickshell.execDetached([terminal, "-e", "sudoedit", path])
        }
    }

    // qalc doesn't treat "x" as multiplication; map it (and ×/÷) to operators.
    function normalizeExpression(expression): string {
        let out = expression.replace(/×/g, "*").replace(/÷/g, "/")

        // Leave hex literals such as 0x1F alone.
        if (!/0[xX][0-9a-fA-F]/.test(out))
            out = out.replace(/(\d|\))\s*[xX]\s*(?=[\d(.])/g, "$1*")

        return out
    }

    function updateCalculator(): void {
        calculatorResult = ""

        if (calculatorQuery)
            calculatorDebounce.restart()
        else
            calculatorDebounce.stop()
    }

    function updateFileSearch(): void {
        fileResults = []
        fileSearchDebounce.stop()

        if (fileProcess.running) {
            fileProcess.signal(15)
            return
        }

        if (fileMode && fileNeedle.length >= 2)
            fileSearchDebounce.restart()
    }

    function fileItem(path): var {
        const parts = path.split("/")
        return {
            type: "file",
            path: path,
            text: parts[parts.length - 1] || path,
            subtitle: path,
            icon: ""
        }
    }

    component KeyCap: Rectangle {
        property string label: ""
        property color edgeColor: "gray"
        property color textColor: "gray"
        property real fontPointSize: 9

        implicitHeight: 20
        implicitWidth: Math.max(implicitHeight, capText.implicitWidth + 12)
        radius: 4
        color: "transparent"
        border.width: 1
        border.color: edgeColor

        Text {
            id: capText

            anchors.centerIn: parent
            color: parent.textColor
            font.pointSize: parent.fontPointSize
            text: parent.label
        }
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
        WlrLayershell.namespace: "launcher"
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

        margins.top: root.expandedTopMargin
        margins.left: root.targetScreen
            ? Math.max(0, Math.round((root.targetScreen.width - width) / 2))
            : 0

        Rectangle {
            id: card

            anchors.fill: parent
            color: root.config.surface
            border.color: root.config.borderColor
            border.width: 1
            radius: root.config.popupRadius
            clip: true

            Behavior on height {
                enabled: root.opened

                NumberAnimation {
                    duration: 100
                    easing.type: Easing.OutCubic
                }
            }

            TextInput {
                id: searchInput

                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                height: root.inputHeight
                leftPadding: 18
                rightPadding: 18
                focus: true
                verticalAlignment: TextInput.AlignVCenter
                color: root.config.fg
                selectionColor: root.config.accent
                selectedTextColor: root.config.bg
                font.pointSize: root.config.fontSize(1.08)
                clip: true
                onTextChanged: {
                    root.query = text;
                    root.selectedIndex = 0;
                    root.updateCalculator();
                    root.updateFileSearch();
                }
                Keys.onPressed: (event) => {
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
                    case Qt.Key_B:
                        if (control) {
                            root.setMode("run");
                            event.accepted = true;
                        }
                        break;
                    case Qt.Key_E:
                        if (control) {
                            root.setMode("emoji");
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
                anchors.left: parent.left
                anchors.leftMargin: 18
                anchors.verticalCenter: searchInput.verticalCenter
                visible: searchInput.text.length === 0
                color: root.config.muted
                font.pointSize: root.config.fontSize(1.08)
                text: root.placeholder
            }

            Rectangle {
                anchors.top: searchInput.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                height: root.expanded ? 1 : 0
                color: root.config.borderColor
            }

            ListView {
                id: resultList

                anchors.top: searchInput.bottom
                anchors.topMargin: 5
                anchors.bottom: footer.top
                anchors.bottomMargin: 4
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.leftMargin: 4
                anchors.rightMargin: 4
                visible: root.expanded
                clip: true
                interactive: contentHeight > height
                model: root.results
                currentIndex: root.selectedIndex

                delegate: Item {
                    id: resultRow

                    required property var modelData
                    required property int index

                    width: ListView.view.width
                    height: root.rowHeight

                    Rectangle {
                        anchors.fill: parent
                        radius: 4
                        color: resultRow.index === root.selectedIndex || rowMouse.containsMouse ? root.config.borderColor : "transparent"
                    }

                    IconImage {
                        id: appIcon

                        anchors.left: parent.left
                        anchors.leftMargin: 12
                        anchors.verticalCenter: parent.verticalCenter
                        implicitSize: 26
                        visible: source.toString() !== ""
                        source: modelData.icon ? Quickshell.iconPath(modelData.icon, true) : ""
                    }

                    Text {
                        anchors.left: parent.left
                        anchors.leftMargin: 12
                        anchors.verticalCenter: parent.verticalCenter
                        visible: modelData.type === "calculator" || modelData.type === "file" || modelData.type === "binary" || modelData.type === "emoji"
                        color: root.config.accent
                        font.family: modelData.type === "emoji" ? root.config.textFontFamily : root.config.iconFontFamily
                        font.pointSize: root.config.iconSize
                        text: modelData.type === "emoji" ? modelData.emoji : modelData.type === "file" ? "󰈔" : modelData.type === "binary" ? (modelData.recent ? root.iconStar : root.iconRun) : "󰃬"
                    }

                    Column {
                        anchors.left: parent.left
                        anchors.leftMargin: 50
                        anchors.right: parent.right
                        anchors.rightMargin: 12
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 1

                        Text {
                            width: parent.width
                            color: root.config.fg
                            font.pointSize: root.config.fontSize(0.96)
                            font.weight: Font.Medium
                            elide: Text.ElideRight
                            text: modelData.text
                        }

                        Text {
                            width: parent.width
                            visible: (modelData.subtitle || "") !== ""
                            color: root.config.muted
                            font.pointSize: root.config.fontSize(0.74)
                            elide: Text.ElideRight
                            text: modelData.subtitle || ""
                        }

                    }

                    MouseArea {
                        id: rowMouse

                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onEntered: root.selectedIndex = resultRow.index
                        onClicked: root.activateSelected()
                    }

                }

            }

            Text {
                anchors.top: searchInput.bottom
                anchors.topMargin: 18
                anchors.horizontalCenter: parent.horizontalCenter
                visible: root.expanded && root.results.length === 0
                color: root.config.muted
                font.pointSize: root.config.fontSize(0.88)
                    text: root.calcPrefix
                        ? (root.calcExpression === "" ? "Type an expression"
                            : calculatorProcess.running || calculatorDebounce.running
                                ? "Calculating…" : "Can't evaluate expression")
                        : root.runMode
                        ? (binaryProcess.running ? "Loading binaries…" : "No binaries found")
                        : root.emojiMode ? "No emoji found"
                        : root.fileMode && root.fileNeedle.length < 2
                            ? "Type at least two characters after /"
                            : root.fileMode && root.fileSearching ? "Searching…"
                            : root.fileMode ? "No files found"
                            : "No applications found"
            }

            // Footer: current mode on the left, action + mode hints on the right.
            Item {
                id: footer

                visible: root.expanded
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                height: root.footerHeight

                // Keep clicks on the footer from reaching the dismiss area.
                MouseArea {
                    anchors.fill: parent
                }

                Rectangle {
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.right: parent.right
                    height: 1
                    color: root.config.borderColor
                }

                Row {
                    anchors.left: parent.left
                    anchors.leftMargin: 14
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 8

                    Text {
                        height: root.capHeight
                        verticalAlignment: Text.AlignVCenter
                        color: root.config.accent
                        font.family: root.config.iconFontFamily
                        font.pointSize: root.config.fontSize(0.9)
                        text: root.emojiMode ? "😀" : root.runMode ? root.iconRun : root.iconApps
                    }

                    Text {
                        height: root.capHeight
                        verticalAlignment: Text.AlignVCenter
                        color: root.config.muted
                        font.pointSize: root.config.fontSize(0.8)
                        text: root.emojiMode ? "Emoji" : root.runMode ? "Run binary" : "Applications"
                    }

                }

                Row {
                    anchors.right: parent.right
                    anchors.rightMargin: 14
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 8

                    Text {
                        visible: root.actionLabel !== ""
                        height: root.capHeight
                        verticalAlignment: Text.AlignVCenter
                        color: root.config.fg
                        font.pointSize: root.config.fontSize(0.8)
                        text: root.actionLabel
                    }


                    Rectangle {
                        visible: root.actionLabel !== ""
                        anchors.verticalCenter: parent.verticalCenter
                        width: 1
                        height: 14
                        color: root.config.borderColor
                    }

                    Repeater {
                        model: root.modes

                        delegate: Item {
                            id: hint

                            required property var modelData
                            readonly property bool active: root.mode === modelData.id

                            anchors.verticalCenter: parent.verticalCenter
                            visible: !active
                            width: visible ? hintRow.width : 0
                            height: root.capHeight

                            Row {
                                id: hintRow

                                spacing: 5

                                Text {
                                    height: root.capHeight
                                    verticalAlignment: Text.AlignVCenter
                                    color: hint.active ? root.config.accent : root.config.muted
                                    font.pointSize: root.config.fontSize(0.8)
                                    text: hint.modelData.label
                                }

                                KeyCap {
                                    label: "Ctrl"
                                    edgeColor: hint.active ? root.config.accent : root.config.borderColor
                                    textColor: root.config.muted
                                    fontPointSize: root.config.fontSize(0.74)
                                }

                                KeyCap {
                                    label: hint.modelData.key
                                    edgeColor: hint.active ? root.config.accent : root.config.borderColor
                                    textColor: root.config.muted
                                    fontPointSize: root.config.fontSize(0.74)
                                }

                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.setMode(hint.modelData.id)
                            }

                        }

                    }

                }

            }

        }

    }

    Timer {
        id: calculatorDebounce
        interval: 120
        onTriggered: {
            if (calculatorProcess.running)
                return

            calculatorProcess.expression = root.query.trim()
            calculatorProcess.command = [
                "qalc", "-t", root.normalizeExpression(root.calcExpression)
            ]
            calculatorProcess.running = true
        }
    }

    Process {
        id: calculatorProcess

        property string expression: ""

        stdout: StdioCollector {
            onStreamFinished: {
                const value = text.trim().split("\n")[0] || ""

                if (calculatorProcess.expression === root.query.trim()) {
                    root.calculatorResult = value
                    root.selectedIndex = 0
                }
            }
        }

        onExited: exitCode => {
            if (exitCode !== 0)
                root.calculatorResult = ""

            if (root.calculatorQuery
                    && calculatorProcess.expression !== root.query.trim()) {
                calculatorDebounce.restart()
            }
        }
    }

    Timer {
        id: fileSearchDebounce
        interval: 180
        onTriggered: {
            if (fileProcess.running || root.fileNeedle.length < 2)
                return

            fileProcess.needle = root.fileNeedle
            fileProcess.command = [
                "fd", "-H", "-t", "f",
                "--max-results", "100",
                "--exclude", "*.png",
                "--exclude", "*.jpg",
                "--exclude", "*.jpeg",
                "--exclude", "*.webp",
                "--exclude", "*.gif",
                "--exclude", "*.bmp",
                "--exclude", "*.svg",
                "--exclude", "*.mp4",
                "--exclude", "*.mkv",
                "--exclude", "*.webm",
                "--exclude", "*.mov",
                "--exclude", "*.avi",
                "--exclude", "*.ttf",
                "--exclude", "*.otf",
                "--exclude", "*.woff",
                "--exclude", "*.woff2",
                "--exclude", "*.so",
                "--exclude", "*.so.*",
                "--exclude", "*.exe",
                "--exclude", "*.dll",
                "--exclude", "*.zip",
                "--exclude", "*.7z",
                "--exclude", "*.tar",
                "--exclude", "*.gz",
                "--",
                fileProcess.needle,
                Quickshell.env("HOME") + "/.config",
                Quickshell.env("HOME") + "/.local/bin",
                "/etc"
            ]
            fileProcess.running = true
        }
    }

    Process {
        id: fileProcess

        property string needle: ""

        stdout: StdioCollector {
            onStreamFinished: {
                if (fileProcess.needle !== root.fileNeedle)
                    return

                root.fileResults = text.trim()
                    .split("\n")
                    .filter(path => path.length > 0)
                    .map(path => root.fileItem(path))
                root.selectedIndex = 0
            }
        }

        stderr: StdioCollector {}

        onExited: {
            if (root.fileMode
                    && root.fileNeedle.length >= 2
                    && fileProcess.needle !== root.fileNeedle) {
                fileSearchDebounce.restart()
            }
        }
    }

    Process {
        id: binaryProcess

        // fd prints an error for PATH entries that don't exist; ignore it.
        stdout: StdioCollector {
            onStreamFinished: {
                const names = text.split("\n")
                    .filter(path => path.length > 0)
                    .map(path => path.slice(path.lastIndexOf("/") + 1))
                    .filter(name => name.length > 0)

                root.binaries = [...new Set(names)].sort()
                root.selectedIndex = 0
            }
        }

        stderr: StdioCollector {}
    }

    Process {
        id: mimeProcess

        property string path: ""

        stdout: StdioCollector {
            onStreamFinished: {
                const mime = text.trim()

                // Empty output means `file` failed (e.g. path vanished).
                if (mime !== "")
                    root.launchFile(mimeProcess.path, mime)

                root.finalizeClose()
            }
        }
    }

    FileView {
        id: historyFile

        path: root.historyPath
        atomicWrites: true
        printErrors: false

        onLoaded: {
            root.history = text()
                .split("\n")
                .filter(line => line.length > 0)
        }
    }

    FileView {
        id: emojiFile

        path: (Quickshell.env("HOME") || "")
            + "/.local/share/emoji/emoji.txt"
        watchChanges: true
        printErrors: false

        onLoaded: {
            root.emojiEntries = text()
                .split("\n")
                .map(line => {
                    const value = line.trim()
                    const separator = value.search(/\s/)

                    if (separator < 1)
                        return null

                    return {
                        emoji: value.slice(0, separator),
                        name: value.slice(separator).trim()
                    }
                })
                .filter(entry => entry !== null)
            root.selectedIndex = 0
        }

        onLoadFailed: root.emojiEntries = []
    }

    IpcHandler {
        target: "launcher"

        function toggle(): void {
            root.toggleApplications()
        }

        function open(): void {
            root.openApplications()
        }

        function close(): void {
            root.close()
        }
    }
}
