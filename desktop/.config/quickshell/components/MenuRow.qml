import QtQuick

// Shared highlighted row used by the main and recorder menus.
Item {
    id: root

    required property var config

    property bool selected: false
    property string icon: ""
    property string label: ""
    property string keyHint: ""
    property bool submenu: false
    property bool accentIcon: true
    property real iconInset: config.spacingControl
    property real hintInset: config.spacingControl
    property real iconScale: 1

    implicitHeight: 32
    height: visible ? implicitHeight : 0
    width: parent ? parent.width : 0

    Rectangle {
        anchors.fill: parent
        radius: 4
        color: root.selected ? root.config.selectionBackground : "transparent"
    }

    Text {
        id: rowIcon

        anchors.left: parent.left
        anchors.leftMargin: root.iconInset
        anchors.verticalCenter: parent.verticalCenter
        width: 22
        horizontalAlignment: Text.AlignHCenter
        color: root.selected ? root.config.selectionForeground : root.accentIcon ? root.config.selectionBackground : root.config.fg
        font.family: root.config.iconFontFamily
        font.pointSize: root.config.iconSize * root.iconScale
        text: root.icon
    }

    Text {
        renderType: Text.NativeRendering
        anchors.left: rowIcon.right
        anchors.leftMargin: root.config.spacingControl
        anchors.right: submenuIcon.visible ? submenuIcon.left : keyHint.left
        anchors.rightMargin: root.config.spacingControl
        anchors.verticalCenter: parent.verticalCenter
        color: root.selected ? root.config.selectionForeground : root.config.fg
        font.pointSize: root.config.textSizeMedium
        font.weight: Font.Medium
        elide: Text.ElideRight
        text: root.label
        textFormat: Text.PlainText
    }

    Text {
        id: submenuIcon

        visible: root.submenu
        anchors.right: keyHint.left
        anchors.rightMargin: root.config.spacingControl
        anchors.verticalCenter: parent.verticalCenter
        color: root.selected ? root.config.selectionForeground : root.config.muted
        font.family: root.config.iconFontFamily
        font.pointSize: root.config.iconSize
        text: "󰅂"
    }

    Text {
        id: keyHint

        renderType: Text.NativeRendering
        anchors.right: parent.right
        anchors.rightMargin: root.hintInset
        anchors.verticalCenter: parent.verticalCenter
        width: 21
        horizontalAlignment: Text.AlignHCenter
        color: root.selected ? root.config.selectionForeground : root.config.fg
        font.pointSize: root.config.textSizeSmall
        text: root.keyHint
    }
}
