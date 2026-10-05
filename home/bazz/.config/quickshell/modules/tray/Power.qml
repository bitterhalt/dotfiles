import QtQuick
import Quickshell

Item {
    id: root

    required property var config
    required property var barWindow
    required property var popupManager

    width: 24
    height: barWindow.height

    Text {
        anchors.centerIn: parent
        color: config.fg
        font.family: config.iconFontFamily
        font.pointSize: config.iconSize
        text: "󰐥"
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: Qt.PointingHandCursor

        onClicked: mouse => {
            if (mouse.button === Qt.LeftButton) {
                powerMenu.confirmAction = ""
                popupManager.toggle(powerMenu)
            } else {
                config.run("foot -a pop-upgrade -e sys_upgrade")
            }
        }
    }

    PopupWindow {
        id: powerMenu

        property string confirmAction: ""

        anchor {
            item: root
            edges: Edges.Bottom | Edges.Right
            gravity: Edges.Bottom | Edges.Left
            margins.bottom: -config.popupGap
            margins.right: config.popupGap
        }

        implicitWidth: 160
        implicitHeight: menuColumn.implicitHeight + 12
        visible: false
        grabFocus: true
        color: "transparent"

        onVisibleChanged: {
            if (!visible)
                confirmAction = ""
        }

        Rectangle {
            anchors.fill: parent
            color: config.surface
            border.color: config.borderColor
            border.width: 1
            radius: config.popupRadius

            Column {
                id: menuColumn

                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: 6
                spacing: 2

                PowerRow {
                    text: "Lock"
                    visible: powerMenu.confirmAction === ""
                    onActivated: {
                        powerMenu.visible = false
                        config.run("swaylock -C ~/.cache/wal/colors-swaylock")
                    }
                }

                PowerRow {
                    text: "Exit"
                    visible: powerMenu.confirmAction === ""
                    onActivated: {
                        powerMenu.visible = false
                        config.run("niri msg action quit")
                    }
                }

                PowerRow {
                    text: "Sleep"
                    visible: powerMenu.confirmAction === ""
                    onActivated: {
                        powerMenu.visible = false
                        config.run("systemctl suspend")
                    }
                }

                PowerRow {
                    text: "Reboot"
                    visible: powerMenu.confirmAction === ""
                    onActivated: powerMenu.confirmAction = "reboot"
                }

                PowerRow {
                    text: "Shutdown"
                    visible: powerMenu.confirmAction === ""
                    onActivated: powerMenu.confirmAction = "shutdown"
                }

                Text {
                    width: parent.width
                    height: powerMenu.confirmAction !== "" ? 34 : 0
                    visible: height > 0

                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    color: config.fg
                    font.pointSize: config.fontSize(0.95)
                    font.weight: Font.DemiBold
                    text: powerMenu.confirmAction === "reboot"
                        ? "Reboot?"
                        : "Shutdown?"
                }

                Row {
                    width: parent.width
                    height: powerMenu.confirmAction !== "" ? 34 : 0
                    visible: height > 0
                    spacing: 4

                    PowerRow {
                        width: (parent.width - 4) / 2
                        text: "No"
                        centered: true
                        onActivated: powerMenu.confirmAction = ""
                    }

                    PowerRow {
                        width: (parent.width - 4) / 2
                        text: "Yes"
                        centered: true
                        accentHover: true

                        onActivated: {
                            const action = powerMenu.confirmAction
                            powerMenu.visible = false
                            powerMenu.confirmAction = ""

                            if (action === "reboot")
                                config.run("systemctl reboot")
                            else if (action === "shutdown")
                                config.run("systemctl poweroff")
                        }
                    }
                }
            }
        }
    }

    component PowerRow: Item {
        id: row

        property string text: ""
        property bool centered: false
        property bool accentHover: false

        signal activated()

        width: parent ? parent.width : 0
        height: visible ? 34 : 0

        Rectangle {
            anchors.fill: parent
            radius: 3
            color: rowMouse.containsMouse
                ? (row.accentHover ? config.accent : config.borderColor)
                : "transparent"
        }

        Text {
            anchors.left: row.centered ? undefined : parent.left
            anchors.leftMargin: row.centered ? 0 : 10
            anchors.centerIn: row.centered ? parent : undefined
            anchors.verticalCenter: row.centered ? undefined : parent.verticalCenter

            color: config.fg
            font.pointSize: config.fontSize(0.95)
            text: row.text
        }

        MouseArea {
            id: rowMouse

            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: row.activated()
        }
    }
}
