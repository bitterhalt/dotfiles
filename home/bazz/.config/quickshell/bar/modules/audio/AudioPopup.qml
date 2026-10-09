import "../../../components"
import "Model.js" as Model
import QtQuick
import QtQuick.Controls
import Quickshell.Services.Pipewire

PopoutPanel {
    id: root

    required property var audioItem

    config: audioItem.config
    contentWidth: 340

    Component.onDestruction: {
        audioItem.showOutputs = false
        audioItem.showInputs = false
        audioItem.showStreams = false
    }

    Item {
        width: parent.width
        height: 24

        Text {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            color: config.fg
            font.pointSize: config.fontSize(1.08)
            font.weight: Font.DemiBold
            text: "Sound"
        }

        Text {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            color: config.muted
            font.pointSize: config.fontSize(0.77)
            text: Pipewire.ready ? "PipeWire" : "Loading…"
        }
    }

    PanelSeparator {
        config: audioItem.config
    }

    // ----------------------------------------------------------
    // Output volume
    // ----------------------------------------------------------
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
                color: outputHover.hovered ? config.borderColor : "transparent"
            }

            Item {
                width: 26
                height: parent.height

                Text {
                    anchors.centerIn: parent
                    color: config.fg
                    opacity: audioItem.muted ? 0.5 : 1
                    font.family: config.iconFontFamily
                    font.pointSize: config.iconSize
                    text: audioItem.icon
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor

                    onClicked: {
                        if (audioItem.sinkAudio) {
                            if (audioItem.volumeOsd)
                                audioItem.volumeOsd.suppress(600)

                            audioItem.sinkAudio.muted = !audioItem.sinkAudio.muted
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
                    color: config.fg
                    font.pointSize: config.fontSize(0.92)
                    font.weight: Font.DemiBold
                    elide: Text.ElideRight
                    text: "Output"
                }

                Text {
                    width: parent.width
                    color: config.muted
                    font.pointSize: config.fontSize(0.77)
                    elide: Text.ElideRight
                    text: audioItem.sink ? Model.label(audioItem.sink) : "No output device"
                }
            }

            Row {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                spacing: 6

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    color: config.fg
                    font.pointSize: config.fontSize(0.92)
                    text: `${audioItem.volume}%`
                }
            }

            MouseArea {
                id: outputDeviceMouse

                anchors.fill: parent
                anchors.leftMargin: 30
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor

                onClicked: {
                    audioItem.showOutputs = !audioItem.showOutputs
                    if (audioItem.showOutputs) {
                        audioItem.showInputs = false
                        audioItem.showStreams = false
                    }
                }
            }
        }

        Slider {
            id: outputSlider

            width: parent.width
            height: 18
            from: 0
            to: 1.5
            stepSize: 0.01
            enabled: audioItem.sinkAudio !== null
            value: audioItem.sinkAudio ? audioItem.sinkAudio.volume : 0

            onMoved: {
                if (audioItem.sinkAudio) {
                    if (audioItem.volumeOsd)
                        audioItem.volumeOsd.suppress(600)

                    audioItem.sinkAudio.volume = value
                }
            }

            background: Rectangle {
                x: outputSlider.leftPadding
                y: outputSlider.topPadding + outputSlider.availableHeight / 2 - height / 2
                width: outputSlider.availableWidth
                height: 4
                radius: 2
                color: config.borderColor

                Rectangle {
                    width: outputSlider.visualPosition * parent.width
                    height: parent.height
                    radius: parent.radius
                    color: config.accent
                }
            }

            handle: Rectangle {
                x: outputSlider.leftPadding + outputSlider.visualPosition * (outputSlider.availableWidth - width)
                y: outputSlider.topPadding + outputSlider.availableHeight / 2 - height / 2
                width: 12
                height: 12
                radius: 6
                color: outputSlider.pressed ? config.fg : config.accent
            }
        }
    }

    Column {
        width: parent.width
        spacing: 2
        visible: audioItem.showOutputs

        Repeater {
            model: audioItem.outputRows

            delegate: DeviceRow {
                required property var modelData

                width: parent ? parent.width : 0
                config: audioItem.config
                row: modelData
                icon: "󰓃"

                onActivated: {
                    audioItem.setOutput(modelData.id)
                    audioItem.showOutputs = false
                }
            }
        }
    }

    PanelSeparator {
        config: audioItem.config
    }

    // ----------------------------------------------------------
    // Input volume and device
    // ----------------------------------------------------------
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
                color: inputHover.hovered ? config.borderColor : "transparent"
            }

            Item {
                width: 26
                height: parent.height

                Text {
                    anchors.centerIn: parent
                    color: config.fg
                    opacity: audioItem.sourceAudio && audioItem.sourceAudio.muted ? 0.5 : 1
                    font.family: config.iconFontFamily
                    font.pointSize: config.iconSize
                    text: audioItem.sourceAudio && audioItem.sourceAudio.muted ? "󰍭" : "󰍬"
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor

                    onClicked: {
                        if (audioItem.sourceAudio)
                            audioItem.sourceAudio.muted = !audioItem.sourceAudio.muted
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
                    color: config.fg
                    font.pointSize: config.fontSize(0.92)
                    font.weight: Font.DemiBold
                    elide: Text.ElideRight
                    text: "Microphone"
                }

                Text {
                    width: parent.width
                    color: config.muted
                    font.pointSize: config.fontSize(0.77)
                    elide: Text.ElideRight
                    text: audioItem.source ? Model.label(audioItem.source) : "No input device"
                }
            }

            Row {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                spacing: 6

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    color: config.fg
                    font.pointSize: config.fontSize(0.92)
                    text: audioItem.sourceAudio ? `${Math.round(audioItem.sourceAudio.volume * 100)}%` : "—"
                }
            }

            MouseArea {
                id: inputDeviceMouse

                anchors.fill: parent
                anchors.leftMargin: 30
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor

                onClicked: {
                    audioItem.showInputs = !audioItem.showInputs
                    if (audioItem.showInputs) {
                        audioItem.showOutputs = false
                        audioItem.showStreams = false
                    }
                }
            }
        }

        Slider {
            id: inputSlider

            width: parent.width
            height: 18
            from: 0
            to: 1.5
            stepSize: 0.01
            enabled: audioItem.sourceAudio !== null
            value: audioItem.sourceAudio ? audioItem.sourceAudio.volume : 0

            onMoved: {
                if (audioItem.sourceAudio)
                    audioItem.sourceAudio.volume = value
            }

            background: Rectangle {
                x: inputSlider.leftPadding
                y: inputSlider.topPadding + inputSlider.availableHeight / 2 - height / 2
                width: inputSlider.availableWidth
                height: 4
                radius: 2
                color: config.borderColor

                Rectangle {
                    width: inputSlider.visualPosition * parent.width
                    height: parent.height
                    radius: parent.radius
                    color: config.accent
                }
            }

            handle: Rectangle {
                x: inputSlider.leftPadding + inputSlider.visualPosition * (inputSlider.availableWidth - width)
                y: inputSlider.topPadding + inputSlider.availableHeight / 2 - height / 2
                width: 12
                height: 12
                radius: 6
                color: inputSlider.pressed ? config.fg : config.accent
            }
        }
    }

    Column {
        width: parent.width
        spacing: 2
        visible: audioItem.showInputs

        Repeater {
            model: audioItem.inputRows

            delegate: DeviceRow {
                required property var modelData

                width: parent ? parent.width : 0
                config: audioItem.config
                row: modelData
                icon: "󰍬"

                onActivated: {
                    audioItem.setInput(modelData.id)
                    audioItem.showInputs = false
                }
            }
        }
    }

    // ----------------------------------------------------------
    // Application streams
    // ----------------------------------------------------------
    PanelSeparator {
        config: audioItem.config
        visible: audioItem.streamRows.length > 0
    }

    Item {
        width: parent.width
        height: audioItem.streamRows.length > 0 ? 28 : 0
        visible: height > 0

        Rectangle {
            anchors.fill: parent
            radius: 3
            color: applicationsMouse.containsMouse ? config.borderColor : "transparent"
        }

        Text {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            color: config.muted
            font.pointSize: config.fontSize(0.77)
            font.weight: Font.DemiBold
            text: "APPLICATIONS"
        }

        Text {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            color: config.muted
            font.family: config.iconFontFamily
            font.pointSize: config.iconSize
            text: audioItem.showStreams ? "󰅀" : "󰅂"
        }

        MouseArea {
            id: applicationsMouse

            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor

            onClicked: {
                audioItem.showStreams = !audioItem.showStreams
                if (audioItem.showStreams) {
                    audioItem.showOutputs = false
                    audioItem.showInputs = false
                }
            }
        }
    }

    Column {
        width: parent.width
        spacing: 8
        visible: audioItem.showStreams

        Repeater {
            model: audioItem.streamRows

            delegate: StreamRow {
                required property var modelData

                width: parent ? parent.width : 0
                config: audioItem.config
                node: audioItem.nodeForId(modelData.id)
                name: modelData.name
                media: modelData.media
                volumeOsd: audioItem.volumeOsd
            }
        }
    }

    component DeviceRow: Item {
        id: deviceRow

        required property var config
        required property var row
        property string icon: ""

        signal activated()

        implicitHeight: 38

        Rectangle {
            anchors.fill: parent
            radius: 3
            color: rowMouse.containsMouse ? deviceRow.config.borderColor : "transparent"
        }

        Text {
            x: 6
            anchors.verticalCenter: parent.verticalCenter
            color: deviceRow.row.active ? deviceRow.config.accent : deviceRow.config.fg
            font.family: deviceRow.config.iconFontFamily
            font.pointSize: deviceRow.config.iconSize
            text: deviceRow.row.active ? "󰄬" : deviceRow.icon
        }

        Text {
            x: 36
            width: parent.width - 80
            anchors.verticalCenter: parent.verticalCenter
            color: deviceRow.config.fg
            font.pointSize: deviceRow.config.fontSize(0.88)
            font.weight: deviceRow.row.active ? Font.DemiBold : Font.Normal
            elide: Text.ElideRight
            text: deviceRow.row.name
        }

        Text {
            anchors.right: parent.right
            anchors.rightMargin: 6
            anchors.verticalCenter: parent.verticalCenter
            visible: deviceRow.row.active
            color: deviceRow.config.muted
            font.pointSize: deviceRow.config.fontSize(0.72)
            text: "Default"
        }

        MouseArea {
            id: rowMouse

            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor

            onClicked: deviceRow.activated()
        }
    }

    component StreamRow: Column {
        id: streamRow

        required property var config
        required property var node
        required property var volumeOsd
        property string name: ""
        property string media: ""
        readonly property var nodeAudio: node && node.audio ? node.audio : null

        spacing: 4

        Item {
            width: parent.width
            height: 28

            Text {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width - 78
                color: streamRow.config.fg
                font.pointSize: streamRow.config.fontSize(0.85)
                elide: Text.ElideRight
                text: streamRow.media !== "" ? `${streamRow.name} — ${streamRow.media}` : streamRow.name
            }

            Text {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                color: streamRow.config.muted
                font.pointSize: streamRow.config.fontSize(0.77)
                text: streamRow.nodeAudio ? `${Math.round(streamRow.nodeAudio.volume * 100)}%` : "—"
            }
        }

        Row {
            width: parent.width
            height: 18
            spacing: 8

            Item {
                width: 20
                height: parent.height

                Text {
                    anchors.centerIn: parent
                    color: streamRow.config.fg
                    opacity: streamRow.nodeAudio && streamRow.nodeAudio.muted ? 0.5 : 1
                    font.family: streamRow.config.iconFontFamily
                    font.pointSize: streamRow.config.iconSize
                    text: streamRow.nodeAudio && streamRow.nodeAudio.muted ? "󰝟" : "󰕾"
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor

                    onClicked: {
                        if (streamRow.nodeAudio) {
                            if (streamRow.volumeOsd)
                                streamRow.volumeOsd.suppress(600)

                            streamRow.nodeAudio.muted = !streamRow.nodeAudio.muted
                        }
                    }
                }
            }

            Slider {
                id: streamSlider

                width: parent.width - 28
                height: parent.height
                from: 0
                to: 1.5
                stepSize: 0.01
                enabled: streamRow.nodeAudio !== null
                value: streamRow.nodeAudio ? streamRow.nodeAudio.volume : 0

                onMoved: {
                    if (streamRow.nodeAudio) {
                        if (streamRow.volumeOsd)
                            streamRow.volumeOsd.suppress(600)

                        streamRow.nodeAudio.volume = value
                    }
                }

                background: Rectangle {
                    x: streamSlider.leftPadding
                    y: streamSlider.topPadding + streamSlider.availableHeight / 2 - height / 2
                    width: streamSlider.availableWidth
                    height: 4
                    radius: 2
                    color: streamRow.config.borderColor

                    Rectangle {
                        width: streamSlider.visualPosition * parent.width
                        height: parent.height
                        radius: parent.radius
                        color: streamRow.config.accent
                    }
                }

                handle: Rectangle {
                    x: streamSlider.leftPadding + streamSlider.visualPosition * (streamSlider.availableWidth - width)
                    y: streamSlider.topPadding + streamSlider.availableHeight / 2 - height / 2
                    width: 10
                    height: 10
                    radius: 5
                    color: streamSlider.pressed ? streamRow.config.fg : streamRow.config.accent
                }
            }
        }
    }
}
