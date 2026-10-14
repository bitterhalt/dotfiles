import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

import "../components"

Item {
    id: root

    required property var config
    required property var targetScreen

    property string page: "home"
    property int selectedIndex: 0
    property var sessions: []
    property string selectedSession: ""
    property string sessionName: ""
    property string promptError: ""

    readonly property var currentItems: {
        if (page === "home") {
            const actions = []

            if (sessions.length > 0) {
                actions.push({
                    label: "Attach session",
                    icon: "󰆍",
                    page: "attach"
                })
            }

            actions.push({
                label: "New session",
                icon: "󰐕",
                page: "new"
            })

            if (sessions.length > 0) {
                actions.push({
                    label: "Rename session",
                    icon: "󰑕",
                    page: "rename"
                })
                actions.push({
                    label: "Delete session",
                    icon: "󰩹",
                    page: "delete"
                })
            }

            return actions
        }

        if (page === "attach" || page === "rename" || page === "delete")
            return sessions.map(name => ({
                label: name,
                icon: "󰆍",
                sessionName: name
            }))

        if (page === "confirmDelete") {
            return [
                { label: "Delete session", icon: "󰩹", action: "delete" },
                { label: "Cancel", icon: "󰜺", action: "cancel" }
            ]
        }

        return []
    }

    readonly property string title: {
        switch (page) {
        case "home": return "Tmux Helper"
        case "attach": return "Attach session"
        case "rename": return "Rename session"
        case "delete": return "Delete session"
        case "confirmDelete": return "Confirm deletion"
        case "new": return "New session"
        case "renameInput": return "Rename session"
        default: return "Tmux Helper"
        }
    }

    function openMenu(): void {
        page = "home"
        selectedIndex = 0
        sessionName = ""
        selectedSession = ""
        promptError = ""
        menuWindow.visible = true
        refreshSessions()
        Qt.callLater(() => keyboardHandler.forceActiveFocus())
    }

    function closeMenu(): void {
        menuWindow.visible = false
        promptError = ""
    }

    function toggleMenu(): void {
        menuWindow.visible ? closeMenu() : openMenu()
    }

    function back(): void {
        switch (page) {
        case "attach":
        case "rename":
        case "delete":
        case "new":
            page = "home"
            selectedIndex = 0
            return
        case "renameInput":
            page = "rename"
            selectedIndex = 0
            Qt.callLater(() => keyboardHandler.forceActiveFocus())
            return
        case "confirmDelete":
            page = "delete"
            selectedIndex = 0
            return
        default:
            closeMenu()
        }
    }

    function refreshSessions(): void {
        if (!listSessions.running)
            listSessions.running = true
    }

    function selectNext(): void {
        if (currentItems.length > 0)
            selectedIndex = (selectedIndex + 1) % currentItems.length
    }

    function selectPrevious(): void {
        if (currentItems.length > 0)
            selectedIndex =
                (selectedIndex - 1 + currentItems.length) % currentItems.length
    }

    function activateSelected(): void {
        if (selectedIndex < 0 || selectedIndex >= currentItems.length)
            return

        const item = currentItems[selectedIndex]

        if (item.page) {
            page = item.page
            selectedIndex = 0

            if (page === "new") {
                sessionName = ""
                promptError = ""
                Qt.callLater(() => sessionInput.forceActiveFocus())
            } else {
                refreshSessions()
                Qt.callLater(() => keyboardHandler.forceActiveFocus())
            }

            return
        }

        if (page === "attach") {
            Quickshell.execDetached([
                "foot", "-a", "tmux", "-e",
                "tmux", "attach-session", "-t", item.sessionName
            ])
            closeMenu()
            return
        }

        if (page === "rename") {
            selectedSession = item.sessionName
            sessionName = item.sessionName
            promptError = ""
            page = "renameInput"
            Qt.callLater(() => sessionInput.forceActiveFocus())
            return
        }

        if (page === "delete") {
            selectedSession = item.sessionName
            page = "confirmDelete"
            selectedIndex = 1
            Qt.callLater(() => keyboardHandler.forceActiveFocus())
            return
        }

        if (page === "confirmDelete") {
            if (item.action === "delete") {
                sessionAction.command = [
                    "tmux", "kill-session", "-t", selectedSession
                ]
                sessionAction.action = "delete"
                sessionAction.running = true
            } else {
                back()
            }
        }
    }

    function submitSessionName(): void {
        const name = sessionName.trim()

        if (page === "new") {
            const command = ["tmux", "new-session"]

            if (name !== "")
                command.push("-s", name)

            Quickshell.execDetached([
                "foot", "-a", "tmux", "-e", ...command
            ])
            closeMenu()
            return
        }

        if (page === "renameInput") {
            if (name === "") {
                promptError = "Session name cannot be empty"
                return
            }

            if (name === selectedSession) {
                closeMenu()
                return
            }

            sessionAction.command = [
                "tmux", "rename-session", "-t", selectedSession, name
            ]
            sessionAction.action = "rename"
            sessionAction.running = true
        }
    }

    Process {
        id: listSessions

        command: ["tmux", "list-sessions", "-F", "#{session_name}"]

        stdout: StdioCollector {
            onStreamFinished: {
                root.sessions = text.trim()
                    .split("\n")
                    .filter(name => name.length > 0)
            }
        }

        onExited: exitCode => {
            if (exitCode !== 0)
                root.sessions = []
        }
    }

    Process {
        id: sessionAction

        property string action: ""

        onExited: exitCode => {
            const action = sessionAction.action
            sessionAction.action = ""

            if (exitCode !== 0) {
                root.promptError = action === "rename"
                    ? "Could not rename session"
                    : "Could not delete session"
                return
            }

            root.page = "home"
            root.selectedIndex = 0
            root.refreshSessions()
            Qt.callLater(() => keyboardHandler.forceActiveFocus())
        }
    }

    PanelWindow {
        id: menuWindow

        screen: root.targetScreen

        anchors {
            top: true
            left: true
        }

        implicitWidth: menuCard.implicitWidth
        implicitHeight: menuCard.implicitHeight
        margins.top: root.config.popupGap
        margins.left: root.targetScreen
            ? Math.max(0, Math.round((root.targetScreen.width - width) / 2)) : 0

        visible: false
        color: "transparent"
        exclusiveZone: 0
        focusable: true

        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "quickshell-submenu"
        WlrLayershell.keyboardFocus: visible
            ? WlrKeyboardFocus.Exclusive
            : WlrKeyboardFocus.None

        FocusScope {
            id: keyboardHandler

            anchors.fill: parent
            focus: true

            Keys.onPressed: event => {
                if (root.page === "new" || root.page === "renameInput")
                    return

                switch (event.key) {
                case Qt.Key_Up:
                case Qt.Key_Backtab:
                    root.selectPrevious()
                    event.accepted = true
                    break
                case Qt.Key_Down:
                case Qt.Key_Tab:
                    root.selectNext()
                    event.accepted = true
                    break
                case Qt.Key_Return:
                case Qt.Key_Enter:
                    root.activateSelected()
                    event.accepted = true
                    break
                case Qt.Key_Escape:
                    root.back()
                    event.accepted = true
                    break
                }
            }
        }

        PopoutPanel {
            id: menuCard

            z: 1
            config: root.config
            contentWidth: 300
            padding: 10
            spacing: 5

            anchors.top: parent.top
            anchors.horizontalCenter: parent.horizontalCenter

            Item {
                width: parent.width
                height: 30

                Text {
                    anchors.left: parent.left
                    anchors.leftMargin: 8
                    anchors.verticalCenter: parent.verticalCenter
                    color: root.config.fg
                    font.pointSize: root.config.fontSize(1)
                    font.weight: Font.DemiBold
                    text: root.title
                }

                Text {
                    anchors.right: parent.right
                    anchors.rightMargin: 8
                    anchors.verticalCenter: parent.verticalCenter
                    visible: root.page !== "home"
                    color: root.config.muted
                    font.pointSize: root.config.fontSize(0.8)
                    text: "Esc  Back"
                }
            }

            PanelSeparator {
                config: root.config
            }

            Repeater {
                model: root.currentItems

                delegate: Item {
                    id: menuItem

                    required property var modelData
                    required property int index

                    width: parent.width
                    height: 36

                    Rectangle {
                        anchors.fill: parent
                        radius: 4
                        color: menuItem.index === root.selectedIndex
                            || itemMouse.containsMouse
                            ? root.config.borderColor
                            : "transparent"
                    }

                    Text {
                        anchors.left: parent.left
                        anchors.leftMargin: 9
                        anchors.verticalCenter: parent.verticalCenter
                        width: 24
                        horizontalAlignment: Text.AlignHCenter
                        color: root.config.accent
                        font.family: root.config.iconFontFamily
                        font.pointSize: root.config.iconSize
                        text: menuItem.modelData.icon || ""
                    }

                    Text {
                        anchors.left: parent.left
                        anchors.leftMargin: 44
                        anchors.right: parent.right
                        anchors.rightMargin: 10
                        anchors.verticalCenter: parent.verticalCenter
                        color: root.config.fg
                        font.pointSize: root.config.fontSize(0.94)
                        elide: Text.ElideRight
                        text: menuItem.modelData.label
                    }

                    MouseArea {
                        id: itemMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onEntered: root.selectedIndex = menuItem.index
                        onClicked: {
                            root.selectedIndex = menuItem.index
                            root.activateSelected()
                        }
                    }
                }
            }

            Item {
                visible: root.page === "new" || root.page === "renameInput"
                width: parent.width
                height: visible ? 36 : 0

                Rectangle {
                    anchors.fill: parent
                    radius: 4
                    color: "transparent"
                    border.width: 1
                    border.color: sessionInput.activeFocus
                        ? root.config.accent
                        : root.config.borderColor

                    TextInput {
                        id: sessionInput

                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 10
                        verticalAlignment: TextInput.AlignVCenter
                        color: root.config.fg
                        selectionColor: root.config.accent
                        selectedTextColor: root.config.bg
                        font.pointSize: root.config.fontSize(0.92)
                        text: root.sessionName

                        onTextChanged: root.sessionName = text
                        onAccepted: root.submitSessionName()
                        Keys.onEscapePressed: root.back()
                    }

                    Text {
                        anchors.left: parent.left
                        anchors.leftMargin: 10
                        anchors.verticalCenter: parent.verticalCenter
                        visible: sessionInput.text.length === 0
                        color: root.config.muted
                        font.pointSize: root.config.fontSize(0.92)
                        text: root.page === "new"
                            ? "Session name (optional)"
                            : "New session name"
                    }
                }
            }

            Text {
                visible: root.promptError !== ""
                width: parent.width
                color: root.config.urgent
                font.pointSize: root.config.fontSize(0.78)
                text: root.promptError
            }
        }

        onVisibleChanged: {
            if (visible)
                Qt.callLater(() => keyboardHandler.forceActiveFocus())
        }
    }

    PopupCatcher {
        targetScreen: root.targetScreen
        visible: menuWindow.visible
        onDismissed: root.closeMenu()
    }

    IpcHandler {
        target: "tmuxMenu"

        function toggle(): void {
            root.toggleMenu()
        }

        function open(): void {
            root.openMenu()
        }

        function close(): void {
            root.closeMenu()
        }
    }
}
