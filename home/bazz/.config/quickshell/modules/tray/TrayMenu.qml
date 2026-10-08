import QtQuick
import Quickshell
import Quickshell.Widgets

Item {
    id: root

    required property var config
    required property var menuHandle
    required property var popupManager

    property var currentMenu: menuHandle
    property var menuStack: []

    function reset(): void {
        currentMenu = menuHandle
        menuStack = []
    }

    function openSubmenu(entry): void {
        menuStack = menuStack.concat([currentMenu])
        currentMenu = entry
    }

    function goBack(): void {
        if (menuStack.length === 0)
            return

        currentMenu = menuStack[menuStack.length - 1]
        menuStack = menuStack.slice(0, -1)
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

    Rectangle {
        anchors.fill: parent

        color: root.config.surface
        border.color: root.config.borderColor
        border.width: 1
        radius: root.config.popupRadius

        Column {
            id: menuColumn

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 6
            spacing: 2

            Item {
                width: parent.width
                height: root.menuStack.length > 0 ? 34 : 0
                visible: height > 0

                Rectangle {
                    anchors.fill: parent
                    radius: 3
                    color: backMouse.containsMouse
                        ? root.config.borderColor
                        : "transparent"
                }

                Text {
                    anchors.left: parent.left
                    anchors.leftMargin: 10
                    anchors.verticalCenter: parent.verticalCenter

                    color: root.config.muted
                    font.pointSize: root.config.fontSize(0.9)
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

            Repeater {
                model: opener.children

                delegate: Loader {
                    required property var modelData

                    width: menuColumn.width

                    sourceComponent: modelData.isSeparator
                        ? separatorComponent
                        : menuItemComponent

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

            Rectangle {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.leftMargin: 6
                anchors.rightMargin: 6
                anchors.verticalCenter: parent.verticalCenter

                height: 1
                color: root.config.borderColor
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

            Rectangle {
                anchors.fill: parent
                radius: 3
                color: rowMouse.containsMouse && entry.enabled
                    ? root.config.borderColor
                    : "transparent"
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
                    visible: entry.icon === ""
                        && entry.buttonType !== QsMenuButtonType.None
                    color: root.config.accent
                    font.pointSize: root.config.fontSize(0.9)
                    text: entry.checkState === Qt.Checked ? "✓" : ""
                }
            }

            Text {
                anchors.left: leading.right
                anchors.leftMargin: 8
                anchors.right: arrow.left
                anchors.rightMargin: 8
                anchors.verticalCenter: parent.verticalCenter

                color: root.config.fg
                font.pointSize: root.config.fontSize(0.92)
                elide: Text.ElideRight
                text: entry.text
            }

            Text {
                id: arrow

                anchors.right: parent.right
                anchors.rightMargin: 8
                anchors.verticalCenter: parent.verticalCenter

                visible: entry.hasChildren
                color: root.config.muted
                font.family: root.config.iconFontFamily
                font.pointSize: root.config.iconSize
                text: "󰅂"
            }

            MouseArea {
                id: rowMouse

                anchors.fill: parent
                hoverEnabled: true
                enabled: entry.enabled
                cursorShape: entry.enabled
                    ? Qt.PointingHandCursor
                    : Qt.ArrowCursor

                onClicked: {
                    if (entry.hasChildren) {
                        root.openSubmenu(entry)
                    } else {
                        entry.triggered()
                        root.popupManager.closeHost("trayMenu")
                    }
                }
            }
        }
    }
}
