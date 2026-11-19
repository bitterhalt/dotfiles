import QtQuick

// Shared enter/exit motion state for standalone popup surfaces.
Item {
    id: motion

    visible: false
    width: 0
    height: 0

    property bool shown: false
    property bool animationsEnabled: true
    property string animationType: "fade"
    required property int duration
    property real surfaceHeight: 0
    readonly property real slideDistance: surfaceHeight
    property bool closing: false
    property bool initialized: false
    property real progress: 0

    // Keep the surface mapped across the shown -> closing handoff.
    property bool surfaceVisible: false
    readonly property real contentOpacity: !animationsEnabled || animationType !== "fade" ? 1 : progress
    readonly property real contentOffset: !animationsEnabled || animationType !== "slide" ? 0 : (progress - 1) * slideDistance

    signal closed

    function restartEnter(): void {
        if (!shown)
            return;
        progressAnimation.stop();
        finishCloseTimer.stop();
        progress = 0;
        animateTo(1, duration);
    }

    onAnimationsEnabledChanged: {
        if (!initialized || animationsEnabled)
            return;
        progressAnimation.stop();
        finishCloseTimer.stop();
        // Unmap before resetting the visual properties of a closing surface.
        if (!shown) {
            surfaceVisible = false;
            closing = false;
            closed();
        }
        progress = shown ? 1 : 0;
    }

    onShownChanged: {
        if (!initialized)
            return;
        progressAnimation.stop();
        finishCloseTimer.stop();
        if (shown) {
            surfaceVisible = true;
            closing = false;
            animateTo(1, duration);
        } else if (animationsEnabled) {
            closing = true;
            animateTo(0, duration);
        } else {
            closing = false;
            progress = 0;
            surfaceVisible = false;
            closed();
        }
    }

    function animateTo(value: real, duration: int): void {
        if (!animationsEnabled) {
            progress = value;
            if (value === 0) {
                closing = false;
                surfaceVisible = false;
                closed();
            }
            return;
        }

        progressAnimation.stop();
        progressAnimation.from = progress;
        progressAnimation.to = value;
        progressAnimation.duration = duration;
        progressAnimation.start();
    }

    Component.onCompleted: {
        initialized = true;
        surfaceVisible = shown;
        if (shown && animationsEnabled) {
            progress = 0;
            Qt.callLater(() => {
                if (motion.shown)
                    motion.animateTo(1, motion.duration);
            });
        } else {
            progress = shown ? 1 : 0;
        }
    }

    NumberAnimation {
        id: progressAnimation
        target: motion
        property: "progress"
        easing.type: Easing.OutCubic
        onFinished: {
            if (!motion.shown && motion.progress <= 0)
                finishCloseTimer.start();
        }
    }

    Timer {
        id: finishCloseTimer
        // Allow the transparent final state to reach the compositor before
        // unmapping. This is a settling delay, not a frame presentation fence.
        interval: 24
        onTriggered: {
            if (!motion.shown && motion.progress <= 0) {
                motion.surfaceVisible = false;
                motion.closing = false;
                motion.closed();
            }
        }
    }
}
