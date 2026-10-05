import "../../components"
import "Model.js" as Model
import QtQuick
import QtQuick.Controls
import Quickshell.Services.Pipewire

PopoutPanel {
    id: root

    required property var audio
    property bool showOutputs: false
    property bool showInputs: false

    anchorItem: audio
    config: audio.config
    contentWidth: 340
    onVisibleChanged: {
        if (!visible) {
            showOutputs = false;
            showInputs = false;
        }
    }

    Item {
        width: parent.width
        height: 24

        Text {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            color: root.config.fg
            font.pointSize: root.config.fontSize(1.08)
            font.weight: Font.DemiBold
            text: "Sound"
        }

        Text {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            color: root.config.muted
            font.pointSize: root.config.fontSize(0.77)
            text: Pipewire.ready ? "PipeWire" : "Loading…"
        }

    }

    PanelSeparator {
        config: root.config
    }

    // --------------------------------------------------------------
    // Output volume and device
    // --------------------------------------------------------------
    Column {
        width: parent.width
        spacing: 7

        Item {
            width: parent.width
            height: 38

            HoverHandler {
                id: outputHover
            }

            Rectangle {
                anchors.fill: parent
                radius: 3
                color: outputHover.hovered ? root.config.borderColor : "transparent"
            }

            Item {
                width: 26
                height: parent.height

                Text {
                    anchors.centerIn: parent
                    color: root.config.fg
                    opacity: root.audio.muted ? 0.5 : 1
                    font.family: root.config.iconFontFamily
                    font.pointSize: root.config.iconSize
                    text: root.audio.icon
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (root.audio.sinkAudio) {
                            if (root.audio.volumeOsd)
                                root.audio.volumeOsd.suppress(600);

                            root.audio.sinkAudio.muted = !root.audio.sinkAudio.muted;
                        }
                    }
                }

            }

            Column {
                x: 36
                width: parent.width - 88
                anchors.verticalCenter: parent.verticalCenter
                spacing: 0

                Text {
                    width: parent.width
                    color: root.config.fg
                    font.pointSize: root.config.fontSize(0.92)
                    font.weight: Font.DemiBold
                    elide: Text.ElideRight
                    text: "Output"
                }

                Text {
                    width: parent.width
                    color: root.config.muted
                    font.pointSize: root.config.fontSize(0.77)
                    elide: Text.ElideRight
                    text: root.audio.sink ? Model.label(root.audio.sink) : "No output device"
                }

            }

            Text {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                color: root.config.fg
                font.pointSize: root.config.fontSize(0.92)
                text: `${root.audio.volume}%`
            }

            MouseArea {
                anchors.fill: parent
                anchors.leftMargin: 30
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    root.showOutputs = !root.showOutputs;
                    if (root.showOutputs)
                        root.showInputs = false;

                }
            }

        }

        VolumeSlider {
            id: outputSlider

            width: parent.width
            config: root.config
            enabled: root.audio.sinkAudio !== null
            value: root.audio.sinkAudio ? root.audio.sinkAudio.volume : 0
            onMoved: {
                if (root.audio.sinkAudio) {
                    if (root.audio.volumeOsd)
                        root.audio.volumeOsd.suppress(600);

                    root.audio.sinkAudio.volume = value;
                }
            }
        }

    }

    Column {
        width: parent.width
        spacing: 2
        visible: root.showOutputs

        Repeater {
            model: root.audio.outputRows

            delegate: AudioDeviceRow {
                required property var modelData

                width: parent ? parent.width : 0
                config: root.config
                row: modelData
                icon: "󰓃"
                onActivated: {
                    root.audio.setOutput(modelData.id);
                    root.showOutputs = false;
                }
            }

        }

    }

    PanelSeparator {
        config: root.config
    }

    // --------------------------------------------------------------
    // Input volume and device
    // --------------------------------------------------------------
    Column {
        width: parent.width
        spacing: 7

        Item {
            width: parent.width
            height: 38

            HoverHandler {
                id: inputHover
            }

            Rectangle {
                anchors.fill: parent
                radius: 3
                color: inputHover.hovered ? root.config.borderColor : "transparent"
            }

            Item {
                width: 26
                height: parent.height

                Text {
                    anchors.centerIn: parent
                    color: root.config.fg
                    opacity: root.audio.sourceAudio && root.audio.sourceAudio.muted ? 0.5 : 1
                    font.family: root.config.iconFontFamily
                    font.pointSize: root.config.iconSize
                    text: root.audio.sourceAudio && root.audio.sourceAudio.muted ? "󰍭" : "󰍬"
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (root.audio.sourceAudio)
                            root.audio.sourceAudio.muted = !root.audio.sourceAudio.muted;

                    }
                }

            }

            Column {
                x: 36
                width: parent.width - 88
                anchors.verticalCenter: parent.verticalCenter
                spacing: 0

                Text {
                    width: parent.width
                    color: root.config.fg
                    font.pointSize: root.config.fontSize(0.92)
                    font.weight: Font.DemiBold
                    elide: Text.ElideRight
                    text: "Microphone"
                }

                Text {
                    width: parent.width
                    color: root.config.muted
                    font.pointSize: root.config.fontSize(0.77)
                    elide: Text.ElideRight
                    text: root.audio.source ? Model.label(root.audio.source) : "No input device"
                }

            }

            Text {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                color: root.config.fg
                font.pointSize: root.config.fontSize(0.92)
                text: root.audio.sourceAudio ? `${Math.round(root.audio.sourceAudio.volume * 100)}%` : "—"
            }

            MouseArea {
                anchors.fill: parent
                anchors.leftMargin: 30
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    root.showInputs = !root.showInputs;
                    if (root.showInputs)
                        root.showOutputs = false;

                }
            }

        }

        VolumeSlider {
            id: inputSlider

            width: parent.width
            config: root.config
            enabled: root.audio.sourceAudio !== null
            value: root.audio.sourceAudio ? root.audio.sourceAudio.volume : 0
            onMoved: {
                if (root.audio.sourceAudio)
                    root.audio.sourceAudio.volume = value;

            }
        }

    }

    Column {
        width: parent.width
        spacing: 2
        visible: root.showInputs

        Repeater {
            model: root.audio.inputRows

            delegate: AudioDeviceRow {
                required property var modelData

                width: parent ? parent.width : 0
                config: root.config
                row: modelData
                icon: "󰍬"
                onActivated: {
                    root.audio.setInput(modelData.id);
                    root.showInputs = false;
                }
            }

        }

    }

    // --------------------------------------------------------------
    // Application streams
    // --------------------------------------------------------------
    PanelSeparator {
        config: root.config
        visible: root.audio.streamRows.length > 0
    }

    SectionHeader {
        config: root.config
        visible: root.audio.streamRows.length > 0
        text: "APPLICATIONS"
    }

    Repeater {
        model: root.audio.streamRows

        delegate: AudioStreamRow {
            required property var modelData

            width: parent ? parent.width : 0
            config: root.config
            node: root.audio.nodeForId(modelData.id)
            name: modelData.name
            media: modelData.media
            volumeOsd: root.audio.volumeOsd
        }

    }

}
