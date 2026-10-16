import QtQuick
import QtQuick.Controls.Basic

Button {
    id: root

    required property var config
    property bool iconOnly: false

    implicitHeight: 30
    implicitWidth: label.implicitWidth + 20
    focusPolicy: Qt.StrongFocus
    padding: 8
    contentItem: Text {
        id: label

        renderType: root.iconOnly ? Text.QtRendering : Text.NativeRendering
        text: root.text
        font.pointSize: root.config.fontSize(0.88)
        color: root.enabled ? root.config.fg : root.config.muted
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight
    }
    background: Rectangle {
        radius: 4
        color: root.down || root.hovered || root.activeFocus
            ? root.config.borderColor : "transparent"
        border.width: root.activeFocus ? 1 : 0
        border.color: root.config.accent
    }
}
