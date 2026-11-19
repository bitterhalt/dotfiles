pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "../components"
import "../wallpaper"

PanelWindow {
    id: root

    required property var config
    required property var targetScreen
    required property var controller
    required property var popupMotion
    property string scanError: ""
    property string scanNotice: ""
    property bool scanFinished: false
    property string selectedPath: ""
    property bool settingsOpen: false
    Binding {
        target: root.popupMotion
        property: "surfaceHeight"
        value: root.height
    }
    // Footer actions and their single-key shortcuts.
    readonly property var actions: [
        {
            label: "Set Wallpaper",
            key: "b",
            action: "wallpaper",
            control: false
        },
        {
            label: "Hellwal",
            key: "h",
            action: "hellwal",
            control: false
        },
        {
            label: "Settings",
            key: "s",
            action: "settings",
            control: false
        }
    ]
    readonly property int selectedIndex: {
        if (visibleEntries.count === 0)
            return -1;
        if (selectedPath === "")
            return 0;
        for (let i = 0; i < visibleEntries.count; ++i) {
            if (visibleEntries.get(i).path === selectedPath)
                return i;
        }
        return 0;
    }
    readonly property var selected: selectedIndex >= 0 && selectedIndex < visibleEntries.count ? visibleEntries.get(selectedIndex) : null

    signal closeRequested

    ListModel {
        id: allEntries
    }
    ListModel {
        id: visibleEntries
    }

    // Search, selection, and wallpaper-apply actions.
    function matches(entry) {
        return entry.name.toLowerCase().includes(search.text.trim().toLowerCase());
    }

    function addEntry(entry) {
        allEntries.append(entry);
        if (matches(entry))
            visibleEntries.append(entry);
    }

    function filterEntries() {
        visibleEntries.clear();
        for (let i = 0; i < allEntries.count; ++i) {
            const entry = allEntries.get(i);
            if (matches(entry))
                visibleEntries.append({
                    path: entry.path,
                    name: entry.name,
                    thumbnail: entry.thumbnail
                });
        }
        selectedPath = "";
        grid.positionViewAtBeginning();
    }

    function moveSelection(delta) {
        if (visibleEntries.count === 0)
            return;
        const index = Math.max(0, Math.min(visibleEntries.count - 1, selectedIndex + delta));
        selectedPath = visibleEntries.get(index).path;
        grid.positionViewAtIndex(index, GridView.Contain);
    }

    function applySelection(hellwal) {
        if (selected)
            controller.apply(selected.path, hellwal);
    }

    function openSettings() {
        settingsOpen = true;
        settingsPanel.begin();
    }

    function closeSettings() {
        settingsOpen = false;
        grid.forceActiveFocus();
    }

    function saveSettingsAndRefresh() {
        closeSettings();
        controller.refreshHellwal();
    }

    function activateAction(action) {
        if (action === "settings")
            openSettings();
        else
            applySelection(action === "hellwal");
    }

    function handleEscape() {
        if (settingsOpen) {
            closeSettings();
        } else if (search.activeFocus) {
            grid.forceActiveFocus();
        } else {
            closeRequested();
        }
    }

    function navigate(event) {
        const columns = Math.max(1, Math.floor(grid.width / grid.cellWidth));
        switch (event.key) {
        case Qt.Key_Left:
            moveSelection(-1);
            break;
        case Qt.Key_Right:
            moveSelection(1);
            break;
        case Qt.Key_Up:
            moveSelection(-columns);
            break;
        case Qt.Key_Down:
            moveSelection(columns);
            break;
        default:
            return;
        }
        event.accepted = true;
    }

    screen: targetScreen
    visible: root.popupMotion.surfaceVisible
    color: "transparent"
    implicitWidth: targetScreen ? Math.min(660, targetScreen.width - 32) : 660
    implicitHeight: targetScreen ? Math.min(570, targetScreen.height - config.popupGap - 24) : 570
    exclusiveZone: 0
    focusable: root.popupMotion.shown
    anchors.top: true
    anchors.left: true
    margins.top: config.popupGap
    margins.left: targetScreen ? Math.max(0, Math.round((targetScreen.width - width) / 2)) : 0
    WlrLayershell.namespace: "slim-wallpaper-picker"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: root.popupMotion.shown ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    Component.onCompleted: Qt.callLater(() => grid.forceActiveFocus())
    Component.onDestruction: {
        if (scanProcess.running)
            scanProcess.signal(15);
    }

    Shortcut {
        sequence: "Escape"
        onActivated: root.handleEscape()
    }
    Shortcut {
        sequence: "B"
        enabled: !search.activeFocus && !root.settingsOpen && !!root.selected && !root.controller.busy
        onActivated: root.applySelection(false)
    }
    Shortcut {
        sequence: "H"
        enabled: !search.activeFocus && !root.settingsOpen && !!root.selected && !root.controller.busy
        onActivated: root.applySelection(true)
    }
    Shortcut {
        sequence: "S"
        enabled: !search.activeFocus && !root.settingsOpen
        onActivated: root.openSettings()
    }

    Process {
        id: scanProcess
        command: ["python3", root.controller.helperPath, "list", "--directory", root.controller.directory]
        running: true
        stdout: SplitParser {
            onRead: data => {
                try {
                    const record = JSON.parse(data);
                    if (record.path) {
                        root.addEntry(record);
                    } else if (record.done) {
                        root.scanFinished = true;
                        if (record.failed)
                            root.scanNotice = record.failed + " thumbnail(s) unavailable";
                    } else if (record.error) {
                        root.scanError = record.error;
                    }
                } catch (error) {
                    root.scanError = "Could not read wallpaper list";
                }
            }
        }
        stderr: StdioCollector {}
        onExited: exitCode => {
            if (!root.scanFinished && root.scanError === "")
                root.scanError = "Could not finish loading wallpapers";
        }
    }

    PopupCatcher {
        targetScreen: root.targetScreen
        visible: root.visible
        onDismissed: root.closeRequested()
    }

    PanelSurface {
        anchors.fill: parent
        config: root.config
        enabled: root.popupMotion.shown
        opacity: root.popupMotion.contentOpacity
        transform: Translate {
            y: root.popupMotion.contentOffset
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: root.config.panelPadding
            spacing: root.config.spacingControl

            // Search field spans the picker above the thumbnail list and preview.
            TextField {
                id: search
                renderType: Text.NativeRendering
                Layout.fillWidth: true
                Layout.preferredHeight: 34
                visible: !root.settingsOpen
                placeholderText: "Search wallpapers…"
                color: root.config.fg
                placeholderTextColor: root.config.muted
                selectionColor: root.config.selectionBackground
                selectedTextColor: root.config.selectionForeground
                font.pointSize: root.config.textSizeNormal
                selectByMouse: true
                enabled: !root.settingsOpen
                KeyNavigation.priority: KeyNavigation.BeforeItem
                KeyNavigation.tab: grid
                KeyNavigation.backtab: grid
                onTextChanged: root.filterEntries()
                onAccepted: grid.forceActiveFocus()
                background: Rectangle {
                    color: "transparent"
                    radius: 4
                    border.color: root.config.selectionBackground
                }
                Keys.onPressed: event => {
                    switch (event.key) {
                    case Qt.Key_Up:
                    case Qt.Key_Down:
                        grid.forceActiveFocus();
                        root.navigate(event);
                        break;
                    default:
                        return;
                    }
                }
            }

            // Wallpaper thumbnails on the left; selected image preview on the right.
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
                visible: !root.settingsOpen
                enabled: !root.settingsOpen
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
                        anchors.margins: root.config.spacingControl / 2
                        radius: 4
                        color: root.config.bg
                        border.width: root.selectedIndex === tile.index ? 2 : 1
                        border.color: root.selectedIndex === tile.index ? root.config.selectionBackground : root.config.border

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
                            font.pointSize: root.config.textSizeSmall
                        }

                        Text {
                            renderType: Text.NativeRendering
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.bottom: parent.bottom
                            anchors.margins: root.config.spacingControl
                            text: tile.name
                            elide: Text.ElideMiddle
                            color: root.config.fg
                            font.pointSize: root.config.textSizeMedium
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            root.selectedPath = tile.path;
                            grid.forceActiveFocus();
                        }
                        onDoubleClicked: root.applySelection(false)
                    }
                }

                Text {
                    renderType: Text.NativeRendering
                    anchors.centerIn: parent
                    visible: visibleEntries.count === 0
                    text: scanProcess.running ? "Loading wallpapers…" : allEntries.count ? "No matching wallpapers" : "No wallpapers found"
                    color: root.config.muted
                    font.pointSize: root.config.textSizeMedium
                }
            }

            WallpaperSettings {
                id: settingsPanel
                Layout.fillWidth: true
                Layout.fillHeight: true
                visible: root.settingsOpen
                config: root.config
                settingsService: root.controller.settingsService
                busy: root.controller.busy
                onSaved: root.saveSettingsAndRefresh()
                onCancelled: root.closeSettings()
            }

            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 1
                color: root.config.border
                visible: !root.settingsOpen
            }

            // Status, errors, and action/shortcut hints.
            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: Math.max(30, actionTips.implicitHeight)
                visible: !root.settingsOpen

                Text {
                    id: wallpaperStatus
                    renderType: Text.NativeRendering
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    width: Math.max(0, parent.width - actionTips.width - root.config.panelPadding)
                    text: root.controller.errorText || root.scanError || (root.controller.busy ? "Applying wallpaper…" : root.controller.noticeText) || (scanProcess.running ? "Building thumbnails… " + allEntries.count : root.scanNotice) || visibleEntries.count + " wallpapers"
                    color: root.controller.errorText || root.scanError ? root.config.urgent : root.config.muted
                    font.pointSize: root.config.textSizeSmall
                    elide: Text.ElideRight
                    ShellToolTip {
                        config: root.config
                        anchorItem: wallpaperStatus
                        shown: statusHover.hovered && wallpaperStatus.truncated
                        text: wallpaperStatus.text
                        delay: 500
                    }

                    HoverHandler {
                        id: statusHover
                    }
                }

                Row {
                    id: actionTips
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: root.config.spacingControl

                    Repeater {
                        model: root.actions
                        delegate: Item {
                            id: hint
                            required property var modelData
                            readonly property bool hovered: enabled && hintMouse.containsMouse
                            width: hintRow.width + root.config.spacingTight * 2
                            height: hintRow.height + root.config.spacingTight * 2
                            opacity: enabled ? 1 : 0.5
                            enabled: (hint.modelData.action === "settings" || !!root.selected) && !root.controller.busy && !root.settingsOpen

                            Rectangle {
                                anchors.fill: parent
                                radius: 4
                                color: hint.hovered ? root.config.selectionBackground : "transparent"
                            }

                            Row {
                                id: hintRow
                                anchors.centerIn: parent
                                spacing: root.config.spacingTight
                                Text {
                                    renderType: Text.NativeRendering
                                    height: 20
                                    verticalAlignment: Text.AlignVCenter
                                    text: hint.modelData.label
                                    color: hint.hovered ? root.config.selectionForeground : root.config.muted
                                    font.pointSize: root.config.textSizeSmall
                                }
                                KeyCap {
                                    visible: hint.modelData.control
                                    label: "Ctrl"
                                    edgeColor: hint.hovered ? root.config.selectionForeground : root.config.selectionBackground
                                    textColor: hint.hovered ? root.config.selectionForeground : root.config.muted
                                    fontPointSize: root.config.textSizeSmall
                                }
                                KeyCap {
                                    label: hint.modelData.key
                                    edgeColor: hint.hovered ? root.config.selectionForeground : root.config.selectionBackground
                                    textColor: hint.hovered ? root.config.selectionForeground : root.config.muted
                                    fontPointSize: root.config.textSizeSmall
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
            id: capText
            renderType: Text.NativeRendering
            anchors.centerIn: parent
            text: parent.label
            color: parent.textColor
            font.pointSize: parent.fontPointSize
        }
    }
}
