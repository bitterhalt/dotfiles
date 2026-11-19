import QtQuick

// Thin, non-interactive overflow hint for a Flickable. The wheel and keys do
// the scrolling; this only shows that more content exists and where it is.
Item {
    id: root

    required property var config
    required property var flickable

    readonly property real trackHeight: flickable ? flickable.height : 0
    readonly property real contentExtent: flickable ? Math.max(flickable.height, flickable.contentHeight) : 0
    readonly property real thumbHeight: contentExtent > 0 ? Math.max(24, trackHeight * trackHeight / contentExtent) : 0
    readonly property real travel: Math.max(0, trackHeight - thumbHeight)
    readonly property real maxScroll: flickable ? Math.max(0, flickable.contentHeight - flickable.height) : 0

    implicitWidth: 3
    visible: trackHeight > 0 && contentExtent > trackHeight + 0.5

    Rectangle {
        objectName: "scrollThumb"

        width: parent.width
        height: root.thumbHeight
        radius: width / 2
        color: Qt.alpha(root.config.muted, 0.35)
        y: root.maxScroll > 0 && root.flickable ? root.travel * Math.min(1, Math.max(0, root.flickable.contentY) / root.maxScroll) : 0
    }
}
