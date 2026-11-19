import QtQuick
import Quickshell.Services.SystemTray
import Quickshell.Widgets

import "../../../components"

Item {
    id: root

    required property var config
    required property var barWindow
    required property var popupManager
    readonly property bool hasItems: trayRepeater.count > 0
    readonly property bool trayMenuOpen: popupManager.hostRequested && popupManager.activeKey === "trayMenu"
    readonly property int trayItemWidth: 20

    height: barWindow.height
    width: implicitWidth
    implicitWidth: hasItems ? revealer.implicitWidth : 0

    // Tray is at the right edge of the bar, so items reveal to the icon's left.
    ItemRevealer {
        id: revealer

        config: root.config
        barWindow: root.barWindow
        visible: root.hasItems
        revealDuration: 160
        revealToLeft: true
        revealLocked: root.trayMenuOpen
        spacing: root.config.spacingControl

        Item {
            id: toggleButton

            width: root.trayItemWidth
            height: revealer.height

            Text {
                id: toggleIcon

                anchors.centerIn: parent
                color: revealer.hovered || revealer.revealLocked ? root.config.fg : root.config.muted
                font.family: root.config.iconFontFamily
                font.pointSize: root.config.iconSize
                text: "󰅀"
                rotation: revealer.revealActive ? 180 : 0

                Behavior on rotation {
                    NumberAnimation {
                        duration: 160
                        easing.type: Easing.OutCubic
                    }
                }
            }
        }

        revealData: [
            Repeater {
                id: trayRepeater

                model: SystemTray.items

                delegate: Item {
                    id: trayItem

                    required property var modelData

                    width: root.trayItemWidth
                    height: root.barWindow.height

                    IconImage {
                        anchors.centerIn: parent
                        implicitSize: 16
                        source: trayItem.modelData.icon
                    }

                    // Left-click activates; right-click opens the item's menu.
                    MouseArea {
                        anchors.fill: parent
                        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                        cursorShape: Qt.PointingHandCursor
                        onClicked: mouse => {
                            if (mouse.button === Qt.MiddleButton) {
                                trayItem.modelData.secondaryActivate();
                                return;
                            }
                            if (mouse.button === Qt.RightButton || trayItem.modelData.onlyMenu) {
                                if (trayItem.modelData.hasMenu)
                                    root.popupManager.toggleHost("trayMenu", trayMenuComponent, trayItem);

                                return;
                            }
                            trayItem.modelData.activate();
                        }
                    }

                    Component {
                        id: trayMenuComponent

                        TrayMenu {
                            config: root.config
                            menuHandle: trayItem.modelData.menu
                            popupManager: root.popupManager
                        }
                    }
                }
            }
        ]
    }
}
