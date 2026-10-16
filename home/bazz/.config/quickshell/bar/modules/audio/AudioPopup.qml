pragma ComponentBehavior: Bound

import QtQuick
import "../../../components"

PopoutPanel {
    id: root

    required property var audioItem
    config: audioItem.config
    contentWidth: Math.min(440, audioItem.barWindow.screen
        ? audioItem.barWindow.screen.width - config.popupGap * 2 : 440)
    padding: 12
    readonly property int chromeHeight: 98
    readonly property real desiredBodyHeight: popupState.helpOpen ? helpRows.implicitHeight
        : popupState.contextOpen ? optionRows.implicitHeight
        : Math.max(76, popupState.rows.length * 80 - 4)
    readonly property real maximumBodyHeight: Math.max(76, Math.min(396,
        root.audioItem.barWindow.screen
            ? root.audioItem.barWindow.screen.height - root.config.popupGap - root.padding * 2 - chromeHeight - 24
            : 396))

    AudioPopupState {
        id: popupState
        objectName: "audioPopupState"
        audioItem: root.audioItem
        onCloseRequested: root.audioItem.closePopup()
        onSelectionMoved: Qt.callLater(() => {
            if (popupState.selectedIndex >= 0)
                rowsView.positionViewAtIndex(popupState.selectedIndex, ListView.Contain);
        })
    }

    FocusScope {
        id: keyboardHandler
        objectName: "audioKeyboard"
        width: parent.width
        height: root.chromeHeight + Math.min(root.desiredBodyHeight, root.maximumBodyHeight)
        focus: true
        Component.onCompleted: Qt.callLater(() => forceActiveFocus())
        Keys.onPressed: event => {
            if (popupState.handleKey(event.key, event.modifiers, event.text))
                event.accepted = true;
        }

        Item {
            id: header
            anchors.left: parent.left
            anchors.right: parent.right
            height: 28

            Text {
                renderType: Text.NativeRendering
                anchors.left: parent.left
                anchors.leftMargin: 6
                anchors.right: helpHint.left
                anchors.rightMargin: 8
                anchors.verticalCenter: parent.verticalCenter
                text: popupState.title
                elide: Text.ElideRight
                color: root.config.fg
                font.pointSize: root.config.fontSize(0.94)
                font.weight: Font.DemiBold
            }
            Text {
                id: helpHint
                renderType: Text.NativeRendering
                anchors.right: parent.right
                anchors.rightMargin: 6
                anchors.verticalCenter: parent.verticalCenter
                text: popupState.contextOpen || popupState.helpOpen
                    ? "Esc Back" : "? Help · Esc Close"
                color: helpMouse.containsMouse ? root.config.fg : root.config.muted
                font.pointSize: root.config.fontSize(0.74)
                MouseArea {
                    id: helpMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        keyboardHandler.forceActiveFocus();
                        if (popupState.contextOpen || popupState.helpOpen)
                            popupState.goBack();
                        else
                            popupState.helpOpen = true;
                    }
                }
            }
        }

        Item {
            id: content
            anchors.top: header.bottom
            anchors.topMargin: 6
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: status.top
            anchors.bottomMargin: 6

            ListView {
                id: rowsView
                objectName: "audioRows"
                anchors.fill: parent
                visible: !popupState.contextOpen && !popupState.helpOpen
                clip: true
                spacing: 4
                model: popupState.rows
                keyNavigationEnabled: false
                cacheBuffer: 80
                delegate: AudioVolumeRow {
                    id: entry
                    required property var modelData
                    required property int index
                    width: rowsView.width
                    height: 76
                    config: root.config
                    row: entry.modelData
                    node: root.audioItem.nodeForId(entry.modelData.id)
                    selected: entry.index === popupState.selectedIndex
                    onPicked: {
                        popupState.selectRow(entry.index);
                        keyboardHandler.forceActiveFocus();
                    }
                    onOptionsRequested: {
                        popupState.selectRow(entry.index);
                        popupState.activateSelected();
                        keyboardHandler.forceActiveFocus();
                    }
                    onMuteRequested: root.audioItem.toggleMute(entry.modelData.id)
                    onVolumeRequested: value => root.audioItem.setVolume(entry.modelData.id, value)
                }
                Text {
                    renderType: Text.NativeRendering
                    anchors.centerIn: parent
                    visible: popupState.rows.length === 0
                    text: popupState.tabIndex === 2 ? "No playback streams"
                        : popupState.tabIndex === 1
                            ? "No input devices" : "No output devices"
                    color: root.config.muted
                    font.pointSize: root.config.fontSize(0.86)
                }
            }

            Column {
                id: optionRows
                anchors.left: parent.left
                anchors.right: parent.right
                spacing: 4
                visible: popupState.contextOpen && !popupState.helpOpen
                Repeater {
                    model: popupState.contextActions
                    delegate: ChoiceRow {
                        required property var modelData
                        required property int index
                        width: parent.width
                        height: 40
                        config: root.config
                        title: modelData.name
                        selected: index === popupState.contextIndex
                        onActivated: {
                            popupState.contextIndex = index;
                            popupState.activateSelected();
                            keyboardHandler.forceActiveFocus();
                        }
                    }
                }
            }

            Column {
                id: helpRows
                anchors.left: parent.left
                anchors.right: parent.right
                spacing: 8
                visible: popupState.helpOpen
                Repeater {
                    model: [
                        {name: "Select row", key: "↑ / ↓   k / j"},
                        {name: "Adjust volume", key: "← / →   h / l"},
                        {name: "Toggle mute", key: "m"},
                        {name: "Set default output / input", key: "d"},
                        {name: "Open options", key: "Enter / c"},
                        {name: "Previous tab", key: "Shift+Tab / H"},
                        {name: "Next tab", key: "Tab / L"},
                        {name: "Show / hide help", key: "?"},
                        {name: "Back / close", key: "Esc"}
                    ]
                    delegate: Item {
                        id: helpRow
                        required property var modelData
                        width: parent.width
                        height: 20
                        Text {
                            renderType: Text.NativeRendering
                            anchors.left: parent.left
                            anchors.leftMargin: 6
                            text: helpRow.modelData.name
                            color: root.config.fg
                            font.pointSize: root.config.fontSize(0.8)
                        }
                        Text {
                            renderType: Text.NativeRendering
                            anchors.right: parent.right
                            anchors.rightMargin: 6
                            text: helpRow.modelData.key
                            color: root.config.muted
                            font.pointSize: root.config.fontSize(0.78)
                        }
                    }
                }
            }
        }

        Text {
            id: status
            renderType: Text.NativeRendering
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: footer.top
            anchors.bottomMargin: 6
            height: 20
            text: popupState.helpOpen ? "Volume range: 0–150% · keyboard step: 5%"
                : popupState.selectedRow && popupState.selectedRow.kind !== "playback" && !popupState.selectedRow.active
                    ? "← → Volume · m Mute · d Default · Enter Options"
                    : "← → Volume · m Mute · Enter Options"
            color: root.config.muted
            font.pointSize: root.config.fontSize(0.72)
            elide: Text.ElideRight
            verticalAlignment: Text.AlignVCenter
        }

        Item {
            id: footer
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: 32

            Rectangle {
                anchors.top: parent.top
                width: parent.width
                height: 1
                color: root.config.borderColor
            }
            Row {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                Repeater {
                    model: popupState.tabs
                    delegate: Item {
                        id: tab
                        required property string modelData
                        required property int index
                        width: parent.width / popupState.tabs.length
                        height: 26
                        Rectangle {
                            anchors.fill: parent
                            anchors.margins: 2
                            radius: 4
                            color: tabMouse.containsMouse || popupState.tabIndex === tab.index
                                ? root.config.borderColor : "transparent"
                        }
                        Text {
                            renderType: Text.NativeRendering
                            anchors.centerIn: parent
                            text: tab.modelData
                            color: popupState.tabIndex === tab.index ? root.config.accent : root.config.muted
                            font.pointSize: root.config.fontSize(0.82)
                            font.weight: popupState.tabIndex === tab.index ? Font.DemiBold : Font.Normal
                        }
                        MouseArea {
                            id: tabMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                popupState.setTab(tab.index);
                                keyboardHandler.forceActiveFocus();
                            }
                        }
                    }
                }
            }
        }
    }

    component ChoiceRow: Item {
        id: choice
        required property var config
        property string title: ""
        property bool selected: false
        signal activated()
        height: 50

        Rectangle {
            anchors.fill: parent
            radius: 4
            color: choiceMouse.containsMouse || choice.selected ? choice.config.borderColor : "transparent"
            border.width: 1
            border.color: choice.selected ? choice.config.accent : "transparent"
        }
        Column {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins: 8
            anchors.verticalCenter: parent.verticalCenter
            spacing: 2
            Text {
                renderType: Text.NativeRendering
                width: parent.width
                text: choice.title
                color: choice.config.fg
                font.pointSize: choice.config.fontSize(0.88)
                elide: Text.ElideRight
            }
        }
        MouseArea {
            id: choiceMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: choice.activated()
        }
    }
}
