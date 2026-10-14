import QtQuick
import QtQuick.Controls.Fusion
import QtQuick.Layouts
import QtQuick.Window
import Quickshell
import Quickshell.Wayland

Rectangle {
    id: root

    required property LockContext context
    required property var config
    readonly property color bg: config.bg
    readonly property color fg: config.fg
    readonly property color surface: config.surface
    readonly property color border: config.borderColor
    readonly property color accent: config.accent
    readonly property color error: config.urgent

    function focusPassword() {
        if (root.context.acceptingPassword && root.context.pamResponseRequired && passwordBox.enabled && passwordBox.visible) {
            passwordBox.forceActiveFocus();
            passwordBox.cursorPosition = passwordBox.text.length;
        }
    }

    color: bg
    focus: true
    Keys.onPressed: (event) => {
        if (event.key === Qt.Key_Escape) {
            root.context.cancelPam();
            event.accepted = true;
            return ;
        }
        if (root.context.showFailure && (event.key === Qt.Key_Return || event.key === Qt.Key_Enter)) {
            root.context.tryUnlock();
            event.accepted = true;
            return ;
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

    SystemClock {
        id: systemClock

        precision: SystemClock.Minutes
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

    MouseArea {
        anchors.fill: parent
        visible: !root.context.pamActivated
        onClicked: root.context.requestUnlock()
    }

    Connections {
        function onPamActivatedChanged() {
            if (!root.context.pamActivated)
                root.forceActiveFocus();

        }

        function onShowFailureChanged() {
            if (root.context.showFailure)
                root.forceActiveFocus();

        }

        function onAcceptingPasswordChanged() {
            Qt.callLater(root.focusPassword);
        }

        function onPamResponseRequiredChanged() {
            Qt.callLater(root.focusPassword);
        }

        target: root.context
    }

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
            color: Qt.alpha(root.fg, 0.7)
            text: Qt.formatDateTime(systemClock.date, "dddd, d MMMM yyyy")
        }

        Label {
            id: clock

            anchors.horizontalCenter: parent.horizontalCenter
            renderType: Text.NativeRendering
            font.pointSize: 80
            color: Qt.alpha(root.fg, 0.7)
            text: Qt.formatTime(systemClock.date, "HH:mm")
        }

    }

    ColumnLayout {
        spacing: 16

        anchors {
            horizontalCenter: parent.horizontalCenter
            top: parent.verticalCenter
        }

        // Password field - shown when PAM requests a response.
        RowLayout {
            visible: root.context.pamActivated && root.context.pamResponseRequired
            Layout.alignment: Qt.AlignHCenter

            TextField {
                id: passwordBox

                horizontalAlignment: TextInput.AlignHCenter
                cursorVisible: activeFocus && (length > 0 || preeditText.length > 0)
                implicitWidth: 200
                padding: 12
                enabled: !root.context.unlockInProgress
                echoMode: TextInput.Password
                inputMethodHints: Qt.ImhSensitiveData | Qt.ImhNoPredictiveText
                color: enabled ? root.fg : root.config.muted
                selectionColor: root.accent
                selectedTextColor: bg
                placeholderTextColor: root.config.muted
                onTextChanged: root.context.currentText = this.text
                onAccepted: {
                    root.context.submitPassword();
                }

                // Fusion hides its centered placeholder while focused.
                Text {
                    anchors.fill: parent
                    anchors.leftMargin: passwordBox.leftPadding
                    anchors.rightMargin: passwordBox.rightPadding
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    visible: passwordBox.length === 0 && passwordBox.preeditText.length === 0
                    font: passwordBox.font
                    color: passwordBox.placeholderTextColor
                    text: "Enter password"
                }

                Connections {
                    function onCurrentTextChanged() {
                        passwordBox.text = root.context.currentText;
                    }

                    target: root.context
                }

                Connections {
                    function onPamActivatedChanged() {
                        if (!root.context.pamActivated)
                            passwordBox.text = "";

                    }

                    target: root.context
                }

                background: Item {
                    Rectangle {
                        anchors.fill: parent
                        color: Qt.rgba(root.surface.r, root.surface.g, root.surface.b, 0.3)
                        radius: 6
                    }

                    Rectangle {
                        anchors.fill: parent
                        color: "transparent"
                        border.width: 1
                        border.color: Qt.rgba(root.border.r, root.border.g, root.border.b, 1)
                        radius: 6
                    }

                }

            }

        }

        // Spinner loader - shown while verifying
        Item {
            id: verificationSpinner

            visible: root.context.pamActivated && root.context.unlockInProgress
            implicitWidth: 24
            implicitHeight: 24
            Layout.alignment: Qt.AlignHCenter

            Rectangle {
                anchors.centerIn: parent
                width: 20
                height: 20
                color: "transparent"

                Canvas {
                    anchors.fill: parent
                    anchors.margins: 2
                    onPaint: {
                        var ctx = getContext("2d");
                        ctx.reset();
                        ctx.lineWidth = 2;
                        ctx.strokeStyle = root.accent;
                        ctx.lineCap = "round";
                        ctx.beginPath();
                        ctx.arc(width / 2, height / 2, width / 2 - 1, 0, Math.PI * 1.5);
                        ctx.stroke();
                    }
                }

                transform: Rotation {
                    origin.x: 10
                    origin.y: 10
                    angle: 0

                    NumberAnimation on angle {
                        running: verificationSpinner.visible
                        from: 0
                        to: 360
                        duration: 800
                        loops: Animation.Infinite
                    }

                }

            }

        }

        // Retry button - shown after failed auth
        Column {
            visible: root.context.pamActivated && root.context.showFailure && !root.context.unlockInProgress
            spacing: 6
            Layout.alignment: Qt.AlignHCenter

            Button {
                implicitWidth: 48
                implicitHeight: 48
                onClicked: root.context.tryUnlock()

                contentItem: Text {
                    text: "↻"
                    color: root.config.muted
                    font.pointSize: 16
                    font.weight: Font.Bold
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }

                background: Rectangle {
                    color: root.surface
                    radius: width / 2
                }

            }

            Text {
                text: "Retry"
                color: root.config.muted
                font.pointSize: 9
                anchors.horizontalCenter: parent.horizontalCenter
            }

        }

        // Status message
        Label {
            id: statusLabel

            visible: text !== ""
            text: {
                if (root.context.errorText !== "")
                    return root.context.errorText;

                if (root.context.pamMessageIsError)
                    return root.context.pamMessage;

                if (root.context.showFailure)
                    return "Authentication failed · Enter to retry";

                return "";
            }
            color: root.context.pamMessageIsError || root.context.showFailure ? root.error : root.config.muted
            font.pointSize: 13
            Layout.alignment: Qt.AlignHCenter
        }

    }

    // Hint label - shown before any auth attempt
    Label {
        id: hintLabel

        visible: !root.context.pamActivated
        text: "Click or press any key to unlock"
        color: root.config.muted
        font.pointSize: 14

        anchors {
            horizontalCenter: parent.horizontalCenter
            bottom: parent.bottom
            bottomMargin: 60
        }

    }

    Column {
        visible: root.context.pamActivated
        spacing: 6

        anchors {
            horizontalCenter: parent.horizontalCenter
            bottom: parent.bottom
            bottomMargin: 40
        }

        Button {
            implicitWidth: 48
            implicitHeight: 48
            onClicked: root.context.cancelPam()

            contentItem: Text {
                text: "✕"
                color: root.config.muted
                font.pointSize: 16
                font.weight: Font.Bold
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }

            background: Rectangle {
                color: root.surface
                radius: width / 2
            }

        }

        Text {
            text: "Cancel"
            color: root.config.muted
            font.pointSize: 9
            anchors.horizontalCenter: parent.horizontalCenter
        }

    }

}
