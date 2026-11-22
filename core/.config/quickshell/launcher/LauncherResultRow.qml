import QtQuick
import Quickshell
import Quickshell.Widgets
import "Dmenu.js" as Dmenu

// Rendering only. The launcher owns selection and activation.
Item {
    id: root

    required property var config
    required property var entry
    property bool selected: false

    Rectangle {
        anchors.fill: parent
        radius: 4
        color: root.selected ? root.config.muted : "transparent"
    }

    IconImage {
        anchors.left: parent.left
        anchors.leftMargin: root.config.panelPadding
        anchors.verticalCenter: parent.verticalCenter
        implicitSize: 22
        visible: source.toString() !== ""
        source: root.entry.icon ? Quickshell.iconPath(root.entry.icon, true) : ""
    }

    Text {
        anchors.left: parent.left
        anchors.leftMargin: root.config.panelPadding
        anchors.verticalCenter: parent.verticalCenter
        visible: root.entry.type === "calculator" || root.entry.type === "file" || root.entry.type === "emoji"
        color: root.selected ? root.config.selectionForeground : root.config.selectionBackground
        font.family: root.entry.type === "emoji" ? root.config.textFontFamily : root.config.iconFontFamily
        font.pointSize: root.entry.type === "emoji" ? root.config.iconSize * 1.5 : root.config.iconSize
        text: root.entry.type === "emoji" ? root.entry.emoji : root.entry.type === "file" ? "󰈔" : "󰃬"
    }

    Column {
        anchors.left: parent.left
        anchors.leftMargin: root.entry.type === "dmenu" ? root.config.panelPadding : root.config.panelPadding + 26 + root.config.spacingControl
        anchors.right: parent.right
        anchors.rightMargin: root.config.panelPadding
        anchors.verticalCenter: parent.verticalCenter
        spacing: 0 // Keep the paired title/status lines compact, like device rows.

        Text {
            objectName: "launcherResultTitle"
            renderType: Text.NativeRendering
            width: parent.width
            color: root.selected ? root.config.selectionForeground : root.config.fg
            font.pointSize: root.config.textSizeMedium
            font.family: root.config.textFontFamily
            elide: Text.ElideRight
            textFormat: root.entry.type === "dmenu" ? Text.RichText : Text.AutoText
            text: root.entry.type === "dmenu" ? Dmenu.richTextWithSymbols(root.entry.text, root.config.iconFontFamily) : root.entry.text
        }
    }
}
