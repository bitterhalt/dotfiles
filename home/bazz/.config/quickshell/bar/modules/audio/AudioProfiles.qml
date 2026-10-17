import QtQuick
import Quickshell.Io
import "Profiles.js" as Profiles

Item {
    id: root
    objectName: "audioProfiles"
    visible: false

    property bool active: false
    property var cards: []
    readonly property bool loading: listProcess.running
    readonly property bool changing: setProcess.running
    property string readError: ""
    property string applyError: ""
    property string monitorError: ""
    readonly property string errorText: applyError || readError || monitorError
    property string listReply: ""
    property string listStderr: ""
    property string setStderr: ""
    property string pendingCard: ""
    property bool refreshPending: false

    signal profileApplied(string cardName)

    onActiveChanged: {
        if (active) {
            monitorError = "";
            subscription.running = true;
            refresh();
        } else {
            refreshDebounce.stop();
            subscription.running = false;
            refreshPending = false;
        }
    }

    function refresh() {
        if (!active)
            return;
        if (!subscription.running) {
            monitorError = "";
            subscription.running = true;
        }
        if (listProcess.running) {
            refreshPending = true;
            return;
        }
        listReply = "";
        listStderr = "";
        readError = "";
        listProcess.running = true;
    }

    function setProfile(cardName, profileName) {
        if (!active || changing)
            return;
        const card = cards.find(item => item.id === cardName);
        const profile = card ? card.profiles.find(item => item.id === profileName) : null;
        if (!profile || !profile.available || profile.active)
            return;
        applyError = "";
        setStderr = "";
        pendingCard = cardName;
        setProcess.command = ["pactl", "set-card-profile", cardName, profileName];
        setProcess.running = true;
    }

    Timer {
        id: refreshDebounce
        interval: 100
        onTriggered: root.refresh()
    }

    Process {
        id: subscription
        command: ["pactl", "subscribe"]
        environment: ({LC_ALL: "C"})
        stdout: SplitParser {
            onRead: data => {
                if (root.active && Profiles.isCardEvent(data))
                    refreshDebounce.restart();
            }
        }
        stderr: StdioCollector {}
        onExited: {
            if (root.active && !subscription.running)
                root.monitorError = "Profile monitoring stopped · r to refresh";
        }
    }

    Process {
        id: listProcess
        command: ["pactl", "--format=json", "list", "cards"]
        environment: ({LC_ALL: "C"})
        stdout: StdioCollector { onStreamFinished: root.listReply = text }
        stderr: StdioCollector { onStreamFinished: root.listStderr = text.trim() }
        onExited: exitCode => {
            if (exitCode === 0) {
                try {
                    root.cards = Profiles.parse(root.listReply);
                    root.readError = "";
                } catch (error) {
                    root.readError = "Could not read audio card profiles";
                }
            } else if (root.active && root.readError === "") {
                root.readError = root.listStderr || "Could not list audio cards · is pactl installed?";
            }
            if (root.refreshPending) {
                root.refreshPending = false;
                root.refresh();
            }
        }
    }

    Process {
        id: setProcess
        environment: ({LC_ALL: "C"})
        stderr: StdioCollector { onStreamFinished: root.setStderr = text.trim() }
        onExited: exitCode => {
            if (exitCode === 0) {
                root.applyError = "";
                root.refresh();
                root.profileApplied(root.pendingCard);
            } else if (root.applyError === "") {
                root.applyError = root.setStderr || "Could not change audio profile";
            }
        }
    }

    Timer {
        interval: 10000
        running: listProcess.running
        onTriggered: {
            root.readError = "Listing audio profiles timed out";
            listProcess.signal(15);
        }
    }

    Timer {
        interval: 10000
        running: setProcess.running
        onTriggered: {
            root.applyError = "Changing audio profile timed out";
            setProcess.signal(15);
        }
    }

    Component.onDestruction: {
        if (subscription.running)
            subscription.signal(15);
        if (listProcess.running)
            listProcess.signal(15);
        if (setProcess.running)
            setProcess.signal(15);
    }
}
