import QtQuick
import QtQuick.Controls.Basic

TextField {
    id: root

    required property var config
    // Solid card fill derived from the panel background and the current accent.
    property color surfaceColor: Qt.tint(config.bg, Qt.alpha(config.selectionBackground, 0.10))
    property color outlineColor: config.border
    property real cornerRadius: 4

    implicitHeight: 32
    renderType: Text.NativeRendering
    color: config.fg
    placeholderTextColor: config.muted
    selectionColor: config.selectionBackground
    selectedTextColor: config.selectionForeground
    font.pointSize: config.textSizeNormal
    selectByMouse: true

    background: Rectangle {
        color: root.surfaceColor
        radius: root.cornerRadius
        border.width: 1
        border.color: root.activeFocus ? root.config.selectionBackground : root.outlineColor
    }
}
