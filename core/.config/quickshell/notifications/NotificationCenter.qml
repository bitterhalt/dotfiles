pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Services.Notifications
import "../components"
import "HistoryModel.js" as HistoryModel

FocusScope {
    id: root

    required property var config
    required property var notificationService
    property real availableWidth: 0
    property real availableHeight: 0
    readonly property real popupWidth: availableWidth > 0 ? Math.max(1, Math.min(380, availableWidth - config.popupGap * 2)) : 380
    readonly property real maxPopupHeight: availableHeight > 0 ? Math.max(120, Math.min(availableHeight - config.popupGap * 2, availableHeight * 0.65)) : 520
    readonly property int popupPadding: config.panelPadding

    signal closeRequested

    implicitWidth: popupWidth
    implicitHeight: HistoryModel.historyWindowHeight(config, history.rows.length, historyFooter.height, popupPadding, list.spacing, maxPopupHeight)
    width: implicitWidth
    height: implicitHeight
    focus: true
    Component.onCompleted: Qt.callLater(() => forceActiveFocus())
    Keys.onPressed: event => {
        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            const selectedCard = list.itemAtIndex(history.selectedIndex);
            if (selectedCard && selectedCard.expandableBody) {
                history.toggleExpanded(selectedCard.notification.id);
                event.accepted = true;
                return;
            }
        }
        if (history.handleKey(event.key, event.modifiers, event.text))
            event.accepted = true;
    }

    function keepSelectionVisible() {
        if (history.selectedIndex < 0 || history.selectedIndex >= list.count)
            return;

        const item = list.itemAtIndex(history.selectedIndex);
        if (!item) {
            list.positionViewAtIndex(history.selectedIndex, ListView.Contain);
            return;
        }

        const viewTop = list.contentY;
        const viewBottom = viewTop + list.height;
        if (item.height >= list.height)
            list.contentY = item.y;
        else if (item.y < viewTop)
            list.contentY = item.y;
        else if (item.y + item.height > viewBottom)
            list.contentY = item.y + item.height - list.height;
    }

    function historyIconSource(notification) {
        return HistoryModel.appIconSource(notification, (name, fallback) => Quickshell.iconPath(name, fallback));
    }

    HistoryState {
        id: history
        objectName: "historyState"
        notificationService: root.notificationService
        onSelectionMoved: Qt.callLater(root.keepSelectionVisible)
        onCloseRequested: root.closeRequested()
    }

    PanelSurface {
        anchors.fill: parent
        config: root.config
    }

    // Scrollable history; selecting a card exposes its actions inline.
    ListView {
        id: list
        objectName: "historyList"
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: historyFooter.top
        anchors.leftMargin: root.popupPadding
        anchors.rightMargin: root.popupPadding
        anchors.topMargin: root.popupPadding
        anchors.bottomMargin: 8
        visible: count > 0
        clip: true
        spacing: 4
        keyNavigationEnabled: false
        onCountChanged: Qt.callLater(root.keepSelectionVisible)

        // Preserve delegates when notifications arrive or disappear.
        model: ScriptModel {
            values: history.rows
        }

        delegate: HistoryCard {
            id: card
            required property var modelData
            required property int index

            width: list.width
            config: root.config
            notification: modelData
            selected: index === history.selectedIndex
            expanded: String(modelData.id) === history.expandedId
            critical: modelData.urgency === NotificationUrgency.Critical
            timeLabel: root.notificationService.timeLabel(modelData)
            appIconSource: root.historyIconSource(modelData)
            actionEntries: HistoryModel.actionsFor(modelData.actions)
            onHeightChanged: if (selected)
                Qt.callLater(root.keepSelectionVisible)
            onPicked: {
                history.select(index);
                root.forceActiveFocus();
            }
            onExpandRequested: history.toggleExpanded(modelData.id)
            onActionRequested: entry => {
                history.select(index);
                history.invoke(entry);
                root.forceActiveFocus();
            }
        }
    }

    Text {
        anchors.centerIn: list
        visible: history.rows.length === 0
        renderType: Text.NativeRendering
        text: "No notifications"
        color: root.config.muted
        font.pointSize: root.config.textSizeMedium
    }

    // Clear action and the DND toggle.
    Item {
        id: historyFooter
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: root.popupPadding
        height: Math.max(clearAllButton.implicitHeight, dndControls.implicitHeight) + 8

        PanelSeparator {
            config: root.config
            anchors.top: parent.top
        }

        ShellButton {
            id: clearAllButton
            objectName: "notificationClearAllButton"
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.topMargin: 8
            config: root.config
            compact: true
            filled: true
            opacity: hovered ? 0.8 : 1
            visible: history.rows.length > 0
            text: "Clear all"
            onClicked: {
                root.notificationService.clearAll();
                root.forceActiveFocus();
            }
        }

        Row {
            id: dndControls
            anchors.right: parent.right
            anchors.verticalCenter: clearAllButton.verticalCenter
            spacing: 8

            Text {
                anchors.verticalCenter: parent.verticalCenter
                visible: root.notificationService.dnd
                renderType: Text.NativeRendering
                text: "DND"
                color: root.notificationService.dnd ? root.config.selectionBackground : root.config.muted
                font.pointSize: root.config.textSizeSmall
            }

            ToggleSwitch {
                id: dndSwitch
                config: root.config
                checked: root.notificationService.dnd
                opacity: checked ? 1 : 0.65
                onToggled: {
                    root.notificationService.toggleDnd();
                    root.forceActiveFocus();
                }
            }
        }
    }
}
