import QtQuick

Item {
    id: batteryModule

    required property var config
    required property var barWindow
    required property var battery

    width: battery.present ? batteryText.implicitWidth : 0
    height: barWindow.height
    visible: battery.present

    Text {
        id: batteryText

        anchors.centerIn: parent
        color: config.fg
        font.pointSize: config.fontSize(1)
        text: `${battery.capacity}% ${battery.icon}`
    }

}
