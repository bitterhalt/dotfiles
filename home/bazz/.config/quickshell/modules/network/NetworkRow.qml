import QtQuick

Item {
    id: root

    required property var config
    required property var row

    signal activated()

    implicitHeight: 40

    Rectangle {
        anchors.fill: parent
        radius: 3
        color: rowMouse.containsMouse
            ? root.config.borderColor
            : "transparent"
    }

    Text {
        x: 6
        anchors.verticalCenter: parent.verticalCenter
        color: root.config.fg
        font.family: root.config.iconFontFamily
        font.pointSize: root.config.iconSize
        text: strengthIcon(root.row.strength)
    }

    Text {
        x: 36
        width: parent.width - 42
        anchors.verticalCenter: parent.verticalCenter
        color: root.config.fg
        font.pointSize: root.config.fontSize(0.92)
        elide: Text.ElideRight
        text: root.row.ssid
    }

    MouseArea {
        id: rowMouse
        anchors.fill: parent
        hoverEnabled: true
        enabled: root.enabled
        cursorShape: root.enabled
            ? Qt.PointingHandCursor
            : Qt.ArrowCursor
        onClicked: root.activated()
    }

    function strengthIcon(strength) {
        if (strength >= 0.75)
            return "󰤨"
        if (strength >= 0.50)
            return "󰤥"
        if (strength >= 0.25)
            return "󰤢"
        return "󰤟"
    }
}
