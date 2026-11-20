import "CriticalColors.js" as CriticalColors
import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets

// Short-lived status card shown beside the bar.
Item {
    id: root

    required property var config
    required property var targetScreen

    property bool shown: false
    property int surfaceWidth: 200
    property string iconSource: ""
    property string iconText: ""
    property string title: ""
    property string subtitle: ""
    property bool critical: false

    // Match critical notification cards, regardless of the current theme.
    readonly property color criticalBorderColor: CriticalColors.border
    readonly property color criticalTextColor: CriticalColors.text

    signal closed

    PopupMotion {
        id: toastMotion

        shown: root.shown
        animationsEnabled: root.config.popupAnimations
        animationType: "slide"
        duration: 150
        surfaceHeight: toast.height
        onClosed: root.closed()
    }

    PanelWindow {
        id: toast

        screen: root.targetScreen
        margins.top: root.config.popupGap
        WlrLayershell.namespace: "slim-notifications"
        WlrLayershell.layer: WlrLayer.Overlay
        exclusiveZone: 0
        implicitWidth: root.surfaceWidth
        implicitHeight: 62
        visible: toastMotion.surfaceVisible
        color: "transparent"

        // Anchored to the top edge only and sized to the card, so compositor
        // effects (a niri shadow) wrap the card, not a full-width strip.
        anchors.top: true

        PanelSurface {
            anchors.fill: parent
            config: root.config
            opacity: toastMotion.contentOpacity
            transform: Translate {
                y: toastMotion.contentOffset
            }
            border.color: root.critical ? root.criticalBorderColor : root.config.border

            Item {
                id: iconBox

                anchors.left: parent.left
                anchors.leftMargin: 12
                anchors.verticalCenter: parent.verticalCenter
                width: 34
                height: 34

                IconImage {
                    id: imageIcon

                    anchors.centerIn: parent
                    implicitSize: 26
                    source: root.iconSource
                    visible: !root.critical && source.toString() !== ""
                }

                Text {
                    anchors.centerIn: parent
                    visible: !imageIcon.visible
                    color: root.critical ? root.criticalTextColor : root.config.selectionBackground
                    font.family: root.config.iconFontFamily
                    font.pointSize: root.config.iconSize
                    text: root.iconText
                }
            }

            Column {
                anchors.left: iconBox.right
                anchors.leftMargin: 10
                anchors.right: parent.right
                anchors.rightMargin: 12
                anchors.verticalCenter: parent.verticalCenter
                spacing: 1

                Text {
                    renderType: Text.NativeRendering
                    width: parent.width
                    color: root.critical ? root.criticalTextColor : root.config.fg
                    font.pointSize: root.config.textSizeNormal * 0.92
                    font.weight: Font.DemiBold
                    elide: Text.ElideRight
                    text: root.title
                }

                Text {
                    renderType: Text.NativeRendering
                    color: root.critical ? root.criticalTextColor : root.config.muted
                    font.pointSize: root.config.textSizeNormal * 0.80
                    text: root.subtitle
                }
            }
        }

        mask: Region {}
    }
}
