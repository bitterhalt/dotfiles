pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "../components"

PanelWindow {
    id: root

    required property var config
    required property var targetScreen
    required property var controller
    property string scanError: ""
    property string scanNotice: ""
    property bool scanFinished: false
    property string selectedPath: ""
    property bool fixedPrompt: false
    property string promptError: ""
    readonly property var actions: [
        { label: "Set Wallpaper", key: "b", action: "wallpaper", control: false },
        { label: "Pywal", key: "p", action: "pywal", control: false },
        { label: "Pywal Fixed", key: "P", action: "fixed", control: true }
    ]
    readonly property int selectedIndex: {
        if (visibleEntries.count === 0)
            return -1
        for (let i = 0; i < visibleEntries.count; ++i) {
            if (visibleEntries.get(i).path === selectedPath)
                return i
        }
        return 0
    }
    readonly property var selected: selectedIndex >= 0 && selectedIndex < visibleEntries.count
        ? visibleEntries.get(selectedIndex) : null

    signal closeRequested()

    ListModel { id: allEntries }
    ListModel { id: visibleEntries }

    function matches(entry) {
        return entry.name.toLowerCase().includes(search.text.trim().toLowerCase())
    }

    function addEntry(entry) {
        allEntries.append(entry)
        if (matches(entry))
            visibleEntries.append(entry)
    }

    function filterEntries() {
        visibleEntries.clear()
        for (let i = 0; i < allEntries.count; ++i) {
            const entry = allEntries.get(i)
            if (matches(entry))
                visibleEntries.append({path: entry.path, name: entry.name, thumbnail: entry.thumbnail})
        }
        selectedPath = ""
        grid.positionViewAtBeginning()
    }

    function moveSelection(delta) {
        if (visibleEntries.count === 0)
            return
        const index = Math.max(0, Math.min(visibleEntries.count - 1, selectedIndex + delta))
        selectedPath = visibleEntries.get(index).path
        grid.positionViewAtIndex(index, GridView.Contain)
    }

    function applySelection(pywal) {
        if (selected)
            controller.apply(selected.path, pywal)
    }

    function openFixedPrompt() {
        if (!selected || controller.busy)
            return
        promptError = ""
        backgroundInput.text = controller.fixedBackground
        fixedPrompt = true
        Qt.callLater(() => {
            backgroundInput.forceActiveFocus()
            backgroundInput.selectAll()
        })
    }

    function applyFixed() {
        if (!selected || controller.busy)
            return
        const color = backgroundInput.text.trim().replace(/^#/, "")
        if (!/^[0-9a-fA-F]{6}$/.test(color)) {
            promptError = "Enter a six-digit hex colour, e.g. 121212"
            return
        }
        controller.fixedBackground = color
        controller.apply(selected.path, true, color)
        fixedPrompt = false
        grid.forceActiveFocus()
    }

    function activateAction(action) {
        if (action === "fixed")
            openFixedPrompt()
        else
            applySelection(action === "pywal")
    }

    function handleEscape() {
        if (fixedPrompt) {
            fixedPrompt = false
            promptError = ""
            grid.forceActiveFocus()
        } else if (search.activeFocus) {
            grid.forceActiveFocus()
        } else {
            closeRequested()
        }
    }

    function navigate(event) {
        const columns = Math.max(1, Math.floor(grid.width / grid.cellWidth))
        switch (event.key) {
        case Qt.Key_Left: moveSelection(-1); break
        case Qt.Key_Right: moveSelection(1); break
        case Qt.Key_Up: moveSelection(-columns); break
        case Qt.Key_Down: moveSelection(columns); break
        default: return
        }
        event.accepted = true
    }

    screen: targetScreen
    visible: true
    color: "transparent"
    implicitWidth: targetScreen ? Math.min(660, targetScreen.width - 32) : 660
    implicitHeight: targetScreen ? Math.min(570, targetScreen.height - config.popupGap - 24) : 570
    exclusiveZone: 0
    focusable: true
    anchors.top: true
    anchors.left: true
    margins.top: config.popupGap
    margins.left: targetScreen ? Math.max(0, Math.round((targetScreen.width - width) / 2)) : 0
    WlrLayershell.namespace: "quickshell-wallpaper-picker"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

    Component.onCompleted: Qt.callLater(() => grid.forceActiveFocus())
    Component.onDestruction: {
        if (scanProcess.running)
            scanProcess.signal(15)
    }

    Shortcut { sequence: "Escape"; onActivated: root.handleEscape() }
    Shortcut {
        sequence: "B"
        enabled: !search.activeFocus && !root.fixedPrompt && !!root.selected && !root.controller.busy
        onActivated: root.applySelection(false)
    }
    Shortcut {
        sequence: "P"
        enabled: !search.activeFocus && !root.fixedPrompt && !!root.selected && !root.controller.busy
        onActivated: root.applySelection(true)
    }
    Shortcut {
        sequence: "Ctrl+P"
        enabled: !root.fixedPrompt && !!root.selected && !root.controller.busy
        onActivated: root.openFixedPrompt()
    }

    Process {
        id: scanProcess
        command: ["python3", root.controller.helperPath, "list", "--directory", root.controller.directory]
        running: true
        stdout: SplitParser {
            onRead: data => {
                try {
                    const record = JSON.parse(data)
                    if (record.path) {
                        root.addEntry(record)
                    } else if (record.done) {
                        root.scanFinished = true
                        if (record.failed)
                            root.scanNotice = record.failed + " thumbnail(s) unavailable"
                    } else if (record.error) {
                        root.scanError = record.error
                    }
                } catch (error) {
                    root.scanError = "Could not read wallpaper list"
                }
            }
        }
        stderr: StdioCollector {}
        onExited: exitCode => {
            if (!root.scanFinished && root.scanError === "")
                root.scanError = "Could not finish loading wallpapers"
        }
    }

    PopupCatcher {
        targetScreen: root.targetScreen
        visible: root.visible
        onDismissed: root.closeRequested()
    }

    Rectangle {
        anchors.fill: parent
        color: root.config.surface
        border.color: root.config.borderColor
        border.width: 1
        radius: root.config.popupRadius

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 12
            spacing: 8

            TextField {
                renderType: Text.NativeRendering
                id: search
                Layout.fillWidth: true
                Layout.preferredHeight: 34
                placeholderText: "Search wallpapers…"
                color: root.config.fg
                placeholderTextColor: root.config.muted
                selectionColor: root.config.accent
                selectedTextColor: root.config.bg
                font.pointSize: root.config.fontSize(0.92)
                selectByMouse: true
                enabled: !root.fixedPrompt
                KeyNavigation.priority: KeyNavigation.BeforeItem
                KeyNavigation.tab: grid
                KeyNavigation.backtab: grid
                onTextChanged: root.filterEntries()
                onAccepted: grid.forceActiveFocus()
                background: Rectangle {
                    color: "transparent"
                    radius: 4
                    border.color: search.activeFocus ? root.config.accent : root.config.borderColor
                }
                Keys.onPressed: event => {
                    switch (event.key) {
                    case Qt.Key_Up:
                    case Qt.Key_Down:
                        grid.forceActiveFocus()
                        root.navigate(event)
                        break
                    default: return
                    }
                }
            }

            GridView {
                id: grid
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                cellWidth: width / Math.max(1, Math.floor(width / 190))
                cellHeight: 145
                model: visibleEntries
                keyNavigationEnabled: false
                reuseItems: true
                cacheBuffer: 145
                enabled: !root.fixedPrompt
                activeFocusOnTab: true
                KeyNavigation.priority: KeyNavigation.BeforeItem
                KeyNavigation.tab: search
                KeyNavigation.backtab: search
                Keys.onPressed: event => root.navigate(event)

                delegate: Item {
                    id: tile
                    required property string path
                    required property string name
                    required property string thumbnail
                    required property int index
                    width: grid.cellWidth
                    height: grid.cellHeight

                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: 3
                        radius: 4
                        color: root.config.bg
                        border.width: root.selectedIndex === tile.index ? 2 : 1
                        border.color: root.selectedIndex === tile.index ? root.config.accent : root.config.borderColor

                        Image {
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.top: parent.top
                            anchors.margins: 4
                            height: parent.height - 30
                            source: tile.thumbnail
                            sourceSize.width: 384
                            sourceSize.height: 216
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                        }

                        Text {
                            renderType: Text.NativeRendering
                            anchors.centerIn: parent
                            visible: tile.thumbnail === ""
                            text: "No preview"
                            color: root.config.muted
                            font.pointSize: root.config.fontSize(0.8)
                        }

                        Text {
                            renderType: Text.NativeRendering
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.bottom: parent.bottom
                            anchors.margins: 7
                            text: tile.name
                            elide: Text.ElideMiddle
                            color: root.config.fg
                            font.pointSize: root.config.fontSize(0.8)
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            root.selectedPath = tile.path
                            grid.forceActiveFocus()
                        }
                        onDoubleClicked: root.applySelection(false)
                    }
                }

                Text {
                    renderType: Text.NativeRendering
                    anchors.centerIn: parent
                    visible: visibleEntries.count === 0
                    text: scanProcess.running ? "Loading wallpapers…"
                        : allEntries.count ? "No matching wallpapers" : "No wallpapers found"
                    color: root.config.muted
                    font.pointSize: root.config.fontSize(0.9)
                }
            }

            Text {
                renderType: Text.NativeRendering
                Layout.fillWidth: true
                text: root.selected ? root.selected.name : root.controller.directory
                elide: Text.ElideMiddle
                color: root.config.fg
                font.pointSize: root.config.fontSize(0.82)
            }

            RowLayout {
                Layout.fillWidth: true
                visible: root.fixedPrompt
                spacing: 8

                Text {
                    renderType: Text.NativeRendering
                    text: "Fixed background"
                    color: root.config.fg
                    font.pointSize: root.config.fontSize(0.85)
                }
                TextField {
                    renderType: Text.NativeRendering
                    id: backgroundInput
                    Layout.fillWidth: true
                    Layout.preferredHeight: 32
                    placeholderText: "121212"
                    color: root.config.fg
                    placeholderTextColor: root.config.muted
                    selectionColor: root.config.accent
                    selectedTextColor: root.config.bg
                    font.pointSize: root.config.fontSize(0.9)
                    selectByMouse: true
                    enabled: !root.controller.busy
                    onAccepted: root.applyFixed()
                    onTextChanged: root.promptError = ""
                    background: Rectangle {
                        radius: 4
                        color: "transparent"
                        border.color: backgroundInput.activeFocus ? root.config.accent : root.config.borderColor
                    }
                }
                Text {
                    renderType: Text.NativeRendering
                    text: "Enter: apply · Esc: cancel"
                    color: root.config.muted
                    font.pointSize: root.config.fontSize(0.78)
                }
            }

            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 1
                color: root.config.borderColor
            }

            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: 30

                Text {
                    renderType: Text.NativeRendering
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    width: Math.max(0, parent.width - actionTips.width - 12)
                    text: root.promptError || root.controller.errorText || root.scanError
                        || (root.controller.busy ? "Applying wallpaper…" : root.controller.noticeText)
                        || (scanProcess.running ? "Building thumbnails… " + allEntries.count : root.scanNotice)
                        || visibleEntries.count + " wallpapers"
                    color: root.promptError || root.controller.errorText || root.scanError ? root.config.urgent : root.config.muted
                    font.pointSize: root.config.fontSize(0.78)
                    elide: Text.ElideRight
                    ToolTip.visible: statusHover.hovered && truncated
                    ToolTip.text: text
                    ToolTip.delay: 500

                    HoverHandler { id: statusHover }
                }

                Row {
                    id: actionTips
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 10

                    Repeater {
                        model: root.actions
                        delegate: Item {
                            id: hint
                            required property var modelData
                            readonly property bool hovered: enabled && hintMouse.containsMouse
                            width: hintRow.width
                            height: 20
                            opacity: enabled ? 1 : 0.5
                            enabled: !!root.selected && !root.controller.busy && !root.fixedPrompt

                            Rectangle {
                                anchors.fill: parent
                                anchors.margins: -4
                                radius: 4
                                color: hint.hovered ? root.config.borderColor : "transparent"
                            }

                            Row {
                                id: hintRow
                                spacing: 5
                                Text {
                                    renderType: Text.NativeRendering
                                    height: 20
                                    verticalAlignment: Text.AlignVCenter
                                    text: hint.modelData.label
                                    color: hint.hovered ? root.config.fg : root.config.muted
                                    font.pointSize: root.config.fontSize(0.8)
                                }
                                KeyCap {
                                    visible: hint.modelData.control
                                    label: "Ctrl"
                                    edgeColor: hint.hovered ? root.config.accent : root.config.borderColor
                                    textColor: root.config.muted
                                    fontPointSize: root.config.fontSize(0.74)
                                }
                                KeyCap {
                                    label: hint.modelData.key
                                    edgeColor: hint.hovered ? root.config.accent : root.config.borderColor
                                    textColor: root.config.muted
                                    fontPointSize: root.config.fontSize(0.74)
                                }
                            }
                            MouseArea {
                                id: hintMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.activateAction(hint.modelData.action)
                            }
                        }
                    }
                }
            }
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
            renderType: Text.NativeRendering
            id: capText
            anchors.centerIn: parent
            text: parent.label
            color: parent.textColor
            font.pointSize: parent.fontPointSize
        }
    }
}
