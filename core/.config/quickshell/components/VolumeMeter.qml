// Shared segmented display; interactive controls can use it as their background.

import QtQuick

Item {
    id: root

    required property var config
    property real value: 0
    property real maximum: 1
    property int segmentCount: 26
    readonly property int activeSegments: maximum > 0 ? Math.ceil(Math.max(0, Math.min(value / maximum, 1)) * segmentCount) : 0
    readonly property real spacing: 3

    implicitWidth: 120
    implicitHeight: 14

    Row {
        anchors.fill: parent
        spacing: root.spacing

        Repeater {
            model: root.segmentCount

            delegate: Rectangle {
                required property int index

                radius: 1
                objectName: "volumeSegment-" + index
                width: Math.max(0, (root.width - root.spacing * (root.segmentCount - 1)) / root.segmentCount)
                height: root.height
                color: index < root.activeSegments ? root.config.selectionBackground : root.config.border
            }
        }
    }
}
