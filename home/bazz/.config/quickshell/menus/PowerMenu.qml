import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

Item {
    id: root

    required property var config
    required property var targetScreen

    property bool opened: false
    property var menuScreen: null
    property int selectedIndex: 0
    readonly property var actions: [
        { label: "Lock", icon: "󰌾", key: "l", command: "swaylock -C ~/.cache/wal/colors-swaylock" },
        { label: "Log out", icon: "󰍃", key: "E", command: "niri msg action quit" },
        { label: "Suspend", icon: "󰤄", key: "z", command: "systemctl suspend" },
        { label: "Restart", icon: "󰜉", key: "R", command: "systemctl reboot" },
        { label: "Shut down", icon: "󰐥", key: "S", command: "systemctl poweroff", destructive: true }
    ]
    readonly property int padding: 12
    readonly property int tileHeight: 110
    readonly property int tileWidth: Math.min(140, Math.max(64,
        Math.floor(((menuScreen || targetScreen)?.width || 800)
            / actions.length - config.popupGap * 2 / actions.length
            - padding * 2 / actions.length
            - config.barModuleSpacing * (actions.length - 1) / actions.length)))

    function openMenu(screen) {
        menuScreen = screen || targetScreen
        selectedIndex = 0
        opened = true
        Qt.callLater(() => keyboardHandler.forceActiveFocus())
    }

    function closeMenu() {
        opened = false
        menuScreen = null
    }

    function toggleMenu(screen) {
        opened ? closeMenu() : openMenu(screen)
    }

    function moveSelection(direction) {
        selectedIndex = (selectedIndex + direction + actions.length) % actions.length
    }

    function activate(index) {
        if (index < 0 || index >= actions.length)
            return
        const command = actions[index].command
        closeMenu()
        config.run(command)
    }

    PanelWindow {
        screen: root.menuScreen || root.targetScreen
        visible: root.opened
        color: "transparent"
        exclusiveZone: 0
        implicitWidth: root.padding * 2 + root.actions.length * root.tileWidth
            + (root.actions.length - 1) * root.config.barModuleSpacing
        implicitHeight: root.tileHeight + root.padding * 2
        focusable: true
        anchors.top: true
        anchors.left: true
        margins.top: 0
        margins.left: screen ? Math.max(0, Math.round((screen.width - width) / 2)) : 0
        WlrLayershell.namespace: "power-menu"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

        Rectangle {
            anchors.fill: parent
            color: root.config.bg
            radius: root.padding
            topLeftRadius: 0
            topRightRadius: 0

            FocusScope {
                id: keyboardHandler

                anchors.fill: parent
                focus: true
                Keys.onPressed: event => {
                    switch (event.key) {
                    case Qt.Key_Left:
                    case Qt.Key_Up:
                    case Qt.Key_Backtab:
                        root.moveSelection(-1)
                        event.accepted = true
                        return
                    case Qt.Key_Right:
                    case Qt.Key_Down:
                    case Qt.Key_Tab:
                        root.moveSelection(1)
                        event.accepted = true
                        return
                    case Qt.Key_Return:
                    case Qt.Key_Enter:
                        root.activate(root.selectedIndex)
                        event.accepted = true
                        return
                    case Qt.Key_Escape:
                        root.closeMenu()
                        event.accepted = true
                        return
                    }
                    const index = root.actions.findIndex(action => action.key === event.text)
                    if (index >= 0) {
                        root.activate(index)
                        event.accepted = true
                    }
                }
            }

            Row {
                anchors.top: parent.top
                anchors.topMargin: root.padding
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: root.config.barModuleSpacing

                Repeater {
                    model: root.actions

                    delegate: Rectangle {
                        id: tile

                        required property var modelData
                        required property int index
                        readonly property bool selected: root.selectedIndex === index
                        readonly property bool danger: selected && modelData.destructive === true
                        readonly property color foreground: danger ? root.config.bg : root.config.fg

                        width: root.tileWidth
                        height: root.tileHeight
                        radius: root.config.popupRadius * 2
                        color: danger ? root.config.urgent
                            : selected ? root.config.borderColor : root.config.surface
                        border.width: 1
                        border.color: danger ? root.config.urgent
                            : selected ? root.config.accent
                            : Qt.rgba(root.config.fg.r, root.config.fg.g, root.config.fg.b, 0.18)

                        Rectangle {
                            anchors.top: parent.top
                            anchors.right: parent.right
                            anchors.margins: 5
                            width: 20
                            height: 20
                            radius: 3
                            color: tile.danger ? root.config.bg : root.config.borderColor
                            Text {
                                anchors.centerIn: parent
                                color: tile.danger ? root.config.urgent : root.config.fg
                                font.pointSize: root.config.fontSize(0.75)
                                text: tile.modelData.key
                            }
                        }

                        Column {
                            anchors.centerIn: parent
                            width: parent.width - 8
                            spacing: 10
                            Text {
                                width: parent.width
                                horizontalAlignment: Text.AlignHCenter
                                color: tile.foreground
                                font.family: root.config.iconFontFamily
                                font.pointSize: root.config.iconSize * 1.8
                                text: tile.modelData.icon
                            }
                            Text {
                                width: parent.width
                                horizontalAlignment: Text.AlignHCenter
                                color: tile.foreground
                                font.pointSize: root.config.fontSize(0.95)
                                elide: Text.ElideRight
                                text: tile.modelData.label
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onEntered: root.selectedIndex = tile.index
                            onClicked: root.activate(tile.index)
                        }
                    }
                }
            }
        }
    }

    // Keep dismissal separate so compositor shadows wrap the tile card,
    // not a transparent full-screen surface.
    PanelWindow {
        screen: root.menuScreen || root.targetScreen
        visible: root.opened
        color: "transparent"
        exclusiveZone: 0
        anchors.top: true
        anchors.bottom: true
        anchors.left: true
        anchors.right: true
        WlrLayershell.namespace: "quickshell-popup-catcher"
        WlrLayershell.layer: WlrLayer.Top
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
        MouseArea {
            anchors.fill: parent
            onClicked: root.closeMenu()
        }
    }

    IpcHandler {
        target: "power"

        function toggle() { root.toggleMenu(root.targetScreen) }
        function open() { root.openMenu(root.targetScreen) }
        function close() { root.closeMenu() }
    }
}
