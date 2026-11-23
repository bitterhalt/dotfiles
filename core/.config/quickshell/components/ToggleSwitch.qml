import QtQuick

Item {
    id: control

    required property var config
    property bool checked: false
    // Opt in to Tab focus and Space/Enter toggling.
    property bool keyboard: false

    signal toggled

    implicitWidth: 32
    implicitHeight: 18
    activeFocusOnTab: keyboard
    Keys.onSpacePressed: if (keyboard)
        toggled()
    Keys.onReturnPressed: if (keyboard)
        toggled()

    // Track and thumb; checked controls the thumb position and track fill.
    Rectangle {
        anchors.fill: parent
        radius: height / 2
        color: control.checked ? control.config.selectionBackground : control.config.border
    }

    Rectangle {
        width: 14
        height: 14
        radius: 7
        y: 2
        x: control.checked ? 16 : 2
        color: control.checked ? control.config.selectionForeground : control.config.muted
    }

    Rectangle {
        anchors.fill: parent
        anchors.margins: -3
        radius: height / 2
        color: "transparent"
        visible: control.keyboard && control.activeFocus
        border.width: 1
        border.color: control.config.selectionBackground
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: control.toggled()
    }
}
