import QtQuick

// Label on the left; the control children fill the row and anchor themselves,
// usually to the right edge. `stacked` puts the label on its own line above a
// control that is stackedHeight tall.
Item {
    id: root

    required property var config
    property string label: ""
    property bool muted: false
    property bool stacked: false
    property int stackedHeight: 76
    readonly property int stackedOffset: 32
    default property alias content: area.data

    width: parent ? parent.width : 0
    implicitHeight: stacked ? stackedOffset + stackedHeight : 40

    Text {
        renderType: Text.NativeRendering
        y: root.stacked ? root.config.spacingTight : (root.height - height) / 2
        color: root.muted ? root.config.muted : root.config.fg
        font.pointSize: root.config.textSizeMedium
        text: root.label
    }

    Item {
        id: area

        anchors.fill: parent
    }
}
