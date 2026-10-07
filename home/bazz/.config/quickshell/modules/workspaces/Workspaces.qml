import QtQuick
import QtQuick.Layouts

Item {
    id: root

    required property var config
    required property var barWindow
    required property var niri

    implicitWidth: workspacesRow.implicitWidth
    height: barWindow.height

    Row {
        id: workspacesRow

        anchors.centerIn: parent
        spacing: config.barModuleSpacing

        Repeater {
            model: niri.workspaces.filter((ws) => {
                return ws.output === barWindow.screen.name;
            }).sort((a, b) => {
                return a.idx - b.idx;
            })

            delegate: Rectangle {
                required property var modelData

                width: modelData.is_active ? 24 : 8
                height: 8
                radius: 4
                color: modelData.is_urgent ? config.urgent : (modelData.is_active ? config.accent : config.fg)
                opacity: modelData.is_active ? 1 : 0.8

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: config.run(`niri msg action focus-workspace ${parent.modelData.idx}`)
                }

            }

        }

    }

}
