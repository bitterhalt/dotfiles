import QtQuick
import Quickshell

Item {
    id: root

    required property var config
    required property var barWindow
    required property var popupManager
    required property var notificationService
    required property var notificationPopup
    required property var uiService

    readonly property bool active: notificationService.dnd || notificationService.notificationCount > 0

    width: active ? 22 : 0
    height: barWindow.height
    visible: active

    Text {
        anchors.centerIn: parent

        color: notificationService.dnd || notificationService.notificationCount > 0 ? config.selectionBackground : config.muted

        font.family: config.iconFontFamily
        font.pointSize: config.iconSize
        text: notificationService.dnd ? "󰂛" : "󱅫"
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: Qt.PointingHandCursor

        onClicked: mouse => {
            if (mouse.button === Qt.RightButton) {
                notificationService.toggleDnd();
                return;
            }

            notificationPopup.hide();

            popupManager.toggleHost("notificationCenter", notificationCenterComponent, root, true, true);
        }
    }

    Component {
        id: notificationCenterComponent

        NotificationCenter {
            config: root.config
            notificationService: root.notificationService
            availableWidth: root.barWindow.screen ? root.barWindow.screen.width : 0
            availableHeight: root.barWindow.screen ? root.barWindow.screen.height : 0
            onCloseRequested: root.popupManager.closeHost("notificationCenter")
            Component.onCompleted: root.notificationService.historyOpenCount += 1
            Component.onDestruction: root.notificationService.historyOpenCount -= 1
        }
    }

    Connections {
        target: uiService

        function onNotificationCenterActionRequested(action): void {
            if (action === "close") {
                popupManager.closeHost("notificationCenter");
                return;
            }

            if (barWindow.screen !== uiService.targetScreen) {
                popupManager.closeHost("notificationCenter");
                return;
            }

            notificationPopup.hide();

            if (action === "toggle") {
                popupManager.toggleHost("notificationCenter", notificationCenterComponent, root, true, true);
            } else if (action === "open") {
                popupManager.openHost("notificationCenter", notificationCenterComponent, root, true, true);
            }
        }
    }
}
