import QtQuick
import "../../../components"

Item {
    id: root
    required property var config
    required property var barWindow
    required property var privacyService
    required property var recorderService

    visible: privacyService.microphoneActive || recorderService.runningNow
    implicitWidth: indicators.implicitWidth + 8
    height: barWindow.height

    Rectangle {
        objectName: "privacyPill"
        anchors.centerIn: parent
        width: parent.width
        height: Math.min(26, root.barWindow.height)
        radius: root.config.popupRadius
        color: Qt.alpha(root.config.selectionBackground, 0.12)
    }

    Row {
        id: indicators
        anchors.centerIn: parent
        spacing: 4

        Indicator {
            objectName: "microphonePrivacyIndicator"
            visible: root.privacyService.microphoneActive
            glyph: "󰍬"
            description: "Microphone in use\n" + root.privacyService.microphoneApplications.join("\n")
        }

        Indicator {
            objectName: "recordingPrivacyIndicator"
            visible: root.recorderService.runningNow
            glyph: "󰑋"
            description: "Recording screen · Click to stop"
            actionable: true
            recording: true
            onActivated: {
                if (root.recorderService.runningNow)
                    root.recorderService.stop();
            }
        }
    }

    component Indicator: Item {
        id: indicator
        required property string glyph
        required property string description
        property bool actionable: false
        property bool recording: false
        signal activated

        anchors.verticalCenter: parent.verticalCenter
        width: 24
        height: Math.min(26, root.barWindow.height)

        Text {
            id: glyphLabel
            objectName: indicator.recording ? "recordingPrivacyGlyph" : "microphonePrivacyGlyph"
            anchors.centerIn: parent
            font.family: root.config.iconFontFamily
            font.pointSize: root.config.iconSize
            color: indicator.recording ? root.config.selectionBackground : root.config.fg
            text: indicator.glyph

            SequentialAnimation on opacity {
                running: indicator.recording && indicator.visible
                loops: Animation.Infinite
                onRunningChanged: if (!running)
                    glyphLabel.opacity = 1

                PauseAnimation {
                    duration: 500
                }
                NumberAnimation {
                    from: 1
                    to: 0
                    duration: 100
                }
                PauseAnimation {
                    duration: 400
                }
                PropertyAction {
                    value: 1
                }
            }
        }
        HoverHandler {
            id: hover
            cursorShape: indicator.actionable ? Qt.PointingHandCursor : Qt.ArrowCursor
        }
        TapHandler {
            enabled: indicator.actionable
            acceptedButtons: Qt.LeftButton
            onTapped: indicator.activated()
        }
        ShellToolTip {
            config: root.config
            anchorItem: indicator
            shown: hover.hovered && indicator.visible
            text: indicator.description
        }
    }
}
