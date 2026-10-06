import QtQuick
import Quickshell

PopupWindow {
    id: panel

    required property Item anchorItem
    required property var config
    property int contentWidth: 330
    property int padding: 14
    default property alias contentData: panelContent.data

    implicitWidth: contentWidth
    implicitHeight: panelContent.implicitHeight + padding * 2
    visible: false
    grabFocus: true
    color: "transparent"

    anchor {
        item: panel.anchorItem
        edges: Edges.Bottom | Edges.Right
        gravity: Edges.Bottom | Edges.Left
        margins.bottom: -panel.config.popupGap
        margins.right: panel.config.popupGap
    }

    Rectangle {
        anchors.fill: parent
        color: panel.config.surface
        border.color: panel.config.borderColor
        border.width: 1
        radius: panel.config.popupRadius

        Column {
            id: panelContent

            anchors.fill: parent
            anchors.margins: panel.padding
            spacing: 8
        }

    }

}
