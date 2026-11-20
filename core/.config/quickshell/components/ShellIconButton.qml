import QtQuick

ShellButton {
    id: root

    property string iconText: ""
    property real iconSize: config.iconSize

    implicitWidth: contentRow.implicitWidth + leftPadding + rightPadding

    contentItem: Item {
        implicitHeight: contentRow.height
        Row {
            id: contentRow
            anchors.centerIn: parent
            spacing: root.iconText !== "" && root.text !== "" ? 4 : 0
            height: Math.max(iconLabel.implicitHeight, textLabel.implicitHeight)

            Text {
                id: iconLabel
                objectName: "buttonIcon"
                visible: root.iconText !== ""
                height: contentRow.height
                verticalAlignment: Text.AlignVCenter
                renderType: Text.QtRendering
                font.family: root.config.iconFontFamily
                font.pointSize: root.iconSize
                color: root.foregroundColor
                text: root.iconText
            }

            Text {
                id: textLabel
                height: contentRow.height
                verticalAlignment: Text.AlignVCenter
                renderType: Text.NativeRendering
                textFormat: Text.PlainText
                font: root.font
                color: root.foregroundColor
                text: root.text
            }
        }
    }
}
