import QtQuick
import Quickshell

Item {
    id: root

    required property var config
    required property var notificationService
    readonly property int popupWidth: 360
    readonly property int popupMinHeight: 320
    readonly property int popupMaxHeight: 650
    readonly property int popupPadding: 12
    readonly property int itemSpacing: 8

    implicitWidth: popupWidth
    implicitHeight: Math.min(Math.max(notificationService.notificationCount > 0 ? 72 + notificationService.notificationCount * 100 : 118, popupMinHeight), popupMaxHeight)
    width: implicitWidth
    height: implicitHeight


    Rectangle {
        anchors.fill: parent
        color: config.surface
        border.color: config.borderColor
        border.width: 1
        radius: config.popupRadius

        Column {
            anchors.fill: parent
            anchors.margins: root.popupPadding
            spacing: 10

            Item {
                width: parent.width
                height: 32

                Text {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    color: config.fg
                    font.pointSize: config.fontSize(1.05)
                    font.weight: Font.DemiBold
                    text: "Notifications"
                }

                Row {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 12

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        color: notificationService.dnd ? config.accent : config.muted
                        font.pointSize: config.fontSize(0.82)
                        text: "Do Not Disturb"
                    }

                    Rectangle {
                        width: 34
                        height: 18
                        radius: 9
                        color: notificationService.dnd ? config.accent : config.borderColor

                        Rectangle {
                            width: 14
                            height: 14
                            radius: 7
                            y: 2
                            x: notificationService.dnd ? 18 : 2
                            color: config.fg
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: notificationService.toggleDnd()
                        }

                    }

                }

            }

            Rectangle {
                width: parent.width
                height: 1
                color: config.borderColor
            }

            Item {
                width: parent.width
                height: parent.height - 76

                Text {
                    anchors.centerIn: parent
                    visible: notificationService.notificationCount === 0
                    color: config.muted
                    font.pointSize: config.fontSize(0.9)
                    text: "No notifications"
                }

                ListView {
                    id: list

                    anchors.fill: parent
                    visible: notificationService.notificationCount > 0
                    clip: true
                    spacing: root.itemSpacing
                    model: notificationService.notifications.slice().reverse()

                    delegate: NotificationCard {
                        required property var modelData

                        width: ListView.view.width
                        config: root.config
                        notification: modelData
                        notificationService: root.notificationService
                    }

                }

            }

            Item {
                width: parent.width
                height: 24
                visible: notificationService.notificationCount > 0

                Text {
                    anchors.centerIn: parent
                    color: clearMouse.containsMouse ? config.fg : config.muted
                    font.pointSize: config.fontSize(0.82)
                    text: "Clear all"
                }

                MouseArea {
                    id: clearMouse

                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: notificationService.clearAll()
                }

            }

        }

    }

}
