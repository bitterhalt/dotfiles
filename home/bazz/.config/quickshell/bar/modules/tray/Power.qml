import QtQuick

Item {
    id: root

    required property var config
    required property var barWindow
    required property var powerMenu

    width: 24
    height: barWindow.height

    Text {
        anchors.centerIn: parent
        color: root.config.fg
        font.family: root.config.iconFontFamily
        font.pointSize: root.config.iconSize
        text: "󰐥"
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: Qt.PointingHandCursor
        onClicked: root.powerMenu.togglePower(root.barWindow.screen)
    }
}
