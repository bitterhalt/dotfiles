import "Model.js" as Model
import QtQuick
import Quickshell
import Quickshell.Services.Pipewire

Item {
    id: audioItem

    required property var config
    required property var barWindow
    required property var popupManager
    required property var volumeOsd
    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var sinkAudio: sink ? sink.audio : null
    readonly property var source: Pipewire.defaultAudioSource
    readonly property var sourceAudio: source ? source.audio : null
    readonly property var allNodes: Pipewire.nodes ? Pipewire.nodes.values : []
    // Bind all audio nodes that we expose controls for. PwNodeAudio's
    // writable volume/mute properties require the node to be tracked.
    readonly property var trackedNodes: allNodes.filter((node) => {
        return node && node.audio;
    })
    readonly property var outputRows: Model.deviceRows(allNodes, true, sink ? sink.id : -1)
    readonly property var inputRows: Model.deviceRows(allNodes, false, source ? source.id : -1)
    readonly property var streamRows: Model.playbackStreams(allNodes)
    readonly property int volume: sinkAudio ? Math.round(sinkAudio.volume * 100) : 0
    readonly property bool muted: sinkAudio ? sinkAudio.muted : false
    readonly property string icon: {
        if (muted)
            return "󰝟";

        if (volume < 25)
            return "󰕿";

        if (volume < 60)
            return "󰖀";

        return "󰕾";
    }

    function nodeForId(id) {
        for (var i = 0; i < allNodes.length; ++i) {
            var node = allNodes[i];
            if (node && Number(node.id) === Number(id))
                return node;

        }
        return null;
    }

    function setOutput(id) {
        var node = nodeForId(id);
        if (!node)
            return ;

        // A default-device change can emit a burst of synthetic volume
        // updates. It is not a volume adjustment, so keep the OSD quiet.
        if (volumeOsd)
            volumeOsd.suppress(1500);

        Pipewire.preferredDefaultAudioSink = node;
    }

    function setInput(id) {
        var node = nodeForId(id);
        if (!node)
            return ;

        Pipewire.preferredDefaultAudioSource = node;
    }

    width: 24
    height: barWindow.height

    PwObjectTracker {
        objects: audioItem.trackedNodes
    }

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
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: Qt.PointingHandCursor
        onClicked: (mouse) => {
            if (mouse.button === Qt.LeftButton) {
                popupManager.toggle(audioPopup);
            } else if (audioItem.sinkAudio) {
                if (volumeOsd)
                    volumeOsd.suppress(600);

                audioItem.sinkAudio.muted = !audioItem.sinkAudio.muted;
            }
        }
        onWheel: (wheel) => {
            if (!audioItem.sinkAudio)
                return ;

            var next = audioItem.sinkAudio.volume + (wheel.angleDelta.y > 0 ? 0.05 : -0.05);
            if (volumeOsd)
                volumeOsd.suppress(600);

            audioItem.sinkAudio.volume = Math.max(0, Math.min(1.5, next));
        }
    }

    AudioPopup {
        id: audioPopup

        audio: audioItem
    }

}
