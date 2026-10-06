import QtQuick

Item {
    id: panel

    required property var config
    property int contentWidth: 330
    property int padding: 14
    default property alias contentData: panelContent.data

    implicitWidth: contentWidth
    implicitHeight: panelContent.implicitHeight + padding * 2
    width: implicitWidth
    height: implicitHeight

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
