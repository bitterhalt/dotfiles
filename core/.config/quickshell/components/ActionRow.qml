import QtQuick

// A button with a trailing shortcut hint; routing and shortcuts belong to its owner.
ShellButton {
    id: root

    property string shortcutText: ""

    implicitWidth: label.implicitWidth + hint.implicitWidth + 28
    outlined: true

    contentItem: Item {
        implicitHeight: Math.max(label.implicitHeight, hint.implicitHeight)
        Text {
            id: label

            anchors.left: parent.left
            anchors.leftMargin: 10
            anchors.right: hint.left
            anchors.rightMargin: 8
            anchors.verticalCenter: parent.verticalCenter
            renderType: Text.NativeRendering
            textFormat: Text.PlainText
            color: !root.enabled ? root.config.muted : root.visuallyHighlighted ? root.config.selectionForeground : root.destructive ? root.config.urgent : root.config.fg
            font: root.font
            elide: Text.ElideRight
            text: root.text
        }
        Text {
            id: hint

            anchors.right: parent.right
            anchors.rightMargin: 10
            anchors.verticalCenter: parent.verticalCenter
            renderType: Text.NativeRendering
            textFormat: Text.PlainText
            color: root.visuallyHighlighted ? root.config.selectionForeground : root.config.muted
            font.pointSize: root.config.textSizeSmall
            text: root.shortcutText
        }
    }
}
