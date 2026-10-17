import QtQuick

Item {
    id: root

    required property var config
    required property var row
    property bool selected: false

    signal activated()
    signal focused()

    function strengthIcon(strength) {
        if (strength >= 0.75)
            return "󰤨";

        if (strength >= 0.5)
            return "󰤥";

        if (strength >= 0.25)
            return "󰤢";

        return "󰤟";
    }

    implicitHeight: 40

    Rectangle {
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.topMargin: 3
        anchors.bottomMargin: 3
        width: 2
        radius: 1
        color: root.config.accent
        visible: root.selected
    }

    Item {
        x: 4
        width: 28
        height: parent.height

        Text {
            anchors.centerIn: parent
            color: rowMouse.containsMouse ? Qt.lighter(root.config.fg, 1.15) : root.config.fg
            font.family: root.config.iconFontFamily
            font.pointSize: root.config.iconSize
            text: root.strengthIcon(root.row.strength)
        }
    }

    Text {
        renderType: Text.NativeRendering
        x: 38
        width: parent.width - 44
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
        cursorShape: root.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
        onEntered: root.focused()
        onClicked: {
            root.focused();
            root.activated();
        }
    }

}
