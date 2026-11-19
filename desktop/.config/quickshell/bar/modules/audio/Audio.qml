import QtQuick

Item {
    id: root

    required property var config
    required property var barWindow
    required property var popupManager
    required property var uiService
    required property var audioService
    readonly property var sink: audioService.sink
    readonly property var sinkAudio: audioService.sinkAudio
    readonly property int volume: audioService.volume
    readonly property bool muted: audioService.muted
    readonly property string icon: {
        if (muted)
            return "󰝟";

        if (volume < 25)
            return "󰕿";

        if (volume < 60)
            return "󰖀";

        return "󰕾";
    }

    function closePopup() {
        popupManager.closeHost("audio");
    }

    width: 24
    height: barWindow.height

    Connections {
        function onAudioActionRequested(action) {
            if (action === "close" || root.barWindow.screen !== root.uiService.targetScreen) {
                root.closePopup();
                return;
            }
            if (action === "open")
                root.popupManager.openHost("audio", audioPopupComponent, root, true);
            else if (action === "toggle")
                root.popupManager.toggleHost("audio", audioPopupComponent, root, true);
        }

        target: root.uiService
    }

    Text {
        anchors.centerIn: parent
        color: config.fg
        opacity: root.muted ? 0.5 : 1
        font.family: config.iconFontFamily
        font.pointSize: config.iconSize
        text: root.icon
    }

    // Left-click opens controls, right-click toggles mute, and the wheel adjusts volume.
    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: Qt.PointingHandCursor
        onClicked: mouse => {
            if (mouse.button === Qt.LeftButton)
                popupManager.toggleHost("audio", audioPopupComponent, root, true);
            else if (root.sink)
                root.audioService.toggleMute(root.sink.id);
        }
        onWheel: wheel => {
            if (!root.sinkAudio)
                return;

            root.audioService.adjustVolume(root.sink.id, wheel.angleDelta.y > 0 ? 0.05 : -0.05);
        }
    }

    // Device-profile backend is loaded only when the profile tab is visited.
    Component {
        id: profileBackendComponent

        AudioProfiles {}
    }

    Component {
        id: audioPopupComponent

        AudioPopup {
            audioItem: root
            audioService: root.audioService
            profileBackend: profileBackendComponent
        }
    }
}
