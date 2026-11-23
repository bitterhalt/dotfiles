import QtQuick

Item {
    id: control

    required property var config
    property bool checked: false
    // Opt in to Tab focus; clicking always focuses the switch.
    property bool keyboard: false

    signal toggled

    implicitWidth: 32
    implicitHeight: 18
    activeFocusOnTab: keyboard
    Keys.onSpacePressed: control.toggled()
    Keys.onReturnPressed: control.toggled()

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

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            control.forceActiveFocus();
            control.toggled();
        }
    }
}
