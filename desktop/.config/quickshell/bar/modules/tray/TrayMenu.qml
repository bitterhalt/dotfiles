import QtQuick
import Quickshell
import Quickshell.Widgets
import "../../../components"

Item {
    id: root

    required property var config
    required property var menuHandle
    required property var popupManager

    property var currentMenu: menuHandle
    property var menuStack: []

    function reset(): void {
        currentMenu = menuHandle;
        menuStack = [];
    }

    function openSubmenu(entry): void {
        menuStack = menuStack.concat([currentMenu]);
        currentMenu = entry;
    }

    function goBack(): void {
        if (menuStack.length === 0)
            return;
        currentMenu = menuStack[menuStack.length - 1];
        menuStack = menuStack.slice(0, -1);
    }

    implicitWidth: 190
    implicitHeight: menuColumn.implicitHeight + 12
    width: implicitWidth
    height: implicitHeight

    Component.onCompleted: reset()

    QsMenuOpener {
        id: opener
        menu: root.currentMenu
    }

    PanelSurface {
        anchors.fill: parent
        config: root.config

        Column {
            id: menuColumn

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 6
            spacing: 2

            // Back row appears only when a submenu is open.
            Item {
                width: parent.width
                height: root.menuStack.length > 0 ? 34 : 0
                visible: height > 0

                Rectangle {
                    anchors.fill: parent
                    radius: 3
                    color: backMouse.containsMouse ? root.config.selectionBackground : "transparent"
                }

                Text {
                    renderType: Text.NativeRendering
                    anchors.left: parent.left
                    anchors.leftMargin: 10
                    anchors.verticalCenter: parent.verticalCenter

                    color: backMouse.containsMouse ? root.config.selectionForeground : root.config.muted
                    font.pointSize: root.config.textSizeMedium
                    text: "‹  Back"
                }

                MouseArea {
                    id: backMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor

                    onClicked: root.goBack()
                }
            }

            // Current menu entries supplied by the system tray item.
            Repeater {
                model: opener.children

                delegate: Loader {
                    required property var modelData

                    width: menuColumn.width

                    sourceComponent: modelData.isSeparator ? separatorComponent : menuItemComponent

                    property var entry: modelData
                }
            }
        }
    }

    Component {
        id: separatorComponent

        Item {
            width: menuColumn.width
            height: 9

            PanelSeparator {
                config: root.config
                horizontalInset: 6
                anchors.verticalCenter: parent.verticalCenter
            }
        }
    }

    Component {
        id: menuItemComponent

        Item {
            id: row

            width: menuColumn.width
            height: 34
            opacity: entry.enabled ? 1.0 : 0.45
            readonly property bool highlighted: rowMouse.containsMouse && entry.enabled

            Rectangle {
                anchors.fill: parent
                radius: 4
                color: row.highlighted ? root.config.selectionBackground : "transparent"
            }

            Item {
                id: leading

                anchors.left: parent.left
                anchors.leftMargin: 8
                anchors.verticalCenter: parent.verticalCenter

                width: 18
                height: 18

                IconImage {
                    anchors.fill: parent
                    visible: entry.icon !== ""
                    source: entry.icon
                }

                Text {
                    anchors.centerIn: parent
                    visible: entry.icon === "" && entry.buttonType !== QsMenuButtonType.None
                    color: row.highlighted ? root.config.selectionForeground : root.config.selectionBackground
                    font.pointSize: root.config.textSizeMedium
                    text: entry.checkState === Qt.Checked ? "✓" : ""
                }
            }

            Text {
                renderType: Text.NativeRendering
                anchors.left: leading.right
                anchors.leftMargin: 8
                anchors.right: arrow.left
                anchors.rightMargin: 8
                anchors.verticalCenter: parent.verticalCenter

                color: row.highlighted ? root.config.selectionForeground : root.config.fg
                font.pointSize: root.config.textSizeMedium
                elide: Text.ElideRight
                text: entry.text
            }

            Text {
                id: arrow

                anchors.right: parent.right
                anchors.rightMargin: 8
                anchors.verticalCenter: parent.verticalCenter

                visible: entry.hasChildren
                color: row.highlighted ? root.config.selectionForeground : root.config.muted
                font.family: root.config.iconFontFamily
                font.pointSize: root.config.iconSize
                text: "󰅂"
            }

            // Open nested menus or trigger the selected tray action.
            MouseArea {
                id: rowMouse

                anchors.fill: parent
                hoverEnabled: true
                enabled: entry.enabled
                cursorShape: entry.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor

                onClicked: {
                    if (entry.hasChildren) {
                        root.openSubmenu(entry);
                    } else {
                        entry.triggered();
                        root.popupManager.closeHost("trayMenu");
                    }
                }
            }
        }
    }
}
