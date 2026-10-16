import QtQuick
import QtQuick.Controls.Basic

Item {
    id: root

    required property var config
    required property var row
    required property var node
    property bool selected: false
    readonly property var nodeAudio: node && node.audio ? node.audio : null

    signal picked()
    signal optionsRequested()
    signal muteRequested()
    signal volumeRequested(real value)

    objectName: "audioVolumeRow"
    implicitHeight: 76

    FontMetrics {
        id: volumeMetrics

        font.pointSize: root.config.fontSize(0.78)
    }

    Rectangle {
        anchors.fill: parent
        radius: 4
        color: rowMouse.containsMouse || root.selected ? root.config.borderColor : "transparent"
    }

    MouseArea {
        id: rowMouse

        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.picked()
        onDoubleClicked: root.optionsRequested()
    }

    Item {
        x: 6
        y: 6
        width: 26
        height: 28

        Text {
            anchors.centerIn: parent
            color: root.config.fg
            opacity: root.nodeAudio && root.nodeAudio.muted ? 0.5 : 1
            font.family: root.config.iconFontFamily
            font.pointSize: root.config.iconSize
            text: root.row.kind === "input" ? (root.nodeAudio && root.nodeAudio.muted ? "󰍭" : "󰍬") : (root.nodeAudio && root.nodeAudio.muted ? "󰝟" : "󰕾")
        }

        MouseArea {
            anchors.fill: parent
            enabled: root.nodeAudio !== null
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                root.picked();
                root.muteRequested();
            }
        }

    }

    Text {
        renderType: Text.NativeRendering
        x: 38
        y: 8
        width: Math.max(0, parent.width - x - (defaultLabel.visible ? defaultLabel.width + 18 : 8))
        color: root.config.fg
        font.pointSize: root.config.fontSize(0.9)
        font.weight: root.row.active ? Font.DemiBold : Font.Normal
        elide: Text.ElideRight
        text: root.row.name
    }

    Text {
        id: defaultLabel

        renderType: Text.NativeRendering
        anchors.right: parent.right
        anchors.rightMargin: 8
        y: 9
        visible: !!root.row.active
        text: "Default"
        color: root.config.accent
        font.pointSize: root.config.fontSize(0.72)
    }

    Text {
        renderType: Text.NativeRendering
        x: 38
        y: 29
        width: parent.width - x - 8
        color: root.config.muted
        font.pointSize: root.config.fontSize(0.75)
        elide: Text.ElideRight
        text: root.row.media || (root.nodeAudio && root.nodeAudio.muted ? "Muted" : "")
    }

    Slider {
        id: slider

        objectName: "audioVolumeSlider"
        anchors.left: parent.left
        anchors.leftMargin: 8
        anchors.right: volumeText.left
        anchors.rightMargin: 8
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 6
        height: 18
        from: 0
        to: 1.5
        stepSize: 0.01
        focusPolicy: Qt.NoFocus
        enabled: root.nodeAudio !== null
        value: root.nodeAudio ? root.nodeAudio.volume : 0
        onPressedChanged: {
            if (pressed) {
                root.picked();
            }
        }
        onMoved: root.volumeRequested(value)

        background: Rectangle {
            x: slider.leftPadding
            y: slider.topPadding + slider.availableHeight / 2 - height / 2
            width: slider.availableWidth
            height: 4
            radius: 2
            color: root.selected || rowMouse.containsMouse
                ? root.config.bg
                : root.config.borderColor

            Rectangle {
                width: slider.visualPosition * parent.width
                height: parent.height
                radius: 2
                color: root.config.accent
            }

        }

        handle: Rectangle {
            x: slider.leftPadding + slider.visualPosition * (slider.availableWidth - width)
            y: slider.topPadding + slider.availableHeight / 2 - height / 2
            width: 12
            height: 12
            radius: 6
            color: slider.pressed ? root.config.fg : root.config.accent
        }

    }

    Text {
        id: volumeText

        objectName: "audioVolumePercent"
        renderType: Text.NativeRendering
        anchors.right: parent.right
        anchors.rightMargin: 8
        anchors.verticalCenter: slider.verticalCenter
        width: Math.ceil(volumeMetrics.advanceWidth("150%"))
        horizontalAlignment: Text.AlignRight
        color: root.config.muted
        font.pointSize: root.config.fontSize(0.78)
        text: root.nodeAudio ? Math.round(root.nodeAudio.volume * 100) + "%" : "—"
    }

}
