import QtQuick

Column {
    id: root

    required property var config
    required property var entries
    property int rowHeight: 20

    spacing: 8

    Repeater {
        model: root.entries

        delegate: Item {
            id: helpRow
            required property var modelData

            width: root.width
            height: root.rowHeight

            Text {
                renderType: Text.NativeRendering
                anchors.left: parent.left
                anchors.leftMargin: 6
                text: helpRow.modelData.name
                color: root.config.fg
                font.pointSize: root.config.textSizeMedium
            }

            Text {
                renderType: Text.NativeRendering
                anchors.right: parent.right
                anchors.rightMargin: 6
                text: helpRow.modelData.key
                color: root.config.muted
                font.pointSize: root.config.textSizeSmall
            }
        }
    }
}
