import QtQuick
import Quickshell
import Quickshell.Widgets

Item {
    id: root

    required property var config
    required property var barWindow
    required property var niri
    readonly property var focusedWindow: niri.windows[niri.focusedWindowId] ?? null
    readonly property string focusedAppIcon: {
        const appId = focusedWindow ? String(focusedWindow.app_id || "") : "";
        if (appId === "")
            return "";

        const entry = DesktopEntries.byId(appId) || DesktopEntries.heuristicLookup(appId);
        return entry ? entry.icon || "" : "";
    }
    readonly property string focusedAppIconSource: focusedAppIcon !== "" ? Quickshell.iconPath(focusedAppIcon, true) : ""
    readonly property int titleLeft: 18 + (focusedAppIconSource !== "" ? 27 : 0)

    implicitWidth: Math.min(windowTitle.implicitWidth + titleLeft + 10, 560)
    height: barWindow.height

    // Focused application's icon and title, elided to fit the bar.
    IconImage {
        anchors.left: parent.left
        anchors.leftMargin: 18
        anchors.verticalCenter: parent.verticalCenter
        implicitSize: 20
        visible: root.focusedAppIconSource !== ""
        source: root.focusedAppIconSource
    }

    Text {
        id: windowTitle

        renderType: Text.NativeRendering
        anchors.left: parent.left
        anchors.leftMargin: root.titleLeft
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width - 10 - root.titleLeft
        color: root.config.fg
        font.pointSize: root.config.textSizeNormal
        elide: Text.ElideRight
        text: {
            const win = root.focusedWindow;
            return win && win.title ? win.title : "";
        }
    }
}
