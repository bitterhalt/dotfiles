import QtQuick

Item {
    id: control

    required property var config
    property bool checked: false

    signal toggled()

    implicitWidth: 32
    implicitHeight: 18

    Rectangle {
        anchors.fill: parent
        radius: height / 2
        color: control.checked ? control.config.accent : control.config.borderColor
    }

    Rectangle {
        width: 14
        height: 14
        radius: 7
        y: 2
        x: control.checked ? 16 : 2
        color: control.config.fg
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: control.toggled()
    }

}
