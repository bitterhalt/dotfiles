import QtQuick

Item {
    id: panel

    required property var config
    property int contentWidth: 280
    property int padding: 12
    property int spacing: 8
    default property alias contentData: panelContent.data

    function prepareLayout() {
        panelContent.forceLayout();
    }

    implicitWidth: contentWidth
    implicitHeight: panelContent.implicitHeight + padding * 2
    width: implicitWidth
    height: implicitHeight

    // Shared popup surface; children supplied by callers go into panelContent.
    PanelSurface {
        anchors.fill: parent
        config: panel.config

        Column {
            id: panelContent

            anchors.fill: parent
            anchors.margins: panel.padding
            spacing: panel.spacing
        }
    }
}
