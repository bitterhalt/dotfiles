import QtQuick
import Quickshell
import Quickshell.Widgets

Rectangle {
    id: root

    required property var config
    property var notification: null
    property var notificationService: null
    property bool compact: false
    property bool showClose: true
    property bool dismissOnClick: false
    readonly property int appIconSize: 36
    readonly property bool hasImage: notification && notification.image && notification.image !== ""
    readonly property int actionCount: !compact && notification && notification.actions ? Math.min(notification.actions.length, 2) : 0

    function iconSource(icon) {
        if (!icon)
            return "";

        if (icon.startsWith("/") || icon.startsWith("file:"))
            return icon;

        return Quickshell.iconPath(icon, true);
    }

    implicitHeight: {
        let h = compact ? 84 : 92;
        if (actionCount > 0)
            h += 34;

        return h;
    }
    radius: config.popupRadius
    color: config.bg
    border.color: config.borderColor
    border.width: 1

    HoverHandler {
        id: cardHover
    }

    Item {
        id: imageBox

        anchors.right: parent.right
        anchors.rightMargin: 22
        y: root.compact ? Math.round((parent.height - height) / 2) : 30
        width: root.appIconSize
        height: root.appIconSize

        Rectangle {
            anchors.fill: parent
            visible: root.hasImage
            radius: width / 2
            clip: true
            color: config.surface

            Image {
                anchors.fill: parent
                source: root.notification ? root.notification.image : ""
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
            }

        }

        IconImage {
            id: appIcon

            anchors.fill: parent
            visible: !root.hasImage && source.toString() !== ""
            source: root.iconSource(root.notification ? root.notification.appIcon : "")
        }

        Text {
            anchors.centerIn: parent
            visible: !root.hasImage && !appIcon.visible
            color: config.muted
            font.family: config.iconFontFamily
            font.pointSize: config.iconSize
            text: "󰂚"
        }

    }

    Column {
        id: contentColumn

        anchors.left: parent.left
        anchors.leftMargin: 22
        anchors.right: imageBox.left
        anchors.rightMargin: 10
        anchors.top: parent.top
        anchors.topMargin: 10
        spacing: 2

        Text {
            width: parent.width
            color: config.muted
            font.pointSize: config.fontSize(0.78)
            elide: Text.ElideRight
            text: root.notification ? (root.notification.appName || "Notification") : ""
        }

        Text {
            width: parent.width
            color: config.fg
            font.pointSize: config.fontSize(0.96)
            font.weight: Font.DemiBold
            elide: Text.ElideRight
            text: root.notification ? (root.notification.summary || "") : ""
        }

        Text {
            width: parent.width
            visible: text.length > 0
            color: config.fg
            opacity: 0.85
            font.pointSize: config.fontSize(0.86)
            textFormat: Text.PlainText
            wrapMode: Text.Wrap
            maximumLineCount: root.compact ? 2 : 3
            elide: Text.ElideRight
            text: root.notification ? (root.notification.body || "") : ""
        }

    }

    Text {
        id: timeText

        visible: !root.compact
        anchors.right: closeButton.left
        anchors.rightMargin: 4
        anchors.top: parent.top
        anchors.topMargin: 10
        color: config.muted
        font.pointSize: config.fontSize(0.74)
        text: root.notificationService ? root.notificationService.timeLabel(root.notification) : ""
    }

    Item {
        id: closeButton

        anchors.right: parent.right
        anchors.rightMargin: 4
        anchors.top: parent.top
        anchors.topMargin: 4
        width: root.showClose ? 24 : 0
        height: 24
        visible: root.showClose
        opacity: root.compact || cardHover.hovered ? 1 : 0.45

        Text {
            anchors.centerIn: parent
            color: config.muted
            font.pointSize: config.fontSize(1)
            text: "×"
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                if (root.notification)
                    root.notification.dismiss();

            }
        }

    }

    MouseArea {
        anchors.fill: parent
        visible: root.dismissOnClick
        cursorShape: Qt.PointingHandCursor
        z: 10
        onClicked: {
            if (root.notification)
                root.notification.dismiss();

        }
    }

    Row {
        id: actionsRow

        visible: root.actionCount > 0
        anchors.left: parent.left
        anchors.leftMargin: 12
        anchors.right: parent.right
        anchors.rightMargin: 12
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 8
        spacing: 6

        Repeater {
            model: root.actionCount

            Rectangle {
                required property int index

                width: (actionsRow.width - 6 * (root.actionCount - 1)) / root.actionCount
                height: 26
                radius: 3
                color: actionMouse.containsMouse ? config.borderColor : config.surface

                Text {
                    anchors.centerIn: parent
                    width: parent.width - 12
                    horizontalAlignment: Text.AlignHCenter
                    elide: Text.ElideRight
                    color: config.fg
                    font.pointSize: config.fontSize(0.8)
                    text: root.notification ? root.notification.actions[index].text : ""
                }

                MouseArea {
                    id: actionMouse

                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (root.notification)
                            root.notification.actions[index].invoke();

                    }
                }

            }

        }

    }

}
