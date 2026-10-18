import QtQuick
import QtQuick.Window
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Widgets

PanelWindow {
    id: root

    required property var config
    required property var targetScreen

    property bool opened: false
    property string query: ""
    property var entries: []
    property int selectedIndex: -1
    property string selectedText: ""
    property bool previewReady: false
    property string activeImageId: ""
    property string pendingImageId: ""
    property string activeTextId: ""
    property string pendingTextId: ""
    property string previewEntryId: ""

    readonly property int panelWidth: 720
    readonly property int panelHeight: 420
    readonly property int historyWidth: 280
    readonly property int rowHeight: 36
    readonly property string previewPath:
        (Quickshell.env("XDG_RUNTIME_DIR") || "/tmp")
        + "/quickshell/clipboard-preview-"
        + Quickshell.processId + ".img"
    readonly property var filteredEntries: {
        const needle = query.trim().toLowerCase()

        if (needle === "")
            return entries

        return entries.filter(entry =>
            entry.preview.toLowerCase().includes(needle)
            || entry.mime.toLowerCase().includes(needle))
    }
    readonly property var selectedEntry:
        selectedIndex >= 0 && selectedIndex < filteredEntries.length
            ? filteredEntries[selectedIndex]
            : null

    function open(): void {
        query = ""
        entries = []
        selectedIndex = -1
        selectedText = ""
        previewReady = false
        opened = true
        refresh()
        Qt.callLater(() => searchInput.forceActiveFocus())
    }

    function toggle(): void {
        opened ? close() : open()
    }

    function close(): void {
        opened = false
        previewDebounce.stop()
        selectedIndex = -1
        entries = []
        query = ""
        selectedText = ""
        previewReady = false
        pendingImageId = ""
        pendingTextId = ""
        previewEntryId = ""
        if (textPreviewProcess.running)
            textPreviewProcess.signal(15)
        if (imagePreviewProcess.running)
            imagePreviewProcess.signal(15)
        else
            cleanupPreview.running = true
    }

    function refresh(): void {
        if (!listProcess.running)
            listProcess.running = true
    }

    function parseEntries(value): var {
        const result = []

        for (const line of value.split("\n")) {
            const firstTab = line.indexOf("\t")

            if (firstTab < 1)
                continue

            const id = line.slice(0, firstTab)
            const rawPreview = line.slice(firstTab + 1)
            const isImage = /^\[\[ binary data\b/.test(rawPreview)
            const dimensions = rawPreview.match(/\b(\d{2,5}x\d{2,5})\b/)
            const preview = isImage
                ? `Image${dimensions ? ` (${dimensions[1]})` : ""}`
                : rawPreview

            if (!/^\d+$/.test(id))
                continue

            result.push({
                id,
                raw: line,
                mime: isImage ? "image" : "text",
                preview,
                isImage
            })
        }

        return result
    }

    function select(index): void {
        if (!opened || index < 0 || index >= filteredEntries.length)
            return

        const entry = filteredEntries[index]
        selectedIndex = index
        if (previewEntryId === entry.id)
            return

        previewEntryId = entry.id
        selectedText = ""
        previewReady = false

        if (entry.isImage) {
            pendingImageId = entry.id
            pendingTextId = ""
            if (textPreviewProcess.running)
                textPreviewProcess.signal(15)
        } else {
            pendingImageId = ""
            pendingTextId = entry.id

            if (imagePreviewProcess.running)
                imagePreviewProcess.signal(15)
        }

        previewDebounce.restart()
    }

    function startPendingTextPreview(): void {
        if (!opened || previewDebounce.running
                || textPreviewProcess.running || pendingTextId === "")
            return

        const entryId = pendingTextId
        const entry = selectedEntry
        pendingTextId = ""

        if (!entry || entry.id !== entryId || entry.isImage)
            return

        activeTextId = entryId
        textPreviewProcess.command = [
            "sh", "-c",
            // Bound the collected output before it enters QML. Four bytes
            // per character leave room for the 12,000-character preview.
            "printf '%s\\n' \"$1\" | cliphist decode | head -c 48000",
            "clipboard-preview", entry.raw
        ]
        textPreviewProcess.running = true
    }

    function startPendingImagePreview(): void {
        if (!opened || previewDebounce.running
                || imagePreviewProcess.running || pendingImageId === "")
            return

        const entryId = pendingImageId
        const entry = selectedEntry
        pendingImageId = ""

        if (!entry || entry.id !== entryId || !entry.isImage)
            return

        activeImageId = entryId
        imagePreviewProcess.command = [
            "sh", "-lc",
            "umask 077; printf '%s\\n' \"$1\" | cliphist decode > \"$2\"",
            "clipboard-preview", entry.raw, previewPath
        ]
        imagePreviewProcess.running = true
    }

    function copySelected(): void {
        const entry = selectedEntry

        if (!entry)
            return

        copyProcess.command = [
            "sh", "-lc",
            "printf '%s\\n' \"$1\" | cliphist decode | wl-copy",
            "clipboard-copy", entry.raw
        ]
        copyProcess.running = true
        close()
    }

    function deleteSelected(): void {
        const entry = selectedEntry

        if (!entry)
            return

        deleteProcess.entryId = entry.id
        deleteProcess.command = [
            "sh", "-lc",
            "printf '%s\\n' \"$1\" | cliphist delete",
            "clipboard-delete", entry.raw
        ]
        deleteProcess.running = true
    }

    screen: targetScreen
    visible: opened
    color: "transparent"
    exclusiveZone: 0
    focusable: true

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: visible
        ? WlrKeyboardFocus.Exclusive
        : WlrKeyboardFocus.None

    MouseArea {
        anchors.fill: parent
        onClicked: root.close()
    }

    Rectangle {
        id: panel

        width: root.panelWidth
        height: root.panelHeight
        anchors.top: parent.top
        anchors.topMargin: root.config.popupGap
        anchors.horizontalCenter: parent.horizontalCenter

        color: root.config.surface
        border.color: root.config.borderColor
        border.width: 1
        radius: root.config.popupRadius
        clip: true

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        }

        Item {
            id: header

            anchors.top: parent.top
            anchors.left: parent.left
            anchors.topMargin: 1
            anchors.leftMargin: 1
            width: root.historyWidth
            height: 42
            z: 1
            TextInput {
                id: searchInput

                renderType: Text.NativeRendering
                anchors.left: parent.left
                anchors.leftMargin: 18
                anchors.right: parent.right
                anchors.rightMargin: 18
                anchors.verticalCenter: parent.verticalCenter
                height: 40
                verticalAlignment: TextInput.AlignVCenter
                color: root.config.fg
                selectionColor: root.config.accent
                selectedTextColor: root.config.bg
                font.pointSize: root.config.fontSize(1.04)
                focus: true
                clip: true

                onTextChanged: {
                    root.query = text
                    root.selectedIndex = root.filteredEntries.length > 0 ? 0 : -1
                    if (root.selectedIndex >= 0)
                        root.select(root.selectedIndex)
                }

                Keys.onPressed: event => {
                    switch (event.key) {
                    case Qt.Key_Down:
                    case Qt.Key_Tab:
                        root.select(root.selectedIndex + 1)
                        event.accepted = true
                        break
                    case Qt.Key_Up:
                    case Qt.Key_Backtab:
                        root.select(root.selectedIndex - 1)
                        event.accepted = true
                        break
                    case Qt.Key_Return:
                    case Qt.Key_Enter:
                        root.copySelected()
                        event.accepted = true
                        break
                    case Qt.Key_Delete:
                        root.deleteSelected()
                        event.accepted = true
                        break
                    case Qt.Key_Escape:
                        root.close()
                        event.accepted = true
                        break
                    }
                }

                Component.onCompleted: forceActiveFocus()
            }

            Text {
                renderType: Text.NativeRendering
                anchors.left: searchInput.left
                anchors.verticalCenter: searchInput.verticalCenter
                visible: searchInput.text.length === 0
                color: root.config.muted
                font.pointSize: root.config.fontSize(1.0)
                text: "Search clipboard"
            }

        }

        Rectangle {
            anchors.top: header.bottom
            anchors.left: parent.left
            anchors.leftMargin: 1
            width: root.historyWidth
            height: 1
            z: 1
            color: root.config.borderColor
        }

        Row {
            anchors.top: parent.top
            anchors.topMargin: 1
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin: 1
            anchors.rightMargin: 1
            anchors.bottom: footer.top

            Rectangle {
                width: root.historyWidth
                height: parent.height
                color: root.config.bg

                ListView {
                    id: entriesList

                    anchors.fill: parent
                    anchors.margins: 8
                    anchors.topMargin: header.height + 9
                    clip: true
                    spacing: 2
                    model: root.filteredEntries
                    currentIndex: root.selectedIndex

                    delegate: Item {
                        id: entryRow
                        required property var modelData
                        required property int index

                        width: ListView.view.width
                        height: root.rowHeight

                        Rectangle {
                            anchors.fill: parent
                            radius: 5
                            color: entryRow.index === root.selectedIndex
                                || rowMouse.containsMouse
                                ? root.config.borderColor
                                : "transparent"
                        }

                        Text {
                            anchors.left: parent.left
                            anchors.leftMargin: 10
                            anchors.verticalCenter: parent.verticalCenter
                            color: root.config.accent
                            font.family: root.config.iconFontFamily
                            font.pointSize: root.config.iconSize
                            text: entryRow.modelData.isImage
                                ? "󰋩" : "󰉢"
                        }

                        Column {
                            anchors.left: parent.left
                            anchors.leftMargin: 42
                            anchors.right: parent.right
                            anchors.rightMargin: 8
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 2

                            Text {
                                renderType: Text.NativeRendering
                                width: parent.width
                                color: root.config.fg
                                font.pointSize: root.config.fontSize(0.88)
                                elide: Text.ElideRight
                                text: entryRow.modelData.preview || "(empty)"
                            }

                            Text {
                                renderType: Text.NativeRendering
                                width: parent.width
                                color: root.config.muted
                                font.pointSize: root.config.fontSize(0.70)
                                elide: Text.ElideRight
                                text: entryRow.modelData.mime
                            }
                        }

                        MouseArea {
                            id: rowMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onEntered: root.select(entryRow.index)
                            onClicked: root.copySelected()
                        }
                    }
                }
            }

            Rectangle {
                width: 1
                height: parent.height
                color: root.config.borderColor
            }

            Item {
                width: parent.width - root.historyWidth - 1
                height: parent.height

                Image {
                    anchors.fill: parent
                    anchors.margins: 16
                    visible: root.previewReady
                        && root.selectedEntry
                        && root.selectedEntry.isImage
                    source: root.previewReady
                        ? "file://" + root.previewPath
                        : ""
                    fillMode: Image.PreserveAspectFit
                    sourceSize.width: Math.ceil(width * Screen.devicePixelRatio)
                    sourceSize.height: Math.ceil(height * Screen.devicePixelRatio)
                    asynchronous: true
                    cache: false
                }

                Text {
                    renderType: Text.NativeRendering
                    anchors.fill: parent
                    anchors.margins: 18
                    visible: root.selectedEntry
                        && !root.selectedEntry.isImage
                    color: root.config.fg
                    font.family: "monospace"
                    font.pointSize: root.config.fontSize(0.82)
                    wrapMode: Text.WrapAnywhere
                    text: root.selectedText
                    clip: true
                }

                Text {
                    renderType: Text.NativeRendering
                    anchors.centerIn: parent
                    visible: !root.selectedEntry
                    color: root.config.muted
                    font.pointSize: root.config.fontSize(0.9)
                    text: root.entries.length === 0
                        ? "Clipboard history is empty"
                        : "Select an item to preview"
                }
            }
        }

        Item {
            id: footer
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: 32

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
                    renderType: Text.NativeRendering
                    anchors.verticalCenter: parent.verticalCenter
                    color: root.config.muted
                    font.pointSize: root.config.fontSize(0.78)
                    text: "Clipboard History"
                }

                Text {
                    renderType: Text.NativeRendering
                    anchors.verticalCenter: parent.verticalCenter
                    color: root.config.muted
                    font.pointSize: root.config.fontSize(0.72)
                    text: `${root.filteredEntries.length} items`
                }
            }

            Text {
                renderType: Text.NativeRendering
                anchors.right: parent.right
                anchors.rightMargin: 14
                anchors.verticalCenter: parent.verticalCenter
                color: root.config.muted
                font.pointSize: root.config.fontSize(0.78)
                text: "Enter:  Copy   Del:  Delete"
            }
        }

        // Draw the outline above opaque panes so child backgrounds cannot
        // cover the left edge of the clipboard panel.
        Rectangle {
            anchors.fill: parent
            color: "transparent"
            border.color: root.config.borderColor
            border.width: 1
            radius: root.config.popupRadius
            z: 100
        }
    }

    Process {
        id: listProcess
        command: ["cliphist", "list"]

        stdout: StdioCollector {
            onStreamFinished: {
                if (!root.opened)
                    return

                root.entries = text.trim().split("\n")
                    .map(line => {
                        const fields = line.split("\t")
                        if (fields.length < 2
                                || !/^\d+$/.test(fields[0]))
                            return null

                        const preview = fields.slice(1).join("\t")
                        const isImage = /^\[\[ binary data\b/.test(preview)
                        const dimensions = preview.match(/\b(\d{2,5}x\d{2,5})\b/)

                        return {
                            id: fields[0],
                            raw: line,
                            mime: isImage ? "image" : "text",
                            preview: isImage
                                ? `Image${dimensions ? ` (${dimensions[1]})` : ""}`
                                : preview,
                            isImage: isImage
                        }
                    })
                    .filter(entry => entry !== null)

                root.previewEntryId = ""
                root.selectedIndex = root.filteredEntries.length > 0 ? 0 : -1
                if (root.selectedIndex >= 0)
                    root.select(root.selectedIndex)
            }
        }
    }

    Timer {
        id: previewDebounce

        interval: 100
        onTriggered: {
            root.startPendingImagePreview()
            root.startPendingTextPreview()
        }
    }

    Process {
        id: textPreviewProcess
        property string entryId: ""

        stdout: StdioCollector {
            onStreamFinished: {
                if (root.opened && root.selectedEntry
                        && root.selectedEntry.id === root.activeTextId) {
                    root.selectedText = text.slice(0, 12000)
                }
            }
        }

        onExited: {
            root.activeTextId = ""
            if (root.pendingTextId !== "")
                root.startPendingTextPreview()
        }
    }

    Process {
        id: imagePreviewProcess

        onExited: exitCode => {
            if (exitCode === 0 && root.opened && root.selectedEntry
                    && root.selectedEntry.id === root.activeImageId) {
                root.previewReady = true
            }

            root.activeImageId = ""

            if (root.pendingImageId !== "")
                root.startPendingImagePreview()
            else if (!root.opened)
                cleanupPreview.running = true
        }
    }

    Process {
        id: copyProcess
    }

    Process {
        id: deleteProcess
        property string entryId: ""

        onExited: exitCode => {
            if (exitCode === 0 && root.opened) {
                root.entries = root.entries.filter(entry =>
                    entry.id !== deleteProcess.entryId)
                root.selectedIndex = Math.min(
                    root.selectedIndex,
                    root.filteredEntries.length - 1
                )
                if (root.selectedIndex >= 0)
                    root.select(root.selectedIndex)
                else {
                    root.selectedText = ""
                    root.previewReady = false
                }
            }
        }
    }

    Process {
        id: cleanupPreview

        command: ["rm", "-f", root.previewPath]
    }

    Component.onDestruction: {
        if (opened)
            cleanupPreview.running = true
    }

    IpcHandler {
        target: "clipboard"

        function toggle(): void {
            root.toggle()
        }

        function open(): void {
            root.open()
        }

        function close(): void {
            root.close()
        }

        function refresh(): void {
            root.refresh()
        }

        function copySelected(): void {
            root.copySelected()
        }

        function deleteSelected(): void {
            root.deleteSelected()
        }
    }
}
