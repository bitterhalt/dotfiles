import "../components"
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

Item {
    id: root

    required property var config
    required property var targetScreen
    property bool opened: false
    property var processes: []
    property string query: ""
    property int selectedIndex: 0
    property var killTarget: null
    property string errorText: ""
    readonly property string helperPath: Quickshell.env("HOME") + "/.config/quickshell/menus/processes.py"
    readonly property int rowHeight: 36
    readonly property var rows: {
        if (!opened)
            return [];

        if (killTarget)
            return [{
            "name": "No",
            "action": "cancel"
        }, {
            "name": "Yes",
            "action": "kill"
        }];

        const needle = query.trim().toLowerCase();
        return processes.filter((process) => {
            return process.name.toLowerCase().includes(needle) || String(process.pid).includes(needle);
        });
    }

    function openMenu() {
        killTarget = null;
        errorText = "";
        searchInput.text = "";
        selectedIndex = 0;
        opened = true;
        refresh();
        Qt.callLater(() => {
            return searchInput.forceActiveFocus();
        });
    }

    function closeMenu() {
        opened = false;
        killTarget = null;
        processes = [];
        errorText = "";
        searchInput.text = "";
    }

    function toggleMenu() {
        opened ? closeMenu() : openMenu();
    }

    function refresh() {
        if (!listProcess.running && !killProcess.running) {
            errorText = "";
            listProcess.running = true;
        }
    }

    function moveSelection(direction) {
        if (rows.length === 0)
            return ;

        selectedIndex = (selectedIndex + direction + rows.length) % rows.length;
        resultList.positionViewAtIndex(selectedIndex, ListView.Contain);
    }

    function back() {
        if (killTarget) {
            killTarget = null;
            errorText = "";
            selectedIndex = 0;
        } else {
            closeMenu();
        }
    }

    function activateSelected() {
        if (killProcess.running || selectedIndex < 0 || selectedIndex >= rows.length)
            return ;

        const item = rows[selectedIndex];
        if (!killTarget) {
            killTarget = item;
            errorText = "";
            selectedIndex = 0; // Cancel is always the default.
        } else if (item.action === "cancel") {
            back();
        } else if (item.action === "kill") {
            killProcess.command = ["python3", helperPath, "kill", String(killTarget.pid), killTarget.started];
            killProcess.running = true;
        }
    }

    onRowsChanged: selectedIndex = Math.max(0, Math.min(selectedIndex, rows.length - 1))

    Process {
        id: listProcess

        command: ["python3", root.helperPath, "list"]
        onExited: (exitCode) => {
            if (root.opened && exitCode !== 0)
                root.errorText = "Could not read processes";

        }

        stdout: StdioCollector {
            onStreamFinished: {
                if (!root.opened)
                    return ;

                try {
                    root.processes = JSON.parse(text);
                } catch (error) {
                    root.errorText = "Could not read processes";
                }
            }
        }

    }

    Process {
        id: killProcess

        onExited: (exitCode) => {
            if (!root.opened)
                return ;

            if (exitCode === 0) {
                root.killTarget = null;
                root.selectedIndex = 0;
                root.refresh();
            } else {
                root.errorText = "Could not kill process";
            }
        }
    }

    PanelWindow {
        screen: root.targetScreen
        visible: root.opened
        color: "transparent"
        implicitWidth: 220
        implicitHeight: 42 + 7 * root.rowHeight + 32 + root.config.barModuleSpacing * 2
        exclusiveZone: 0
        focusable: true
        anchors.top: true
        anchors.left: true
        margins.top: root.config.popupGap
        margins.left: root.targetScreen ? Math.max(0, Math.round((root.targetScreen.width - width) / 2)) : 0
        WlrLayershell.namespace: "quickshell-submenu"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

        Rectangle {
            anchors.fill: parent
            color: root.config.surface
            radius: root.config.popupRadius
            border.width: 1
            border.color: root.config.borderColor
            clip: true

            Rectangle {
                id: searchBackground

                anchors.fill: searchInput
                anchors.leftMargin: 8
                anchors.rightMargin: 8
                anchors.topMargin: 8
                visible: root.killTarget === null
                color: root.config.bg
                radius: 4
                border.width: 1
                border.color: searchInput.activeFocus ? root.config.accent : root.config.borderColor
            }

            TextInput {
                id: searchInput

                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                height: 42
                leftPadding: 18
                rightPadding: 18
                topPadding: root.killTarget ? 0 : searchBackground.anchors.topMargin
                bottomPadding: root.killTarget ? 0 : searchBackground.anchors.bottomMargin
                verticalAlignment: TextInput.AlignVCenter
                color: root.killTarget ? "transparent" : root.config.fg
                cursorVisible: activeFocus && !root.killTarget
                selectionColor: root.config.accent
                selectedTextColor: root.config.bg
                font.pointSize: root.config.fontSize(1)
                clip: true
                readOnly: root.killTarget !== null
                onTextChanged: {
                    root.query = text;
                    root.selectedIndex = 0;
                }
                Keys.onPressed: (event) => {
                    switch (event.key) {
                    case Qt.Key_Down:
                    case Qt.Key_Tab:
                        root.moveSelection(1);
                        event.accepted = true;
                        break;
                    case Qt.Key_Up:
                    case Qt.Key_Backtab:
                        root.moveSelection(-1);
                        event.accepted = true;
                        break;
                    case Qt.Key_Return:
                    case Qt.Key_Enter:
                        root.activateSelected();
                        event.accepted = true;
                        break;
                    case Qt.Key_Escape:
                        root.back();
                        event.accepted = true;
                        break;
                    case Qt.Key_R:
                        if ((event.modifiers & Qt.ControlModifier) && !root.killTarget) {
                            root.refresh();
                            event.accepted = true;
                        }
                        break;
                    }
                }
            }

            Text {
                anchors.fill: searchInput
                anchors.leftMargin: 18
                anchors.rightMargin: 18
                anchors.topMargin: root.killTarget ? 0 : searchBackground.anchors.topMargin
                anchors.bottomMargin: root.killTarget ? 0 : searchBackground.anchors.bottomMargin
                verticalAlignment: Text.AlignVCenter
                visible: root.killTarget !== null || searchInput.text === ""
                color: root.killTarget ? root.config.fg : root.config.muted
                font.pointSize: root.config.fontSize(1)
                elide: Text.ElideRight
                text: root.killTarget ? "Kill " + root.killTarget.name + " (PID " + root.killTarget.pid + ")?" : "Kill process"
            }

            ListView {
                id: resultList

                anchors.top: searchInput.bottom
                anchors.topMargin: root.config.barModuleSpacing
                anchors.bottom: footer.top
                anchors.bottomMargin: root.config.barModuleSpacing
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.leftMargin: 4
                anchors.rightMargin: 4
                model: root.rows
                currentIndex: root.selectedIndex
                clip: true

                delegate: Rectangle {
                    required property var modelData
                    required property int index

                    width: ListView.view.width
                    height: root.rowHeight
                    radius: 4
                    color: index === root.selectedIndex ? root.config.borderColor : "transparent"

                    Text {
                        anchors.left: parent.left
                        anchors.leftMargin: 14
                        anchors.right: pidLabel.left
                        anchors.rightMargin: 12
                        anchors.verticalCenter: parent.verticalCenter
                        color: root.config.fg
                        font.pointSize: root.config.fontSize(0.96)
                        elide: Text.ElideRight
                        text: modelData.name
                    }

                    Text {
                        id: pidLabel

                        anchors.right: parent.right
                        anchors.rightMargin: 14
                        anchors.verticalCenter: parent.verticalCenter
                        color: root.config.muted
                        font.pointSize: root.config.fontSize(0.8)
                        text: modelData.pid ? "PID " + modelData.pid : ""
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            root.selectedIndex = parent.index;
                            root.activateSelected();
                        }
                    }

                }

            }

            Text {
                anchors.centerIn: resultList
                visible: root.rows.length === 0
                color: root.config.muted
                font.pointSize: root.config.fontSize(0.88)
                text: listProcess.running ? "Loading…" : "No processes found"
            }

            Item {
                id: footer

                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                height: 32

                Rectangle {
                    anchors.top: parent.top
                    width: parent.width
                    height: 1
                    color: root.config.borderColor
                }

                Text {
                    anchors.fill: parent
                    anchors.leftMargin: 14
                    anchors.rightMargin: 14
                    verticalAlignment: Text.AlignVCenter
                    color: root.errorText ? root.config.urgent : root.config.muted
                    font.pointSize: root.config.fontSize(0.78)
                    elide: Text.ElideRight
                    text: root.errorText || (killProcess.running ? "Killing…" : root.killTarget ? "Enter Confirm · Esc Back" : "Enter Select · Ctrl+R Refresh")
                }

            }

        }

    }

    PopupCatcher {
        targetScreen: root.targetScreen
        visible: root.opened
        onDismissed: root.closeMenu()
    }

    IpcHandler {
        function toggle() {
            root.toggleMenu();
        }

        function open() {
            root.openMenu();
        }

        function close() {
            root.closeMenu();
        }

        target: "processMenu"
    }

}
