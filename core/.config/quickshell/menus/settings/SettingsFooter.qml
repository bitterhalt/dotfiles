pragma ComponentBehavior: Bound

import "../../components"
import QtQuick

// Footer like the clipboard and wallpaper menus: status or hint on the
// left, the help toggle on the right, under an inset separator.
Item {
    id: root

    required property var config
    property string statusText: ""
    property bool statusIsError: false
    property bool helpOpen: false

    signal helpToggled

    width: parent ? parent.width : 0
    height: footerKeys.implicitHeight + config.panelPadding * 2

    PanelSeparator {
        config: root.config
        horizontalInset: root.config.panelPadding
        anchors.top: parent.top
    }

    Text {
        id: footerStatus

        renderType: Text.NativeRendering
        anchors.left: parent.left
        anchors.leftMargin: root.config.panelPadding
        anchors.right: footerKeys.left
        anchors.rightMargin: root.config.spacingControl
        anchors.verticalCenter: parent.verticalCenter
        visible: root.statusText !== ""
        elide: Text.ElideRight
        color: root.statusIsError ? root.config.urgent : root.config.muted
        font.pointSize: root.config.textSizeSmall
        text: root.statusText
    }

    Text {
        id: footerKeys

        renderType: Text.NativeRendering
        anchors.right: parent.right
        anchors.rightMargin: root.config.panelPadding
        anchors.verticalCenter: parent.verticalCenter
        color: footerKeyMouse.containsMouse ? root.config.fg : root.config.muted
        font.pointSize: root.config.textSizeSmall
        text: root.helpOpen ? "? Close help" : "? Help"

        MouseArea {
            id: footerKeyMouse

            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.helpToggled()
        }
    }
}
