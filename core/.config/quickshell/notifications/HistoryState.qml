import QtQuick
import "HistoryModel.js" as Model

Item {
    id: root

    required property var notificationService
    readonly property var rows: (notificationService.historyNotifications ?? notificationService.notifications).slice().reverse()
    property string selectedId: ""
    property string expandedId: ""
    property int fallbackIndex: 0
    readonly property int selectedIndex: Model.selectionIndex(rows, selectedId, fallbackIndex)
    readonly property var selectedNotification: selectedIndex >= 0 ? rows[selectedIndex] : null
    readonly property var actions: Model.actionsFor(selectedNotification ? selectedNotification.actions : [])

    signal selectionMoved
    signal closeRequested

    visible: false
    onRowsChanged: {
        // Resolve against the new rows directly: dependent bindings may still
        // hold the previous index while this change handler is running.
        select(Model.selectionIndex(rows, selectedId, fallbackIndex));
        if (expandedId !== "" && !rows.some(row => String(row.id) === expandedId))
            expandedId = "";
        selectionMoved();
    }
    onSelectedIndexChanged: selectionMoved()

    function select(index) {
        if (index < 0 || index >= rows.length) {
            selectedId = "";
            fallbackIndex = 0;
            return;
        }
        fallbackIndex = index;
        selectedId = String(rows[index].id);
        selectionMoved();
    }

    function move(delta) {
        if (rows.length)
            select(Math.max(0, Math.min(rows.length - 1, selectedIndex + delta)));
    }

    function dismissSelected() {
        if (!selectedNotification)
            return;
        fallbackIndex = selectedIndex;
        notificationService.dismiss(selectedNotification);
    }

    function toggleExpanded(id) {
        const key = String(id || "");
        expandedId = expandedId === key ? "" : key;
    }

    function invoke(entry) {
        if (!selectedNotification || !entry)
            return;
        if (entry.dismiss)
            dismissSelected();
        else if (entry.action)
            entry.action.invoke();
    }

    function handleKey(key, modifiers, text) {
        if (key === Qt.Key_X && modifiers === Qt.ControlModifier) {
            notificationService.clearAll();
            return true;
        }
        if (modifiers & (Qt.ControlModifier | Qt.AltModifier | Qt.MetaModifier))
            return false;
        if (key === Qt.Key_Escape) {
            closeRequested();
        } else if (key === Qt.Key_Up || key === Qt.Key_K || key === Qt.Key_Backtab || (key === Qt.Key_Tab && (modifiers & Qt.ShiftModifier))) {
            move(-1);
        } else if (key === Qt.Key_Down || key === Qt.Key_J || key === Qt.Key_Tab) {
            move(1);
        } else if (key === Qt.Key_X) {
            dismissSelected();
        } else if (key === Qt.Key_Return || key === Qt.Key_Enter) {
            // The default may share a label with a visible action and have
            // been deduplicated. Enter still invokes the original default.
            const action = selectedNotification ? selectedNotification.actions.find(action => action.identifier === "default") : null;
            if (action)
                invoke({
                    action: action,
                    dismiss: Model.isCloseAction(action)
                });
        } else {
            const letter = (text || (key >= Qt.Key_A && key <= Qt.Key_Z ? String.fromCharCode(key) : "")).toLowerCase();
            const entry = actions.find(entry => entry.key !== "" && entry.key === letter);
            if (!entry)
                return false;
            invoke(entry);
        }
        return true;
    }
}
