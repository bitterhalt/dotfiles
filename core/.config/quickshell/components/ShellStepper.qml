import QtQuick

// "- value +" control. It only reports the requested value through moved();
// the owner validates and stores it. Left/Right step it while it has focus.
Row {
    id: root

    required property var config
    property real value: 0
    property real step: 1
    property real from: -1e9
    property real to: 1e9
    // The shown number is value * factor, e.g. 100 to show 1.1 as 110%.
    property real factor: 1
    property int decimals: 0
    property string suffix: ""

    signal moved(real value)

    function bump(direction) {
        const next = Math.round((value + direction * step) * 1000) / 1000;
        moved(Math.min(to, Math.max(from, next)));
    }

    spacing: config.spacingControl
    Keys.onLeftPressed: bump(-1)
    Keys.onRightPressed: bump(1)

    ShellButton {
        config: root.config
        outlined: true
        width: 28
        text: "−"
        onClicked: root.bump(-1)
    }

    Text {
        renderType: Text.NativeRendering
        width: 64
        height: 28
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        color: root.config.fg
        font.pointSize: root.config.textSizeMedium
        text: (root.value * root.factor).toFixed(root.decimals) + root.suffix
    }

    ShellButton {
        config: root.config
        outlined: true
        width: 28
        text: "+"
        onClicked: root.bump(1)
    }
}
