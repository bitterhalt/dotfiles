import QtQuick
import QtQuick.Controls

Slider {
    id: root

    required property var config
    property int knobSize: 12

    height: 18
    from: 0
    to: 1.5
    stepSize: 0.01

    background: Rectangle {
        x: root.leftPadding
        y: root.topPadding + root.availableHeight / 2 - height / 2
        width: root.availableWidth
        height: 4
        radius: 2
        color: root.config.borderColor

        Rectangle {
            width: root.visualPosition * parent.width
            height: parent.height
            radius: parent.radius
            color: root.config.accent
        }

    }

    handle: Rectangle {
        x: root.leftPadding + root.visualPosition * (root.availableWidth - width)
        y: root.topPadding + root.availableHeight / 2 - height / 2
        width: root.knobSize
        height: root.knobSize
        radius: root.knobSize / 2
        color: root.pressed ? root.config.fg : root.config.accent
    }

}
