import QtQuick
import Quickshell
import Quickshell.Wayland

Item {
    id: root

    required property var config
    required property var barWindow

    visible: false

    property string state: ""

    function show(newState): void {
        state = newState
        toast.visible = true
        toastTimer.restart()
    }

    PanelWindow {
        id: toast

        screen: root.barWindow.screen

        anchors {
            top: true
            left: true
            right: true
        }

        margins.top: root.config.popupGap

        WlrLayershell.layer: WlrLayer.Overlay

        exclusiveZone: 0
        implicitHeight: 62
        visible: false
        color: "transparent"
        mask: Region {}

        Rectangle {
            width: 160
            height: parent.height
            anchors.horizontalCenter: parent.horizontalCenter

            radius: root.config.popupRadius
            color: root.config.surface
            border.color: root.config.borderColor
            border.width: 1

            Item {
                id: iconBox

                anchors.left: parent.left
                anchors.leftMargin: 12
                anchors.verticalCenter: parent.verticalCenter

                width: 34
                height: 34

                Text {
                    anchors.centerIn: parent
                    color: root.config.accent
                    font.family: root.config.iconFontFamily
                    font.pointSize: root.config.iconSize
                    text: "󱐋"
                }
            }

            Column {
                anchors.left: iconBox.right
                anchors.leftMargin: 10
                anchors.right: parent.right
                anchors.rightMargin: 12
                anchors.verticalCenter: parent.verticalCenter
                spacing: 1

                Text {
                    width: parent.width
                    color: root.config.fg
                    font.pointSize: root.config.fontSize(0.92)
                    font.weight: Font.DemiBold
                    elide: Text.ElideRight
                    text: "Idle timer"
                }

                Text {
                    color: root.config.muted
                    font.pointSize: root.config.fontSize(0.80)
                    text: root.state
                }
            }
        }
    }

    Timer {
        id: toastTimer

        interval: 5000
        repeat: false
        onTriggered: toast.visible = false
    }
}
