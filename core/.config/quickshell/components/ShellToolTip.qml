import QtQuick
import Quickshell

// A separate, non-interactive surface so bar tooltips are not clipped to the bar.
PopupWindow {
    id: root
    required property var config
    required property Item anchorItem
    property string text: ""
    property bool shown: false
    property int delay: 400
    property bool delayElapsed: false

    function updateDelay(): void {
        showTimer.stop();
        delayElapsed = false;
        if (shown && text !== "")
            showTimer.start();
    }
    onShownChanged: updateDelay()
    onAnchorItemChanged: updateDelay()
    onTextChanged: {
        if (!visible)
            updateDelay();
    }
    Component.onCompleted: updateDelay()

    visible: shown && delayElapsed && text !== "" && !!anchorItem && anchorItem.visible
    color: "transparent"
    grabFocus: false
    mask: Region {}
    implicitWidth: Math.min(360, Math.ceil(naturalCaption.implicitWidth) + 20)
    implicitHeight: caption.implicitHeight + 16

    anchor.item: anchorItem
    anchor.rect.x: anchorItem ? anchorItem.width / 2 : 0
    anchor.rect.y: anchorItem ? anchorItem.height + 6 : 0
    anchor.rect.width: 0
    anchor.rect.height: 0
    anchor.edges: Edges.Bottom
    anchor.gravity: Edges.Bottom
    anchor.adjustment: PopupAdjustment.SlideX | PopupAdjustment.FlipY

    Timer {
        id: showTimer
        interval: root.delay
        onTriggered: root.delayElapsed = true
    }

    // Do not size the window from the wrapped caption: its width depends on ours.
    Text {
        id: naturalCaption
        visible: false
        text: root.text
        font: caption.font
        textFormat: Text.PlainText
        renderType: Text.NativeRendering
        wrapMode: Text.NoWrap
    }

    PanelSurface {
        anchors.fill: parent
        config: root.config

        Text {
            id: caption
            objectName: "tooltipCaption"
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.leftMargin: 10
            anchors.topMargin: 8
            width: Math.max(0, root.width - 20)
            text: root.text
            textFormat: Text.PlainText
            renderType: Text.NativeRendering
            wrapMode: Text.Wrap
            color: root.config.fg
            font.family: root.config.textFontFamily
            font.pointSize: root.config.textSizeMedium
        }
    }
}
