import QtQuick
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: root

    required property var targetScreen

    signal dismissed

    screen: targetScreen
    visible: false
    color: "transparent"
    exclusiveZone: 0
    focusable: false
    anchors.top: true
    anchors.bottom: true
    anchors.left: true
    anchors.right: true
    WlrLayershell.namespace: "slim-popup-catcher"
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    // Dismiss only when a click lands outside the owning popup surface.
    MouseArea {
        anchors.fill: parent
        onClicked: root.dismissed()
    }
}
