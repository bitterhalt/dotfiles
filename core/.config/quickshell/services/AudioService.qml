import QtQuick
import Quickshell.Services.Pipewire
import "../bar/modules/audio/Model.js" as Model

// One PipeWire model/tracker shared by all per-screen controls.
Item {
    id: root
    visible: false

    required property var config
    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var sinkAudio: sink ? sink.audio : null
    readonly property var source: Pipewire.defaultAudioSource
    readonly property var sourceAudio: source ? source.audio : null
    readonly property var allNodes: Pipewire.nodes ? Pipewire.nodes.values : []
    readonly property var trackedNodes: [...new Set([sink, source].concat(allNodes.filter(node => node && node.audio)))].filter(node => !!node)
    readonly property var outputRows: Model.deviceRows(allNodes, true, sink ? sink.id : -1)
    readonly property var inputRows: Model.deviceRows(allNodes, false, source ? source.id : -1)
    readonly property var streamRows: Model.playbackStreams(allNodes)
    readonly property int volume: sinkAudio ? Math.round(sinkAudio.volume * 100) : 0
    readonly property bool muted: sinkAudio ? sinkAudio.muted : false

    function nodeForId(id) {
        return allNodes.find(node => node && Number(node.id) === Number(id)) || null;
    }

    function setOutput(id) {
        const node = nodeForId(id);
        if (node && node.audio && !node.isStream && node.isSink)
            Pipewire.preferredDefaultAudioSink = node;
    }

    function setInput(id) {
        const node = nodeForId(id);
        if (node && node.audio && !node.isStream && !node.isSink)
            Pipewire.preferredDefaultAudioSource = node;
    }

    function setVolume(id, value) {
        const node = nodeForId(id);
        if (node && node.audio && Number.isFinite(value))
            node.audio.volume = Model.clampVolume(value, Model.volumeLimit(node, config.maxVolume));
    }

    function adjustVolume(id, delta) {
        const node = nodeForId(id);
        if (node && node.audio)
            setVolume(id, node.audio.volume + delta);
    }

    function toggleMute(id) {
        const node = nodeForId(id);
        if (node && node.audio)
            node.audio.muted = !node.audio.muted;
    }

    PwObjectTracker {
        objects: root.trackedNodes
    }
}
