import QtQuick
import "Model.js" as Model

Item {
    id: root

    required property var audioItem
    property var profiles: null
    readonly property var tabs: ["Outputs", "Inputs", "Playback", "Config"]
    property int tabIndex: 0
    property string profileCardKey: ""
    readonly property var profileCard: profiles && profileCardKey !== ""
        ? profiles.cards.find(card => card.id === profileCardKey) || null : null
    property string selectedKey: ""
    property bool contextOpen: false
    property int contextIndex: 0
    property bool helpOpen: false
    readonly property var rows: {
        if (tabIndex === 0)
            return audioItem.outputRows;
        if (tabIndex === 1)
            return audioItem.inputRows;
        if (tabIndex === 2)
            return audioItem.streamRows;
        return profileCardKey !== "" ? (profileCard ? profileCard.profiles : [])
            : profiles ? profiles.cards : [];
    }
    readonly property int selectedIndex: {
        if (profileCardKey !== "" && selectedKey === "") {
            const activeIndex = rows.findIndex(row => row.active);
            if (activeIndex >= 0)
                return activeIndex;
        }
        return Model.selectionIndex(rows, selectedKey);
    }
    readonly property var selectedRow: selectedIndex >= 0 ? rows[selectedIndex] : null
    readonly property var contextActions: selectedRow && tabIndex !== 3 ? (
        selectedRow.kind === "playback" || selectedRow.active
            ? [{name: "Toggle mute", action: "mute"}]
            : [{name: "Toggle mute", action: "mute"}, {name: "Set as default", action: "default"}]
    ) : []
    readonly property string title: helpOpen ? "Audio help"
        : contextOpen ? "Options · " + (selectedRow ? selectedRow.name : "")
        : profileCard ? profileCard.name
        : tabs[tabIndex]

    signal selectionMoved()
    signal closeRequested()

    visible: false
    onSelectedIndexChanged: selectionMoved()
    onContextActionsChanged: contextIndex = Math.max(0, Math.min(contextIndex, contextActions.length - 1))
    onRowsChanged: {
        if (profileCardKey !== "")
            Qt.callLater(root.checkProfileCard);
        // Never silently retarget an open action menu when a device disappears.
        if (contextOpen && !rows.some(row => String(row.id) === selectedKey))
            contextOpen = false;
        selectionMoved();
    }

    function checkProfileCard() {
        if (profileCardKey !== "" && profiles && !profiles.loading && !profiles.changing && !profileCard) {
            profileCardKey = "";
            selectedKey = "";
        }
    }

    function selectRow(index) {
        if (index < 0 || index >= rows.length)
            return;
        selectedKey = String(rows[index].id);
        selectionMoved();
    }

    function moveSelection(delta) {
        if (contextOpen) {
            contextIndex = Math.max(0, Math.min(contextActions.length - 1, contextIndex + delta));
        } else if (rows.length > 0) {
            selectRow(Math.max(0, Math.min(rows.length - 1, selectedIndex + delta)));
        }
    }

    function setTab(index) {
        if (index < 0 || index >= tabs.length)
            return;
        contextOpen = false;
        helpOpen = false;
        profileCardKey = "";
        tabIndex = index;
        selectedKey = "";
        selectionMoved();
    }

    function cycleTab(delta) {
        setTab((tabIndex + delta + tabs.length) % tabs.length);
    }

    function setDefault() {
        if (!selectedRow || selectedRow.active || tabIndex === 3)
            return;
        if (selectedRow.kind === "output")
            audioItem.setOutput(selectedRow.id);
        else if (selectedRow.kind === "input")
            audioItem.setInput(selectedRow.id);
    }

    function toggleMute() {
        if (selectedRow && tabIndex !== 3)
            audioItem.toggleMute(selectedRow.id);
    }

    function adjustVolume(delta) {
        if (selectedRow && tabIndex !== 3)
            audioItem.adjustVolume(selectedRow.id, delta);
    }

    function activateSelected() {
        if (tabIndex === 3) {
            if (!selectedRow || !profiles || profiles.changing)
                return;
            if (profileCardKey === "") {
                const card = selectedRow.id;
                selectedKey = "";
                profileCardKey = card;
                selectionMoved();
            } else if (selectedRow.available) {
                if (selectedRow.active)
                    leaveProfiles();
                else
                    profiles.setProfile(profileCardKey, selectedRow.id);
            }
        } else if (contextOpen) {
            const action = contextActions[contextIndex];
            contextOpen = false;
            if (action && action.action === "mute")
                toggleMute();
            else if (action)
                setDefault();
        } else if (selectedRow) {
            selectedKey = String(selectedRow.id);
            contextIndex = 0;
            contextOpen = true;
        }
    }

    function leaveProfiles() {
        const card = profileCardKey;
        profileCardKey = "";
        selectedKey = card;
        selectionMoved();
    }

    Connections {
        target: root.profiles
        function onProfileApplied(cardName) {
            if (root.profileCardKey === cardName)
                root.leaveProfiles();
        }
    }

    function goBack() {
        if (helpOpen)
            helpOpen = false;
        else if (contextOpen)
            contextOpen = false;
        else if (profileCardKey !== "")
            leaveProfiles();
        else
            closeRequested();
    }

    function handleKey(key, modifiers, text) {
        if (modifiers & (Qt.ControlModifier | Qt.AltModifier | Qt.MetaModifier))
            return false;
        if (key === Qt.Key_Escape) {
            goBack();
        } else if (key === Qt.Key_Question || text === "?") {
            helpOpen = !helpOpen;
        } else if (key === Qt.Key_Backtab || (key === Qt.Key_Tab && (modifiers & Qt.ShiftModifier))
                || (key === Qt.Key_H && (modifiers & Qt.ShiftModifier))) {
            cycleTab(-1);
        } else if (key === Qt.Key_Tab || (key === Qt.Key_L && (modifiers & Qt.ShiftModifier))) {
            cycleTab(1);
        } else if (helpOpen) {
            return false;
        } else if (tabIndex === 3 && key === Qt.Key_R) {
            if (profiles)
                profiles.refresh();
        } else if (key === Qt.Key_Up || key === Qt.Key_K) {
            moveSelection(-1);
        } else if (key === Qt.Key_Down || key === Qt.Key_J) {
            moveSelection(1);
        } else if (key === Qt.Key_Return || key === Qt.Key_Enter || key === Qt.Key_C) {
            activateSelected();
        } else if (contextOpen) {
            return false;
        } else if (key === Qt.Key_Left || key === Qt.Key_H) {
            adjustVolume(-0.05);
        } else if (key === Qt.Key_Right || key === Qt.Key_L) {
            adjustVolume(0.05);
        } else if (key === Qt.Key_M) {
            toggleMute();
        } else if (key === Qt.Key_D) {
            setDefault();
        } else {
            return false;
        }
        return true;
    }
}
