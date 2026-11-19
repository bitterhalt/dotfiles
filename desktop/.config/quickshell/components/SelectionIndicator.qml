import QtQuick

Rectangle {
    id: root

    required property var config
    property bool selected: false
    property real verticalInset: 3

    anchors.left: parent.left
    anchors.top: parent.top
    anchors.bottom: parent.bottom
    anchors.topMargin: verticalInset
    anchors.bottomMargin: verticalInset
    width: 3
    radius: 1
    color: config.selectionBackground
    visible: selected
}
