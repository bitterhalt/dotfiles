import QtQuick
import Quickshell
import Quickshell.Wayland
import "../components"

// Workspace overview for a hidden bar: shown only on focused-output workspace
// switches while the bar is off, so it never duplicates the bar's module.
Item {
    id: osd

    visible: false

    required property var config
    required property var niri
    required property var targetScreen
    required property bool barVisible

    // Match ZenCard's inset and translucent surface.
    readonly property int horizontalPadding: 24
    readonly property int verticalPadding: 12

    property bool osdVisible: false

    readonly property var rows: {
        if (!osd.osdVisible || !niri || !targetScreen)
            return [];
        return niri.workspaces.filter(workspace => workspace && workspace.output === targetScreen.name).sort((left, right) => left.idx - right.idx);
    }

    function show() {
        osdVisible = true;
        hideTimer.restart();
    }

    Connections {
        target: osd.niri

        function onWorkspaceActivated(id, focused) {
            if (focused && osd.targetScreen && osd.niri.focusedOutput === osd.targetScreen.name && !osd.barVisible)
                osd.show();
        }
    }

    onBarVisibleChanged: {
        if (barVisible) {
            osdVisible = false;
            hideTimer.stop();
        }
    }

    Timer {
        id: hideTimer

        interval: 1200
        onTriggered: osd.osdVisible = false
    }

    LazyLoader {
        active: osd.osdVisible

        PanelWindow {
            id: osdWindow

            screen: osd.targetScreen
            anchors {
                top: true
                left: true
            }
            margins.top: config.popupGap
            margins.left: osd.targetScreen ? Math.max(0, Math.round((osd.targetScreen.width - width) / 2)) : 0

            // OSDs should remain visible above fullscreen surfaces.
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "slim-osd"
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

            exclusiveZone: 0
            focusable: false
            implicitWidth: chipRow.implicitWidth + osd.horizontalPadding * 2
            implicitHeight: chipRow.implicitHeight + osd.verticalPadding * 2
            color: "transparent"

            // Do not steal mouse input from whatever is underneath the OSD.
            mask: Region {}

            Rectangle {
                anchors.fill: parent
                color: osd.config.bg
                opacity: 0.8
                radius: osd.config.popupRadius
            }

            Row {
                id: chipRow

                anchors.centerIn: parent
                spacing: osd.config.spacingControl

                Repeater {
                    model: osd.rows

                    delegate: Item {
                        id: chip

                        required property var modelData
                        readonly property bool active: !!modelData.is_active
                        readonly property bool urgent: !!modelData.is_urgent

                        readonly property real chipHeight: 24
                        readonly property real chipPadding: osd.config.spacingControl
                        implicitWidth: nameLabel.implicitWidth + chipPadding * 2
                        implicitHeight: chipHeight
                        width: implicitWidth
                        height: implicitHeight

                        Rectangle {
                            anchors.fill: parent
                            radius: osd.config.popupRadius
                            color: osd.config.selectionBackground
                            visible: chip.active
                        }

                        Text {
                            id: nameLabel

                            anchors.centerIn: parent
                            renderType: Text.NativeRendering
                            text: chip.modelData.name || String(chip.modelData.idx)
                            color: chip.active ? osd.config.selectionForeground : chip.urgent ? osd.config.urgent : osd.config.muted
                            font.pointSize: osd.config.textSize
                            font.weight: chip.active ? Font.DemiBold : Font.Normal
                        }
                    }
                }
            }
        }
    }
}
