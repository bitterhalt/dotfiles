import QtQuick

// Thin inset rule used between popup content and its footer.
Rectangle {
    id: root

    required property var config
    property int horizontalInset: 0

    anchors.left: parent.left
    anchors.right: parent.right
    anchors.leftMargin: horizontalInset
    anchors.rightMargin: horizontalInset
    height: 1
    color: config.border
}
