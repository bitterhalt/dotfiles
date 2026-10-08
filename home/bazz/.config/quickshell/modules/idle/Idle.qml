import QtQuick

Item {
    id: idleModule

    required property var config
    required property var barWindow
    required property var idleService

    width: idleService.disabled ? 24 : 0
    height: barWindow.height
    visible: width > 0

    Text {
        anchors.centerIn: parent
        color: config.accent
        font.family: config.iconFontFamily
        font.pointSize: config.iconSize
        text: "󱐋"
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: idleService.toggle(barWindow.screen)
    }

    IdleNotifier {
        id: idleNotifier
        config: idleModule.config
        barWindow: idleModule.barWindow
    }

    Connections {
        target: idleService

        function onNotificationRequested(message, screen): void {
            if (barWindow.screen === screen)
                idleNotifier.show(message)
        }
    }
}
