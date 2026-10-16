import QtQuick
import "../Model.js" as Model

// Fake PipeWire state for offline tests. No service imports or desktop writes.
Item {
    id: root
    property QtObject config: QtObject {
        property color bg: "#101010"
        property color fg: "#eeeeee"
        property color muted: "#888888"
        property color accent: "#6699cc"
        property color urgent: "#cc3333"
        property color borderColor: "#333333"
        property color surface: "#222222"
        property string iconFontFamily: "sans-serif"
        property real iconSize: 10
        property int popupGap: 16
        property int popupRadius: 4
        function fontSize(scale) { return 10 * scale; }
    }
    property var barWindow: ({screen: {width: 1280, height: 800}})
    property QtObject speakerAudio: QtObject { property real volume: 0.5; property bool muted: false }
    property QtObject headsetAudio: QtObject { property real volume: 0.7; property bool muted: false }
    property QtObject micAudio: QtObject { property real volume: 0.4; property bool muted: false }
    property QtObject streamAudio: QtObject { property real volume: 0.6; property bool muted: false }
    property var speaker: ({id: 1, name: "speaker", description: "Speakers", audio: speakerAudio, isSink: true, isStream: false})
    property var headset: ({id: 2, name: "headset", description: "Headset", audio: headsetAudio, isSink: true, isStream: false})
    property var mic: ({id: 3, name: "microphone", description: "Microphone", audio: micAudio, isSink: false, isStream: false})
    property var playback: ({id: 4, name: "playback", audio: streamAudio, isSink: true, isStream: true,
        properties: {"application.name": "Music player", "media.name": "A song"}})
    property var allNodes: [speaker, headset, mic, playback]
    property int outputId: 1
    property int inputId: 3
    readonly property var sink: outputId === 1 ? speaker : headset
    readonly property var source: mic
    readonly property var outputRows: Model.deviceRows(allNodes, true, outputId)
    readonly property var inputRows: Model.deviceRows(allNodes, false, inputId)
    readonly property var streamRows: Model.playbackStreams(allNodes)
    property var calls: []
    property bool closed: false

    function nodeForId(id) { return allNodes.find(node => node.id === id) || null; }
    function setOutput(id) { outputId = id; calls = calls.concat([{action: "output", id: id}]); }
    function setInput(id) { inputId = id; calls = calls.concat([{action: "input", id: id}]); }
    function setVolume(id, value) {
        const node = nodeForId(id);
        if (!node || !node.audio)
            return;
        node.audio.volume = Model.clampVolume(value);
        calls = calls.concat([{action: "volume", id: id, value: node.audio.volume}]);
    }
    function adjustVolume(id, delta) {
        const node = nodeForId(id);
        if (node && node.audio)
            setVolume(id, node.audio.volume + delta);
    }
    function toggleMute(id) {
        const node = nodeForId(id);
        if (node && node.audio) {
            node.audio.muted = !node.audio.muted;
            calls = calls.concat([{action: "mute", id: id}]);
        }
    }
    function closePopup() { closed = true; }
}
