pragma ComponentBehavior: Bound

import QtQuick
import "../../../components"

PopoutPanel {
    id: root

    required property var audioItem
    required property Component profileBackend
    property bool profilesLoaded: false
    config: audioItem.config
    contentWidth: Math.min(440, audioItem.barWindow.screen
        ? audioItem.barWindow.screen.width - config.popupGap * 2 : 440)
    padding: 10
    readonly property int rowHeight: popupState.tabIndex === 3 ? 48 : 60
    readonly property int rowSpacing: 4
    readonly property int chromeHeight: 90
    readonly property real desiredBodyHeight: popupState.helpOpen ? helpRows.implicitHeight
        : popupState.contextOpen ? optionRows.implicitHeight
        : Math.max(rowHeight, popupState.rows.length * (rowHeight + rowSpacing) - rowSpacing)
    readonly property real maximumBodyHeight: Math.max(rowHeight, Math.min(316,
        root.audioItem.barWindow.screen
            ? root.audioItem.barWindow.screen.height - root.config.popupGap - root.padding * 2 - chromeHeight - 24
            : 316))

    AudioPopupState {
        id: popupState
        objectName: "audioPopupState"
        audioItem: root.audioItem
        profiles: profileLoader.item
        onTabIndexChanged: if (tabIndex === 3) root.profilesLoaded = true
        onCloseRequested: root.audioItem.closePopup()
        onSelectionMoved: Qt.callLater(() => {
            if (popupState.selectedIndex >= 0)
                rowsView.positionViewAtIndex(popupState.selectedIndex, ListView.Contain);
        })
    }

    Loader {
        id: profileLoader
        active: root.profilesLoaded
        sourceComponent: root.profileBackend
        visible: false
    }

    Binding {
        target: profileLoader.item
        property: "active"
        value: popupState.tabIndex === 3
        when: profileLoader.item !== null
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
            height: 24

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
                text: popupState.contextOpen || popupState.helpOpen || popupState.profileCardKey !== ""
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
                        if (popupState.contextOpen || popupState.helpOpen || popupState.profileCardKey !== "")
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
                spacing: root.rowSpacing
                model: popupState.rows
                keyNavigationEnabled: false
                cacheBuffer: 80
                delegate: Item {
                    id: entry
                    required property var modelData
                    required property int index
                    width: rowsView.width
                    height: root.rowHeight
                    Loader {
                        anchors.fill: parent
                        sourceComponent: popupState.tabIndex === 3 ? profileRow : volumeRow
                    }
                    Component {
                        id: volumeRow
                        AudioVolumeRow {
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
                    }
                    Component {
                        id: profileRow
                        ChoiceRow {
                            config: root.config
                            title: entry.modelData.name + (entry.modelData.available === false ? " (unavailable)" : "")
                            subtitle: entry.modelData.kind === "card" ? entry.modelData.media
                                : entry.modelData.active ? "Active" : ""
                            selected: entry.index === popupState.selectedIndex
                            enabled: entry.modelData.available !== false && !(popupState.profiles && popupState.profiles.changing)
                            onActivated: {
                                popupState.selectRow(entry.index);
                                popupState.activateSelected();
                                keyboardHandler.forceActiveFocus();
                            }
                        }
                    }
                }
                Text {
                    renderType: Text.NativeRendering
                    anchors.centerIn: parent
                    visible: popupState.rows.length === 0
                    text: popupState.tabIndex === 3
                        ? (popupState.profiles && popupState.profiles.loading ? "Loading audio cards…" : "No audio cards")
                        : popupState.tabIndex === 2 ? "No playback streams"
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
                        {name: "Refresh Config", key: "r"},
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
            height: 18
            text: popupState.helpOpen ? "Volume range: 0–150% · keyboard step: 5%"
                : popupState.tabIndex === 3
                    ? (popupState.profiles && (popupState.profiles.errorText
                        || (popupState.profiles.changing ? "Applying profile…" : "")
                        || (popupState.profiles.loading ? "Loading cards…" : "")))
                        || (popupState.profileCardKey !== "" ? "Enter Apply profile · Esc Back" : "Enter Profiles · r Refresh")
                : popupState.selectedRow && popupState.selectedRow.kind !== "playback" && !popupState.selectedRow.active
                    ? "← → Volume · m Mute · d Default · Enter Options"
                    : "← → Volume · m Mute · Enter Options"
            color: popupState.tabIndex === 3 && popupState.profiles && popupState.profiles.errorText
                ? root.config.urgent : root.config.muted
            font.pointSize: root.config.fontSize(0.72)
            elide: Text.ElideRight
            verticalAlignment: Text.AlignVCenter
        }

        Item {
            id: footer
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: 30

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
                            color: popupState.tabIndex === tab.index ? root.config.bg
                                : tabMouse.containsMouse ? root.config.borderColor : "transparent"
                            border.width: 1
                            border.color: popupState.tabIndex === tab.index
                                ? root.config.accent : root.config.borderColor
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
        property string subtitle: ""
        property bool selected: false
        signal activated()
        height: 50
        opacity: enabled ? 1 : 0.45

        Rectangle {
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.topMargin: 6
            anchors.bottomMargin: 6
            width: 2
            radius: 1
            color: choice.config.accent
            visible: choice.selected
        }
        Column {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin: 12
            anchors.rightMargin: 8
            anchors.verticalCenter: parent.verticalCenter
            spacing: 2
            Text {
                renderType: Text.NativeRendering
                width: parent.width
                text: choice.title
                color: choiceMouse.containsMouse ? Qt.lighter(choice.config.fg, 1.15) : choice.config.fg
                font.pointSize: choice.config.fontSize(0.88)
                font.weight: choice.selected ? Font.DemiBold : Font.Normal
                elide: Text.ElideRight
            }
            Text {
                renderType: Text.NativeRendering
                width: parent.width
                visible: choice.subtitle !== ""
                text: choice.subtitle
                color: choice.config.muted
                font.pointSize: choice.config.fontSize(0.74)
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
