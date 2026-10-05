import QtQuick

Item {
    id: root

    required property var config
    required property var row
    property string icon: ""

    signal activated()

    implicitHeight: 38

    Rectangle {
        anchors.fill: parent
        radius: 3
        color: rowMouse.containsMouse ? root.config.borderColor : "transparent"
    }

    Text {
        x: 6
        anchors.verticalCenter: parent.verticalCenter
        color: root.row.active ? root.config.accent : root.config.fg
        font.family: root.config.iconFontFamily
        font.pointSize: root.config.iconSize
        text: root.row.active ? "󰄬" : root.icon
    }

    Text {
        x: 36
        width: parent.width - 80
        anchors.verticalCenter: parent.verticalCenter
        color: root.config.fg
        font.pointSize: root.config.fontSize(0.88)
        font.weight: root.row.active ? Font.DemiBold : Font.Normal
        elide: Text.ElideRight
        text: root.row.name
    }

    Text {
        anchors.right: parent.right
        anchors.rightMargin: 6
        anchors.verticalCenter: parent.verticalCenter
        visible: root.row.active
        color: root.config.muted
        font.pointSize: root.config.fontSize(0.72)
        text: "Default"
    }

    MouseArea {
        id: rowMouse

        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.activated()
    }

}
