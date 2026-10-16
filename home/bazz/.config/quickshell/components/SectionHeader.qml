import QtQuick

Text {
    renderType: Text.NativeRendering
    required property var config

    color: config.muted
    font.pointSize: config.fontSize(0.77)
    font.weight: Font.DemiBold
    font.letterSpacing: 0.4
}
