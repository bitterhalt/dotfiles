import QtQuick
import Quickshell

Item {
    id: config

    required property var theme
    // Typography
    property real fontScale: 1
    property real iconScale: 1
    property string iconFontFamily: "Symbols Nerd Font Mono"
    // Bar geometry
    property int barHeight: 32
    property int barEdgeMargin: 14
    property int barModuleSpacing: 8
    property int workspaceTitleGap: 10
    property int barItemPadding: 6
    // Clock
    property string clockFormat: "HH:mm"
    property string clockAlternativeFormat: "ddd, dd.MM"
    // Popup geometry
    property int popupGap: 16
    property int popupRadius: 4
    // Semantic palette supplied by ThemeService.
    // ThemeService falls back to the hardcoded palette when Pywal is absent.
    readonly property color bg: theme.bg
    readonly property color surface: theme.surface
    readonly property color borderColor: theme.borderColor
    readonly property color fg: theme.fg
    readonly property color muted: theme.muted
    readonly property color accent: theme.accent
    readonly property color urgent: theme.urgent
    readonly property string textFontFamily: systemFontMetrics.font.family
    readonly property real systemFontPointSize: systemFontMetrics.font.pointSize > 0 ? systemFontMetrics.font.pointSize : 10
    readonly property real iconSize: systemFontPointSize * fontScale * iconScale

    function fontSize(scale) {
        return systemFontPointSize * fontScale * scale;
    }

    function run(command) {
        Quickshell.execDetached(["sh", "-lc", command]);
    }

    visible: false

    FontMetrics {
        id: systemFontMetrics
    }

}
