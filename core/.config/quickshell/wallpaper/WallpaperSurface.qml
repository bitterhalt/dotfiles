import QtQuick
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: win

    required property string namespace
    required property string url
    required property int rev
    required property int fadeMs

    WlrLayershell.layer: WlrLayer.Background
    WlrLayershell.namespace: namespace
    exclusionMode: ExclusionMode.Ignore // exclusive zone -1, needed for place-within-backdrop
    focusable: false
    color: "black"

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    // The helper overwrites the same file, so a ?rev suffix forces a reload.
    readonly property string target: url + "?r=" + rev

    // The overview image is heavily blurred, so decode it small (0 = native size).
    readonly property int decodeWidth: fadeMs === 0 ? 960 : 0

    onTargetChanged: {
        if (base.source.toString() === "" || fadeMs === 0) {
            base.source = target;
            over.opacity = 0;
        } else {
            over.source = target;
        }
    }

    Image {
        id: base
        anchors.fill: parent
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        cache: false
        sourceSize.width: win.decodeWidth
        source: win.target
        // Once the base shows the new image, hide the overlay and free its texture.
        onStatusChanged: if (status === Image.Ready && source === over.source) {
            over.opacity = 0;
            over.source = "";
        }
    }

    Image {
        id: over
        anchors.fill: parent
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        cache: false
        sourceSize.width: win.decodeWidth
        opacity: 0
        onStatusChanged: if (status === Image.Ready && source !== base.source)
            fade.restart()
    }

    NumberAnimation {
        id: fade
        target: over
        property: "opacity"
        from: 0
        to: 1
        duration: win.fadeMs
        easing.type: Easing.InOutQuad
        onFinished: base.source = over.source
    }
}
