import QtQuick
import QtQuick.Window
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "../components"

PanelWindow {
    id: root

    required property var config
    required property var targetScreen

    // PanelWindow already has a `closed` signal, so report the end of our own
    // close sequence under a distinct name.
    signal closeFinished

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
    readonly property int historyWidth: 160
    readonly property int rowHeight: 36
    readonly property string previewPath: (Quickshell.env("XDG_RUNTIME_DIR") || "/tmp") + "/quickshell/clipboard-preview-" + Quickshell.processId + ".img"
    readonly property var filteredEntries: {
        const needle = query.trim().toLowerCase();

        if (needle === "")
            return entries;

        return entries.filter(entry => entry.preview.toLowerCase().includes(needle) || entry.mime.toLowerCase().includes(needle));
    }
    readonly property var selectedEntry: selectedIndex >= 0 && selectedIndex < filteredEntries.length ? filteredEntries[selectedIndex] : null

    PopupMotion {
        id: popupMotion
        duration: 150
        surfaceHeight: root.height
        shown: root.opened
        animationsEnabled: root.config.popupAnimations
        animationType: "fade"
        onClosed: root.finishClose()
    }

    function open(): void {
        query = "";
        entries = [];
        selectedIndex = -1;
        selectedText = "";
        previewReady = false;
        // The panel can be reused when reopened during the close fade, so the
        // visible prompt has to be reset explicitly as well as the query.
        searchInput.text = "";
        opened = true;
        refresh();
        Qt.callLater(() => searchInput.forceActiveFocus());
    }

    function close(): void {
        if (!opened)
            return;
        opened = false;
        previewDebounce.stop();
        if (textPreviewProcess.running)
            textPreviewProcess.signal(15);
        if (imagePreviewProcess.running)
            imagePreviewProcess.signal(15);
    }

    function finishClose(): void {
        if (opened)
            return;
        selectedIndex = -1;
        entries = [];
        query = "";
        selectedText = "";
        previewReady = false;
        pendingImageId = "";
        pendingTextId = "";
        previewEntryId = "";

        // If an image decode is still running, wait for it to exit
        // (its onExited emits closeFinished()). Otherwise we're done now.
        if (imagePreviewProcess.running)
            imagePreviewProcess.signal(15);
        else
            closeFinished();
    }

    function refresh(): void {
        if (!listProcess.running)
            listProcess.running = true;
    }

    function select(index): void {
        if (!opened || index < 0 || index >= filteredEntries.length)
            return;
        const entry = filteredEntries[index];
        selectedIndex = index;
        if (previewEntryId === entry.id)
            return;
        previewEntryId = entry.id;
        selectedText = "";
        previewReady = false;

        if (entry.isImage) {
            pendingImageId = entry.id;
            pendingTextId = "";
            if (textPreviewProcess.running)
                textPreviewProcess.signal(15);
        } else {
            pendingImageId = "";
            pendingTextId = entry.id;

            if (imagePreviewProcess.running)
                imagePreviewProcess.signal(15);
        }

        previewDebounce.restart();
    }

    function startPendingTextPreview(): void {
        if (!opened || previewDebounce.running || textPreviewProcess.running || pendingTextId === "")
            return;
        const entryId = pendingTextId;
        const entry = selectedEntry;
        pendingTextId = "";

        if (!entry || entry.id !== entryId || entry.isImage)
            return;
        activeTextId = entryId;
        textPreviewProcess.command = ["sh", "-c",
            // Bound the collected output before it enters QML. Four bytes
            // per character leave room for the 12,000-character preview.
            "printf '%s\\n' \"$1\" | cliphist decode | head -c 48000", "clipboard-preview", entry.raw];
        textPreviewProcess.running = true;
    }

    function startPendingImagePreview(): void {
        if (!opened || previewDebounce.running || imagePreviewProcess.running || pendingImageId === "")
            return;
        const entryId = pendingImageId;
        const entry = selectedEntry;
        pendingImageId = "";

        if (!entry || entry.id !== entryId || !entry.isImage)
            return;
        activeImageId = entryId;
        imagePreviewProcess.command = ["sh", "-lc", "umask 077; printf '%s\\n' \"$1\" | cliphist decode > \"$2\"", "clipboard-preview", entry.raw, previewPath];
        imagePreviewProcess.running = true;
    }

    function copySelected(): void {
        const entry = selectedEntry;

        if (!entry)
            return;
        // Detached so the copy survives the panel being destroyed.
        Quickshell.execDetached(["sh", "-lc", "printf '%s\\n' \"$1\" | cliphist decode | wl-copy", "clipboard-copy", entry.raw]);
        close();
    }

    function deleteSelected(): void {
        const entry = selectedEntry;

        if (!entry)
            return;
        deleteProcess.entryId = entry.id;
        deleteProcess.command = ["sh", "-lc", "printf '%s\\n' \"$1\" | cliphist delete", "clipboard-delete", entry.raw];
        deleteProcess.running = true;
    }

    screen: targetScreen
    visible: popupMotion.surfaceVisible
    color: "transparent"
    exclusiveZone: 0
    focusable: opened

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: opened ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    MouseArea {
        anchors.fill: parent
        onClicked: root.close()
    }

    Rectangle {
        id: panel
        objectName: "clipboardSurface"

        width: root.panelWidth
        height: root.panelHeight
        anchors.top: parent.top
        anchors.topMargin: root.config.popupGap
        anchors.horizontalCenter: parent.horizontalCenter

        color: root.config.bg
        opacity: popupMotion.contentOpacity
        enabled: root.opened
        transform: Translate {
            y: popupMotion.contentOffset
        }
        radius: root.config.popupRadius
        clip: true

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        }

        // Full-width search header above both the history list and preview.
        Item {
            id: header
            objectName: "clipboardHeader"

            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            height: Math.max(32, searchInput.implicitHeight) + root.config.panelPadding * 2
            z: 1

            Rectangle {
                id: searchFrame
                objectName: "clipboardSearchFrame"
                anchors.fill: parent
                anchors.margins: root.config.panelPadding
                color: root.config.bg
                radius: 4
                border.width: 1
                border.color: root.config.selectionBackground
            }

            TextInput {
                id: searchInput
                objectName: "clipboardSearchInput"

                renderType: Text.NativeRendering
                anchors.left: searchFrame.left
                anchors.leftMargin: root.config.spacingControl
                anchors.right: searchFrame.right
                anchors.rightMargin: root.config.spacingControl
                anchors.verticalCenter: searchFrame.verticalCenter
                height: searchFrame.height
                verticalAlignment: TextInput.AlignVCenter
                color: root.config.fg
                selectionColor: root.config.selectionBackground
                selectedTextColor: root.config.selectionForeground
                font.pointSize: root.config.textSizeNormal
                focus: true
                clip: true

                onTextChanged: {
                    root.query = text;
                    root.selectedIndex = root.filteredEntries.length > 0 ? 0 : -1;
                    if (root.selectedIndex >= 0)
                        root.select(root.selectedIndex);
                }

                Keys.onPressed: event => {
                    if (event.key === Qt.Key_0 && event.modifiers === Qt.ControlModifier) {
                        if (!wipeProcess.running)
                            wipeProcess.running = true;
                        event.accepted = true;
                        return;
                    }

                    switch (event.key) {
                    case Qt.Key_Down:
                    case Qt.Key_Tab:
                        root.select(root.selectedIndex + 1);
                        event.accepted = true;
                        break;
                    case Qt.Key_Up:
                    case Qt.Key_Backtab:
                        root.select(root.selectedIndex - 1);
                        event.accepted = true;
                        break;
                    case Qt.Key_Return:
                    case Qt.Key_Enter:
                        root.copySelected();
                        event.accepted = true;
                        break;
                    case Qt.Key_Delete:
                        root.deleteSelected();
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
                anchors.verticalCenter: searchInput.verticalCenter
                visible: searchInput.text.length === 0
                color: root.config.muted
                font.pointSize: root.config.textSizeNormal
                text: "Search clipboard"
            }
        }

        // Left: compact history rows. Right: preview for the selected entry.
        Row {
            objectName: "clipboardBody"
            anchors.top: header.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin: root.config.panelPadding
            anchors.rightMargin: root.config.panelPadding
            anchors.bottom: footer.top
            anchors.bottomMargin: root.config.spacingControl
            spacing: root.config.spacingControl

            Item {
                width: root.historyWidth
                height: parent.height

                ListView {
                    id: entriesList
                    objectName: "clipboardEntries"

                    anchors.fill: parent
                    clip: true
                    spacing: root.config.spacingTight
                    model: root.filteredEntries
                    currentIndex: root.selectedIndex

                    delegate: ClipboardHistoryRow {
                        required property var modelData
                        required property int index

                        config: root.config
                        entry: modelData
                        selected: index === root.selectedIndex
                        width: ListView.view.width
                        height: root.rowHeight
                    }
                }
            }

            ClipboardPreview {
                config: root.config
                entry: root.selectedEntry
                ready: root.previewReady
                imagePath: root.previewPath
                previewText: root.selectedText
                historyEmpty: root.entries.length === 0
                width: Math.max(0, parent.width - root.historyWidth - parent.spacing)
                height: parent.height
            }
        }

        // Footer with item count and keyboard actions.
        Item {
            id: footer
            objectName: "clipboardFooter"
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: Math.max(footerLabels.implicitHeight, footerHint.implicitHeight) + root.config.panelPadding * 2

            PanelSeparator {
                objectName: "clipboardFooterSeparator"
                config: root.config
                horizontalInset: root.config.panelPadding
                anchors.top: parent.top
            }

            Row {
                id: footerLabels
                anchors.left: parent.left
                anchors.leftMargin: root.config.panelPadding
                anchors.verticalCenter: parent.verticalCenter
                spacing: root.config.spacingControl

                Text {
                    renderType: Text.NativeRendering
                    anchors.verticalCenter: parent.verticalCenter
                    color: root.config.muted
                    font.pointSize: root.config.textSizeSmall
                    text: "Clipboard History"
                }

                Text {
                    renderType: Text.NativeRendering
                    anchors.verticalCenter: parent.verticalCenter
                    color: root.config.muted
                    font.pointSize: root.config.textSizeSmall
                    text: `${root.filteredEntries.length} items`
                }
            }

            Text {
                id: footerHint
                renderType: Text.NativeRendering
                anchors.right: parent.right
                anchors.rightMargin: root.config.panelPadding
                anchors.verticalCenter: parent.verticalCenter
                color: root.config.muted
                font.pointSize: root.config.textSizeSmall
                text: "Enter:  Copy   Del:  Delete"
            }
        }

        // Draw the outline above opaque panes so child backgrounds cannot
        // cover the left edge of the clipboard panel.
        Rectangle {
            anchors.fill: parent
            color: "transparent"
            border.color: root.config.border
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
                    return;
                root.entries = text.trim().split("\n").map(line => {
                    const fields = line.split("\t");
                    if (fields.length < 2 || !/^\d+$/.test(fields[0]))
                        return null;

                    const preview = fields.slice(1).join("\t");
                    const isImage = /^\[\[ binary data\b/.test(preview);
                    const dimensions = preview.match(/\b(\d{2,5}x\d{2,5})\b/);

                    return {
                        id: fields[0],
                        raw: line,
                        mime: isImage ? "image" : "text",
                        preview: isImage ? `Image${dimensions ? ` (${dimensions[1]})` : ""}` : preview,
                        isImage: isImage
                    };
                }).filter(entry => entry !== null);

                root.previewEntryId = "";
                root.selectedIndex = root.filteredEntries.length > 0 ? 0 : -1;
                if (root.selectedIndex >= 0)
                    root.select(root.selectedIndex);
            }
        }
    }

    Timer {
        id: previewDebounce

        interval: 100
        onTriggered: {
            root.startPendingImagePreview();
            root.startPendingTextPreview();
        }
    }

    Process {
        id: textPreviewProcess

        stdout: StdioCollector {
            onStreamFinished: {
                if (root.opened && root.selectedEntry && root.selectedEntry.id === root.activeTextId) {
                    root.selectedText = text.slice(0, 12000);
                }
            }
        }

        onExited: {
            root.activeTextId = "";
            if (root.pendingTextId !== "")
                root.startPendingTextPreview();
        }
    }

    Process {
        id: imagePreviewProcess

        onExited: exitCode => {
            if (exitCode === 0 && root.opened && root.selectedEntry && root.selectedEntry.id === root.activeImageId) {
                root.previewReady = true;
            }

            root.activeImageId = "";

            if (root.pendingImageId !== "")
                root.startPendingImagePreview();
            else if (!root.opened && !popupMotion.closing)
                root.closeFinished();
        }
    }

    Process {
        id: wipeProcess
        command: ["cliphist", "wipe"]

        onExited: exitCode => {
            if (exitCode === 0)
                root.close();
            else
                console.warn("Clipboard history wipe failed (exit code " + exitCode + ")");
        }
    }

    Process {
        id: deleteProcess
        property string entryId: ""

        onExited: exitCode => {
            if (exitCode === 0 && root.opened) {
                root.entries = root.entries.filter(entry => entry.id !== deleteProcess.entryId);
                root.selectedIndex = Math.min(root.selectedIndex, root.filteredEntries.length - 1);
                if (root.selectedIndex >= 0)
                    root.select(root.selectedIndex);
                else {
                    root.selectedText = "";
                    root.previewReady = false;
                }
            }
        }
    }
}
