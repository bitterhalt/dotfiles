import QtQuick

Item {
    id: root

    required property var config
    required property var entry
    property bool selected: false

    Rectangle {
        anchors.fill: parent
        radius: 5
        color: root.selected ? root.config.selectionBackground : "transparent"
    }

    Text {
        anchors.left: parent.left
        anchors.leftMargin: 10
        anchors.verticalCenter: parent.verticalCenter
        color: root.selected ? root.config.selectionForeground : root.config.selectionBackground
        font.family: root.config.iconFontFamily
        font.pointSize: root.config.iconSize
        text: root.entry.isImage ? "󰋩" : "󰉢"
    }

    Text {
        objectName: "clipboardHistoryLabel"
        renderType: Text.NativeRendering
        anchors.left: parent.left
        anchors.leftMargin: 42
        anchors.right: parent.right
        anchors.rightMargin: 8
        anchors.verticalCenter: parent.verticalCenter
        color: root.selected ? root.config.selectionForeground : root.config.fg
        font.pointSize: root.config.textSizeMedium
        text: root.entry.isImage ? "Image" : "Text"
    }
}
