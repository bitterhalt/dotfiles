import QtQuick
import Quickshell
import Quickshell.Services.Pam

Scope {
    id: root

    property string currentText: ""
    property bool unlockInProgress: false
    property bool showFailure: false
    property bool pamActivated: false
    property bool timedOut: false
    property string errorText: ""
    property bool awaitingPasswordPrompt: false
    property bool submitPending: false
    readonly property bool acceptingPassword: pamActivated && !showFailure && (awaitingPasswordPrompt || (pam.responseRequired && !unlockInProgress))
    // Expose PAM state for the UI
    readonly property alias pamMessage: pam.message
    readonly property alias pamMessageIsError: pam.messageIsError
    readonly property alias pamResponseRequired: pam.responseRequired
    readonly property alias pamResponseVisible: pam.responseVisible

    signal unlocked()
    signal failed()

    function requestUnlock() {
        if (root.unlockInProgress)
            return ;

        if (root.pamActivated)
            return ;

        if (pam.active)
            return ;

        root.pamActivated = true;
        root.timedOut = false;
        root.showFailure = false;
        timeoutTimer.restart();
        tryUnlock();
    }

    function tryUnlock() {
        if (root.unlockInProgress || pam.active)
            return ;

        root.timedOut = false;
        root.unlockInProgress = true;
        root.showFailure = false;
        root.errorText = "";
        root.currentText = "";
        root.awaitingPasswordPrompt = true;
        root.submitPending = false;
        timeoutTimer.restart();
        if (!pam.start()) {
            timeoutTimer.stop();
            root.unlockInProgress = false;
            root.awaitingPasswordPrompt = false;
            root.errorText = "Could not start authentication";
            root.showFailure = true;
        }
    }

    function cancelPam() {
        timeoutTimer.stop();
        root.timedOut = true;
        if (pam.active)
            pam.abort();

        root.pamActivated = false;
        root.awaitingPasswordPrompt = false;
        root.submitPending = false;
        root.unlockInProgress = false;
        root.showFailure = false;
        root.currentText = "";
        root.errorText = "";
    }

    function submitPassword() {
        if (!root.acceptingPassword)
            return ;

        if (pam.responseRequired && !root.unlockInProgress)
            respondToPam(root.currentText);
        else
            root.submitPending = true;
    }

    function respondToPam(response) {
        if (pam.responseRequired && !root.unlockInProgress && root.acceptingPassword) {
            root.awaitingPasswordPrompt = false;
            root.submitPending = false;
            root.unlockInProgress = true;
            timeoutTimer.restart();
            pam.respond(response);
            root.currentText = "";
        }
    }

    onCurrentTextChanged: {
        if (acceptingPassword)
            timeoutTimer.restart();

    }

    Timer {
        id: timeoutTimer

        interval: 10000
        repeat: false
        onTriggered: cancelPam()
    }

    PamContext {
        id: pam

        configDirectory: "pam"
        config: "quickshell-lock"
        onPamMessage: {
            if (this.responseRequired) {
                root.awaitingPasswordPrompt = false;
                root.unlockInProgress = false;
                timeoutTimer.restart();
                if (root.submitPending)
                    Qt.callLater(root.submitPassword);

            }
        }
        onCompleted: (result) => {
            if (root.timedOut)
                return ;

            root.awaitingPasswordPrompt = false;
            root.submitPending = false;
            timeoutTimer.stop();
            root.unlockInProgress = false;
            root.currentText = "";
            if (result == PamResult.Success) {
                root.unlocked();
            } else {
                root.showFailure = true;
                root.failed();
            }
        }
        onError: (error) => {
            if (root.timedOut)
                return ;

            root.awaitingPasswordPrompt = false;
            root.submitPending = false;
            timeoutTimer.stop();
            root.currentText = "";
            root.unlockInProgress = false;
            root.errorText = "Authentication error; press Enter to retry or Esc to cancel";
            root.showFailure = true;
        }
    }

}
