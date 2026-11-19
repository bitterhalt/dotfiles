import QtQuick
import QtQuick.Controls.Basic

Button {
    id: root

    required property var config
    property bool compact: false
    property bool iconOnly: false
    property bool tinted: false
    property bool filled: false
    property bool outlined: false
    property bool destructive: false
    property bool selected: false
    readonly property bool visuallyHighlighted: enabled && (down || hovered || activeFocus || selected || filled)
    property color foregroundColor: !enabled ? config.muted : visuallyHighlighted ? config.selectionForeground : destructive ? config.urgent : config.fg
    property color outlineColor: config.selectionBackground
    property real cornerRadius: 4

    implicitHeight: Math.max(compact ? 22 : 28, implicitContentHeight + topPadding + bottomPadding)
    implicitWidth: label.implicitWidth + leftPadding + rightPadding
    focusPolicy: Qt.StrongFocus
    hoverEnabled: true
    padding: compact ? 2 : 4
    leftPadding: compact ? 6 : 8
    rightPadding: compact ? 6 : 8
    font.pointSize: compact ? config.textSizeSmall : config.textSizeMedium

    contentItem: Text {
        id: label

        renderType: root.iconOnly ? Text.QtRendering : Text.NativeRendering
        textFormat: Text.PlainText
        text: root.text
        font: root.font
        color: root.foregroundColor
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight
    }

    background: Rectangle {
        radius: root.cornerRadius
        color: root.visuallyHighlighted ? root.config.selectionBackground : root.tinted ? Qt.alpha(root.config.selectionBackground, 0.12) : "transparent"
        border.width: root.outlined || root.activeFocus ? 1 : 0
        border.color: root.activeFocus ? root.config.selectionBackground : root.outlineColor
    }
}
