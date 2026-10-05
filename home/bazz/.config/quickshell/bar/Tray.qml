import QtQuick
import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Widgets

Item {
    id: root

    required property var config
    required property var barWindow
    required property var popupManager
    readonly property int revealDuration: 300
    property bool expanded: false
    property real revealProgress: expanded ? 1 : 0
    readonly property real revealExtent: trayItems.implicitWidth * revealProgress
    readonly property real revealSpacing: config.barModuleSpacing * revealProgress

    height: barWindow.height
    implicitWidth: expander.width + revealSpacing + revealExtent

    Item {
        id: expander

        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        width: 20
        height: barWindow.height

        Text {
            anchors.centerIn: parent
            color: config.fg
            opacity: 0.5
            font.family: config.iconFontFamily
            font.pointSize: config.iconSize
            text: "󰇙"
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: root.expanded = !root.expanded
        }

    }

    Item {
        id: trayClip

        x: expander.width + root.revealSpacing
        anchors.verticalCenter: parent.verticalCenter
        width: root.revealExtent
        height: barWindow.height
        clip: true

        Row {
            id: trayItems

            x: trayClip.width - implicitWidth
            anchors.verticalCenter: parent.verticalCenter
            spacing: config.barModuleSpacing

            Repeater {
                model: SystemTray.items

                Item {
                    required property var modelData

                    width: 20
                    height: barWindow.height

                    IconImage {
                        anchors.centerIn: parent
                        implicitSize: 16
                        source: modelData.icon
                    }

                    MouseArea {
                        anchors.fill: parent
                        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                        cursorShape: Qt.PointingHandCursor
                        onClicked: (mouse) => {
                            if (mouse.button === Qt.MiddleButton) {
                                parent.modelData.secondaryActivate();
                                return ;
                            }
                            if (mouse.button === Qt.RightButton || parent.modelData.onlyMenu) {
                                const pos = barWindow.itemPosition(parent);
                                parent.modelData.display(barWindow, pos.x, barWindow.height);
                                return ;
                            }
                            parent.modelData.activate();
                        }
                    }

                }

            }

            Power {
                config: root.config
                barWindow: root.barWindow
                popupManager: root.popupManager
            }

        }

    }

    Behavior on revealProgress {
        NumberAnimation {
            duration: root.revealDuration
            easing.type: Easing.OutCubic
        }

    }

}
