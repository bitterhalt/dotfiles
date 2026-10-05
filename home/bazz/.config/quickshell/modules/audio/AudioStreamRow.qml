import QtQuick

Column {
    id: root

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
            color: root.config.fg
            font.pointSize: root.config.fontSize(0.85)
            elide: Text.ElideRight
            text: root.media !== "" ? `${root.name} — ${root.media}` : root.name
        }

        Text {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            color: root.config.muted
            font.pointSize: root.config.fontSize(0.77)
            text: root.nodeAudio ? `${Math.round(root.nodeAudio.volume * 100)}%` : "—"
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
                color: root.config.fg
                opacity: root.nodeAudio && root.nodeAudio.muted ? 0.5 : 1
                font.family: root.config.iconFontFamily
                font.pointSize: root.config.iconSize
                text: root.nodeAudio && root.nodeAudio.muted ? "󰝟" : "󰕾"
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    if (root.nodeAudio) {
                        if (root.volumeOsd)
                            root.volumeOsd.suppress(600);

                        root.nodeAudio.muted = !root.nodeAudio.muted;
                    }
                }
            }

        }

        VolumeSlider {
            id: streamSlider

            width: parent.width - 28
            config: root.config
            knobSize: 10
            enabled: root.nodeAudio !== null
            value: root.nodeAudio ? root.nodeAudio.volume : 0
            onMoved: {
                if (root.nodeAudio) {
                    if (root.volumeOsd)
                        root.volumeOsd.suppress(600);

                    root.nodeAudio.volume = value;
                }
            }
        }

    }

}
