import QtQuick
import "../../../components"

Item {
    id: root

    required property var config
    required property var barWindow

    visible: false

    property string state: ""
    property bool toastShown: false

    function show(newState): void {
        state = newState;
        toastShown = true;
        toastTimer.restart();
    }

    BarToast {
        config: root.config
        targetScreen: root.barWindow.screen
        shown: root.toastShown
        surfaceWidth: 160
        iconText: "󱐋"
        title: "Idle timer"
        subtitle: root.state
    }

    Timer {
        id: toastTimer

        interval: 5000
        repeat: false
        onTriggered: root.toastShown = false
    }
}
