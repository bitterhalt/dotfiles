pragma ComponentBehavior: Bound

import "../../components"
import QtQuick

// Footer: power actions, the Yes/No confirmation that replaces them for
// destructive actions, the status line, and the help toggle.
Item {
    id: root

    required property var config
    property var powerActions: []
    property string pendingPower: ""
    property string statusText: ""
    property bool statusIsError: false
    property bool helpOpen: false

    signal powerRequested(string action)
    signal confirmRequested
    signal cancelRequested
    signal helpToggled

    width: parent ? parent.width : 0
    height: footerKeys.implicitHeight + config.panelPadding * 2

    // Same muted/hover treatment as the bar popup scan buttons.
    component FooterButton: ShellButton {
        config: root.config
        quiet: true
    }

    PanelSeparator {
        config: root.config
        horizontalInset: root.config.panelPadding
        anchors.top: parent.top
    }

    Row {
        id: powerButtons

        anchors.left: parent.left
        anchors.leftMargin: root.config.panelPadding
        anchors.verticalCenter: parent.verticalCenter
        spacing: root.config.spacingControl
        visible: root.pendingPower === "" && root.statusText === ""

        Repeater {
            model: root.powerActions

            delegate: FooterButton {
                required property var modelData

                text: modelData.label
                onClicked: root.powerRequested(modelData.id)
            }
        }
    }

    Row {
        id: confirmButtons

        anchors.left: parent.left
        anchors.leftMargin: root.config.panelPadding
        anchors.verticalCenter: parent.verticalCenter
        spacing: root.config.spacingControl
        visible: root.pendingPower !== ""

        FooterButton {
            text: "[Y]es"
            onClicked: root.confirmRequested()
        }

        FooterButton {
            text: "[N]o"
            onClicked: root.cancelRequested()
        }
    }

    Text {
        id: footerStatus

        renderType: Text.NativeRendering
        anchors.left: parent.left
        anchors.leftMargin: root.config.panelPadding
        anchors.right: footerKeys.left
        anchors.rightMargin: root.config.spacingControl
        anchors.verticalCenter: parent.verticalCenter
        visible: root.pendingPower === "" && root.statusText !== ""
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
