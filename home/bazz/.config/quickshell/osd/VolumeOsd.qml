import QtQuick
import QtQuick.Layouts
import Quickshell
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
    readonly property var sinkAudio:
        currentSink && currentSink.audio ? currentSink.audio : null

    property bool volumeOsdVisible: false
    property bool startupReady: false
    property double suppressedUntil: 0

    function suppress(ms) {
        volumeOsdVisible = false
        volumeOsdHideTimer.stop()
        suppressedUntil = Math.max(suppressedUntil, Date.now() + (ms ?? 400))
    }

    function showVolumeOsd() {
        if (!startupReady || Date.now() < suppressedUntil)
            return

        volumeOsdVisible = true
        volumeOsdHideTimer.restart()
    }

    // Changing the default sink (for example when a Bluetooth headset connects)
    // is not a user volume adjustment, so don't show the OSD for the settling
    // volume events that follow.
    onCurrentSinkChanged: suppress(1500)

    Connections {
        target: osd.sinkAudio
        ignoreUnknownSignals: true

        function onVolumeChanged() {
            osd.showVolumeOsd()
        }

        function onMutedChanged() {
            osd.showVolumeOsd()
        }
    }

    Timer {
        id: volumeOsdStartupTimer
        interval: 1000
        running: true
        repeat: false

        onTriggered: osd.startupReady = true
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
                right: true
            }

            margins.top: config.popupGap

            // OSDs should remain visible above fullscreen surfaces.
            WlrLayershell.layer: WlrLayer.Overlay

            exclusiveZone: 0
            implicitHeight: 42
            color: "transparent"

            // Do not steal mouse input from whatever is underneath the OSD.
            mask: Region {}

            Rectangle {
                width: 220
                height: parent.height
                anchors.horizontalCenter: parent.horizontalCenter

                color: config.surface
                border.color: config.borderColor
                border.width: 1
                radius: config.popupRadius

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    spacing: 10

                    Text {
                        Layout.preferredWidth: 22

                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter

                        color: config.fg
                        opacity: Pipewire.defaultAudioSink?.audio.muted ? 0.55 : 1.0

                        font.family: config.iconFontFamily
                        font.pointSize: config.iconSize

                        text: {
                            const audio = Pipewire.defaultAudioSink?.audio

                            if (!audio || audio.muted)
                                return "󰝟"

                            const volume = Math.round(audio.volume * 100)

                            if (volume < 25)
                                return "󰕿"
                            if (volume < 60)
                                return "󰖀"

                            return "󰕾"
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: 6

                        radius: 2.5
                        color: config.borderColor

                        Rectangle {
                            anchors {
                                left: parent.left
                                top: parent.top
                                bottom: parent.bottom
                            }

                            // The shell currently allows output volume up to 150%.
                            width: {
                                const volume =
                                    Pipewire.defaultAudioSink?.audio.volume ?? 0
                                return parent.width * Math.min(volume / 1.5, 1.0)
                            }

                            radius: parent.radius
                            color: config.accent
                        }
                    }

                    Text {
                        Layout.preferredWidth: 38

                        horizontalAlignment: Text.AlignRight
                        verticalAlignment: Text.AlignVCenter

                        color: config.fg
                        font.pointSize: config.fontSize(0.92)

                        text: {
                            const audio = Pipewire.defaultAudioSink?.audio

                            if (!audio)
                                return "0%"

                            return `${Math.round(audio.volume * 100)}%`
                        }
                    }
                }
            }
        }
    }
}
