import QtQuick

Item {
    id: control

    required property var config
    property bool checked: false

    signal toggled

    implicitWidth: 32
    implicitHeight: 18

    // Track and thumb; checked controls the thumb position and track fill.
    Rectangle {
        anchors.fill: parent
        radius: height / 2
        color: control.config.selectionBackground
    }

    Rectangle {
        width: 14
        height: 14
        radius: 7
        y: 2
        x: control.checked ? 16 : 2
        color: control.config.selectionForeground
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: control.toggled()
    }
}
