import QtQuick
import "../components"
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire
import Quickshell.Wayland

Item {
    id: osd
    visible: false

    required property var config
    required property var targetScreen

    PwObjectTracker {
        objects: [Pipewire.defaultAudioSink]
    }

    readonly property var currentSink: Pipewire.defaultAudioSink
    readonly property var sinkAudio: currentSink && currentSink.audio ? currentSink.audio : null

    property bool volumeOsdVisible: false

    onCurrentSinkChanged: {
        volumeOsdVisible = false;
        volumeOsdHideTimer.stop();
    }

    // The OSD is only shown when asked to (keybinds via IPC), never in
    // reaction to volume events, so Bluetooth connects, startup and other
    // apps changing the volume don't pop it up.
    function showVolumeOsd() {
        volumeOsdVisible = true;
        volumeOsdHideTimer.restart();
    }

    function adjustVolume(delta) {
        if (!currentSink || !currentSink.ready || !sinkAudio)
            return;
        if (sinkAudio.muted && delta > 0)
            sinkAudio.muted = false;

        // Rounded so repeated steps don't drift (0.4999...).
        sinkAudio.volume = Math.max(0, Math.min(config.maxVolume, Math.round((sinkAudio.volume + delta) * 100) / 100));

        showVolumeOsd();
    }

    function toggleMute() {
        if (!currentSink || !currentSink.ready || !sinkAudio)
            return;
        sinkAudio.muted = !sinkAudio.muted;
        showVolumeOsd();
    }

    // Niri/keybind control:
    //
    //   qs ipc call volume up
    //   qs ipc call volume down
    //   qs ipc call volume mute
    IpcHandler {
        target: "volume"

        function up(): void {
            osd.adjustVolume(0.05);
        }

        function down(): void {
            osd.adjustVolume(-0.05);
        }

        function mute(): void {
            osd.toggleMute();
        }
    }

    Timer {
        id: volumeOsdHideTimer
        interval: 1000

        onTriggered: osd.volumeOsdVisible = false
    }

    LazyLoader {
        active: osd.volumeOsdVisible

        PanelWindow {
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

            exclusiveZone: 0
            implicitWidth: 220
            implicitHeight: 48
            color: "transparent"

            // Do not steal mouse input from whatever is underneath the OSD.
            mask: Region {}

            // Segmented level; dim the whole meter when muted, like the audio popup.
            PanelSurface {
                anchors.fill: parent
                config: osd.config

                VolumeMeter {
                    objectName: "osdVolumeMeter"
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.leftMargin: 22
                    anchors.rightMargin: 22
                    height: 14
                    config: osd.config
                    value: osd.sinkAudio ? osd.sinkAudio.volume : 0
                    maximum: osd.config.maxVolume
                    opacity: osd.sinkAudio && osd.sinkAudio.muted ? 0.4 : 1
                }
            }
        }
    }
}
