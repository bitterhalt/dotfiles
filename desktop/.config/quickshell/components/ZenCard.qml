import QtQuick
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: root

    required property var config
    required property var targetScreen
    required property var resumeService
    readonly property int horizontalPadding: 24
    readonly property int verticalPadding: 12

    screen: targetScreen
    color: "transparent"
    implicitWidth: labels.width + horizontalPadding * 2
    implicitHeight: labels.implicitHeight + verticalPadding * 2
    exclusiveZone: 0
    focusable: false
    margins.top: 32
    margins.right: 32
    WlrLayershell.layer: WlrLayer.Bottom
    WlrLayershell.namespace: "slim-zen-card"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    anchors {
        top: true
        right: true
    }

    SystemClock {
        id: clock

        enabled: root.visible
        precision: SystemClock.Minutes
    }

    Connections {
        target: root.resumeService
        function onResumed(): void {
            clock.enabled = false;
            // Restore the visibility binding, rather than leaving a hidden clock enabled.
            clock.enabled = Qt.binding(() => root.visible);
        }
    }

    Rectangle {
        anchors.fill: parent
        color: root.config.bg
        opacity: 0.8
        radius: root.config.popupRadius
    }

    // Large date and time shown while the bar is hidden.
    Column {
        id: labels

        x: root.horizontalPadding
        y: root.verticalPadding
        width: Math.max(timeText.implicitWidth, dateText.implicitWidth)
        spacing: 8

        Text {
            id: timeText

            width: labels.width
            renderType: Text.NativeRendering
            textFormat: Text.PlainText
            text: Qt.formatDateTime(clock.date, root.config.clockFormat)
            color: root.config.fg
            font.family: root.config.textFontFamily
            font.pointSize: root.config.fontSize * 2.8
            font.weight: Font.DemiBold
            horizontalAlignment: Text.AlignHCenter
            opacity: 0.8
        }

        Text {
            id: dateText

            width: labels.width
            renderType: Text.NativeRendering
            textFormat: Text.PlainText
            text: Qt.formatDateTime(clock.date, root.config.clockAlternativeFormat)
            color: root.config.fg
            font.family: root.config.textFontFamily
            font.pointSize: root.config.fontSize
            font.weight: Font.DemiBold
            horizontalAlignment: Text.AlignHCenter
            opacity: 0.8
        }
    }

    // An empty input region lets all pointer events reach the desktop below.
    mask: Region {}
}
