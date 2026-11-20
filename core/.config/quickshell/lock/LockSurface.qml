import QtQuick
import QtQuick.Controls.Fusion
import QtQuick.Layouts
import QtQuick.Window
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

Rectangle {
    id: root

    required property LockContext context
    required property var config
    property var resumeService: null
    readonly property color bg: config.bg
    readonly property color fg: config.fg
    readonly property color error: "#cc241d"
    property int previousPasswordLength: 0
    property real pulseScale: 1
    property real pulseOpacity: 0
    property real feedbackOffset: 0
    property string weatherText: ""

    function focusPassword() {
        if (root.context.acceptingPassword && root.context.pamResponseRequired && passwordBox.enabled && passwordBox.visible) {
            passwordBox.forceActiveFocus();
            passwordBox.cursorPosition = passwordBox.text.length;
        }
    }

    color: bg
    focus: true
    Keys.onPressed: event => {
        if (event.key === Qt.Key_Escape) {
            root.context.cancelPam();
            event.accepted = true;
            return;
        }
        if (root.context.showFailure && (event.key === Qt.Key_Return || event.key === Qt.Key_Enter)) {
            root.context.tryUnlock();
            event.accepted = true;
            return;
        }
        if (!root.context.pamActivated)
            root.context.requestUnlock();

        // Preserve the wake-up key and any typing before PAM has provided
        // its prompt. Input does not depend on when the prompt appears.
        if (root.context.acceptingPassword) {
            if (event.key === Qt.Key_Backspace) {
                root.context.currentText = Array.from(root.context.currentText).slice(0, -1).join("");
            } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                if (root.context.currentText !== "")
                    root.context.submitPassword();
            } else if (event.text && !/[\x00-\x1f\x7f]/.test(event.text) && !(event.modifiers & Qt.MetaModifier) && (!(event.modifiers & Qt.ControlModifier) || (event.modifiers & Qt.AltModifier))) {
                root.context.currentText += event.text;
            }
            Qt.callLater(root.focusPassword);
        }
        event.accepted = true;
    }

    // Read-only decoration: never fetch weather or delay the lock for it.
    FileView {
        objectName: "lockWeatherCache"
        path: (Quickshell.env("XDG_CACHE_HOME") || Quickshell.env("HOME") + "/.cache") + "/quickshell/weather.json"
        watchChanges: true
        printErrors: false
        onLoaded: {
            root.weatherText = "";
            try {
                const cached = JSON.parse(text());
                const city = cached && cached._place;
                const temperature = cached && cached.current && cached.current.temperature_2m;
                if (typeof city === "string" && city.trim() !== "" && typeof temperature === "number" && Number.isFinite(temperature))
                    root.weatherText = city.trim() + " " + Math.round(temperature) + "°C";
            } catch (_) {}
        }
        onFileChanged: reload()
        onLoadFailed: root.weatherText = ""
    }

    // Typing feedback (pulse effect)
    SequentialAnimation {
        id: typingPulse

        ParallelAnimation {
            NumberAnimation {
                target: root
                property: "pulseScale"
                from: 1
                to: 1.4
                duration: 100
                easing.type: Easing.OutQuad
            }

            NumberAnimation {
                target: root
                property: "pulseOpacity"
                from: 0.28
                to: 0.18
                duration: 100
            }
        }

        ParallelAnimation {
            NumberAnimation {
                target: root
                property: "pulseScale"
                to: 1
                duration: 180
                easing.type: Easing.OutQuad
            }

            NumberAnimation {
                target: root
                property: "pulseOpacity"
                to: 0
                duration: 180
                easing.type: Easing.OutQuad
            }
        }
    }

    SequentialAnimation {
        id: failureShake

        NumberAnimation {
            target: root
            property: "feedbackOffset"
            to: -7
            duration: 45
        }

        NumberAnimation {
            target: root
            property: "feedbackOffset"
            to: 6
            duration: 55
        }

        NumberAnimation {
            target: root
            property: "feedbackOffset"
            to: -4
            duration: 50
        }

        NumberAnimation {
            target: root
            property: "feedbackOffset"
            to: 0
            duration: 65
        }
    }

    SystemClock {
        id: systemClock
        objectName: "lockClock"

        precision: SystemClock.Minutes
    }

    Connections {
        target: root.resumeService
        function onResumed(): void {
            systemClock.enabled = false;
            systemClock.enabled = true;
        }
    }

    Image {
        anchors.fill: parent
        source: "file://" + Quickshell.env("HOME") + "/.local/share/wall/lockscreen.png"
        sourceSize.width: Math.ceil(width * Screen.devicePixelRatio)
        sourceSize.height: Math.ceil(height * Screen.devicePixelRatio)
        fillMode: Image.PreserveAspectCrop
    }

    Rectangle {
        anchors.fill: parent
        color: root.bg
        opacity: 0.3
    }

    Connections {
        function onPamActivatedChanged() {
            if (!root.context.pamActivated)
                root.forceActiveFocus();
        }

        function onShowFailureChanged() {
            if (root.context.showFailure) {
                root.forceActiveFocus();
                failureShake.restart();
            } else {
                failureShake.stop();
                root.feedbackOffset = 0;
            }
        }

        function onAcceptingPasswordChanged() {
            Qt.callLater(root.focusPassword);
        }

        function onPamResponseRequiredChanged() {
            Qt.callLater(root.focusPassword);
        }

        function onCurrentTextChanged() {
            const length = Array.from(root.context.currentText).length;
            if (length > root.previousPasswordLength && root.context.acceptingPassword) {
                typingPulse.restart();
            } else {
                typingPulse.stop();
                root.pulseScale = 1;
                root.pulseOpacity = 0;
            }
            root.previousPasswordLength = length;
        }

        target: root.context
    }

    // Date and time above the password prompt.
    Column {
        id: clockGroup

        anchors.horizontalCenter: parent.horizontalCenter
        y: 80
        spacing: 8

        Label {
            id: dateLabel

            anchors.horizontalCenter: parent.horizontalCenter
            renderType: Text.NativeRendering
            font.pointSize: 24
            color: root.config.fg
            opacity: 0.7
            text: Qt.formatDateTime(systemClock.date, "dddd, d MMMM")
        }

        Label {
            id: clock

            anchors.horizontalCenter: parent.horizontalCenter
            renderType: Text.NativeRendering
            font.pointSize: 80
            color: root.config.fg
            opacity: 0.7
            text: Qt.formatTime(systemClock.date, "HH:mm")
        }

        Label {
            objectName: "lockWeatherLabel"
            anchors.horizontalCenter: parent.horizontalCenter
            visible: root.weatherText !== ""
            renderType: Text.NativeRendering
            textFormat: Text.PlainText
            font.pointSize: 20
            color: root.config.fg
            opacity: 0.7
            text: root.weatherText
        }
    }

    // Password feedback and authentication status.
    ColumnLayout {
        id: feedbackColumn

        spacing: 16

        anchors {
            horizontalCenter: parent.horizontalCenter
            top: parent.verticalCenter
        }

        // Keep the real text input invisible, but focusable for IME/key input.
        RowLayout {
            visible: root.context.pamActivated && (root.context.pamResponseRequired || root.context.currentText.length > 0)
            Layout.alignment: Qt.AlignHCenter

            TextField {
                id: passwordBox

                objectName: "lockPasswordInput"
                renderType: Text.NativeRendering
                horizontalAlignment: TextInput.AlignHCenter
                cursorVisible: false
                implicitWidth: 240
                implicitHeight: 52
                padding: 12
                enabled: !root.context.unlockInProgress
                echoMode: TextInput.Password
                inputMethodHints: Qt.ImhSensitiveData | Qt.ImhNoPredictiveText
                activeFocusOnPress: false
                selectByMouse: false
                color: "transparent"
                selectionColor: "transparent"
                selectedTextColor: "transparent"
                onTextChanged: root.context.currentText = text
                onAccepted: root.context.submitPassword()

                // Block cursor movement, selection, context menus and middle-click paste.
                // Programmatic keyboard focus and text input remain unchanged.
                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.AllButtons
                    cursorShape: Qt.ArrowCursor
                    onWheel: event => {
                        event.accepted = true;
                    }
                }

                Connections {
                    function onCurrentTextChanged() {
                        if (passwordBox.text !== root.context.currentText)
                            passwordBox.text = root.context.currentText;
                    }

                    target: root.context
                }

                cursorDelegate: Item {
                    visible: false
                }

                background: Item {
                    Row {
                        anchors.centerIn: parent
                        spacing: 6

                        Repeater {
                            id: passwordDots

                            objectName: "lockPasswordDots"
                            // Cap only the visible dots, not the actual password.
                            model: Math.min(12, Array.from(root.context.currentText).length)

                            delegate: Item {
                                required property int index
                                readonly property bool newest: index === passwordDots.count - 1

                                width: 12
                                height: 24

                                Rectangle {
                                    anchors.centerIn: parent
                                    width: 20
                                    height: 20
                                    radius: 10
                                    color: root.config.selectionBackground
                                    opacity: newest ? root.pulseOpacity : 0
                                    scale: newest ? root.pulseScale : 1
                                }

                                Rectangle {
                                    objectName: "lockPasswordDot-" + index
                                    anchors.centerIn: parent
                                    width: newest ? 10 : 8
                                    height: width
                                    radius: width / 2
                                    color: newest ? root.config.selectionBackground : root.config.border
                                    scale: newest ? root.pulseScale : 1
                                }
                            }
                        }
                    }
                }
            }
        }

        // Status message
        Label {
            id: statusLabel

            objectName: "lockStatus"
            renderType: Text.NativeRendering
            textFormat: Text.PlainText
            visible: text !== ""
            text: {
                if (root.context.errorText !== "")
                    return root.context.errorText;

                if (root.context.pamMessageIsError)
                    return root.context.pamMessage;

                if (root.context.showFailure)
                    return "Incorrect password";

                return "";
            }
            color: root.context.errorText !== "" || root.context.pamMessageIsError || root.context.showFailure ? root.error : root.config.muted
            font.pointSize: 13
            Layout.alignment: Qt.AlignHCenter
        }

        transform: Translate {
            x: root.feedbackOffset
        }
    }
}
