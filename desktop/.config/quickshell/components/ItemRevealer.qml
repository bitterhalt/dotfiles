import QtQuick

Item {
    id: root

    required property var config
    required property var barWindow
    default property alias contentData: primaryRow.data
    property alias revealData: revealRow.data
    property int revealDuration: 300
    property int hoverRevealDelay: 300
    property bool revealActive: false
    property bool revealLocked: false
    property bool revealToLeft: false
    property int spacing: 8
    readonly property bool hovered: revealHover.hovered
    property real revealProgress: revealActive ? 1 : 0
    readonly property real revealExtent: revealRow.implicitWidth * revealProgress
    readonly property real revealSpacing: spacing * revealProgress

    implicitWidth: primaryRow.implicitWidth + revealSpacing + revealExtent
    height: barWindow.height

    HoverHandler {
        id: revealHover

        onHoveredChanged: {
            if (hovered) {
                if (root.hoverRevealDelay <= 0)
                    root.revealActive = true;
                else
                    revealTimer.restart();
            } else {
                revealTimer.stop();
                if (!root.revealLocked)
                    root.revealActive = false;
            }
        }
    }

    Timer {
        id: revealTimer

        interval: root.hoverRevealDelay
        onTriggered: {
            if (revealHover.hovered)
                root.revealActive = true;
        }
    }

    onRevealLockedChanged: {
        if (revealLocked) {
            revealTimer.stop();
            revealActive = true;
        } else if (!revealHover.hovered) {
            revealTimer.stop();
            revealActive = false;
        }
    }

    // Always-visible clock/workspace content.
    Row {
        id: primaryRow

        x: root.revealToLeft ? root.width - primaryRow.implicitWidth : 0
        anchors.verticalCenter: parent.verticalCenter
        spacing: root.spacing
    }

    // Clipped row revealed on hover; revealProgress also drives its spacing.
    Item {
        id: revealClip

        x: root.revealToLeft ? primaryRow.x - root.revealSpacing - root.revealExtent : primaryRow.implicitWidth + root.revealSpacing
        anchors.verticalCenter: parent.verticalCenter
        width: root.revealExtent
        height: revealRow.implicitHeight
        clip: true

        Row {
            id: revealRow

            x: revealClip.width - implicitWidth
            anchors.verticalCenter: parent.verticalCenter
            spacing: root.spacing
        }
    }

    Behavior on revealProgress {
        NumberAnimation {
            duration: root.revealDuration
            easing.type: Easing.OutCubic
        }
    }
}
