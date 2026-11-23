import QtQuick

// Thin inset rule used between popup content and its footer, or between a
// sidebar and its page. Callers position it; horizontal rules usually anchor
// to the top or vertical center of their container.
Rectangle {
    id: root

    required property var config
    property bool vertical: false
    property int horizontalInset: 0
    property int verticalInset: 0

    width: root.vertical ? 1 : (root.parent ? root.parent.width - root.horizontalInset * 2 : 1)
    height: root.vertical ? (root.parent ? root.parent.height - root.verticalInset * 2 : 1) : 1
    x: root.vertical ? (root.parent ? Math.round((root.parent.width - root.width) / 2) : 0) : root.horizontalInset
    y: root.vertical ? root.verticalInset : 0
    color: config.border
}
