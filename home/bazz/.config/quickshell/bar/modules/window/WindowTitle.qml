import QtQuick

Item {
    id: root

    required property var config
    required property var barWindow
    required property var niri

    implicitWidth: Math.min(windowTitle.implicitWidth + 20 + config.workspaceTitleGap, 560)
    height: barWindow.height

    Text {
        id: windowTitle

        anchors.left: parent.left
        anchors.leftMargin: config.workspaceTitleGap
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width - 10 - config.workspaceTitleGap
        color: config.fg
        font.pointSize: config.fontSize(1)
        elide: Text.ElideRight
        text: {
            const win = niri.windows[niri.focusedWindowId];
            return win && win.title ? win.title : "";
        }
    }

}
