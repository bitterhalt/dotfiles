import QtQuick
import "../../../components"

Row {
    id: root

    required property var config
    required property var selectedNetwork
    property int selectedIndex: 0
    property bool confirmForget: false

    signal activated(int index)
    signal focused(int index)

    function focusAction(index): void {
        if (index === 0)
            connectAction.forceActiveFocus();
        else if (index === 1)
            forgetAction.forceActiveFocus();
        else
            cancelAction.forceActiveFocus();
    }

    spacing: 6

    ShellButton {
        id: cancelAction
        objectName: "networkBackAction"
        config: root.config
        selected: root.visible && root.selectedIndex === 2
        KeyNavigation.tab: connectAction
        KeyNavigation.backtab: forgetAction
        onActiveFocusChanged: if (activeFocus)
            root.focused(2)
        width: Math.max(26, implicitWidth)
        padding: 0
        leftPadding: 0
        rightPadding: 0
        text: "‹"
        Accessible.name: "Back"
        onClicked: root.activated(2)
    }

    ShellButton {
        id: connectAction
        objectName: "networkConnectAction"
        config: root.config
        outlined: true
        outlineColor: root.config.border
        foregroundColor: !enabled ? root.config.muted : visuallyHighlighted ? root.config.selectionForeground : root.config.muted
        selected: root.visible && root.selectedIndex === 0
        KeyNavigation.tab: forgetAction
        KeyNavigation.backtab: cancelAction
        onActiveFocusChanged: if (activeFocus)
            root.focused(0)
        width: Math.max(0, (root.width - cancelAction.width - root.spacing * 2) / 2)
        text: root.selectedNetwork && root.selectedNetwork.connected ? "Disconnect" : "Connect"
        onClicked: root.activated(0)
    }

    ShellButton {
        id: forgetAction
        objectName: "networkForgetAction"
        config: root.config
        selected: root.visible && root.selectedIndex === 1
        destructive: true
        outlined: true
        outlineColor: root.config.border
        KeyNavigation.tab: cancelAction
        KeyNavigation.backtab: connectAction
        onActiveFocusChanged: if (activeFocus)
            root.focused(1)
        width: connectAction.width
        text: root.confirmForget ? "Confirm" : "Forget"
        onClicked: root.activated(1)
    }
}
