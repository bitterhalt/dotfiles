import QtQuick
import Quickshell.Services.Pipewire
import "privacy/Model.js" as Model

// Read-only PipeWire monitoring, shared by all bars. No polling or subprocesses.
Item {
    id: root
    visible: false
    readonly property var audioNodes: Pipewire.nodes ? Pipewire.nodes.values.filter(node => node && node.audio) : []
    readonly property var audioLinks: Pipewire.linkGroups ? Pipewire.linkGroups.values.filter(group => group && group.source && group.target && group.source.audio && group.target.audio) : []
    readonly property var microphoneApplications: Model.microphoneApplications(audioLinks, PwLinkState.Active)
    readonly property bool microphoneActive: microphoneApplications.length > 0

    // Node properties and link states require binding before they can be read.
    PwObjectTracker {
        objects: root.audioNodes.concat(root.audioLinks)
    }
}
