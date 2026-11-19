pragma ComponentBehavior: Bound

import QtQuick
import "../../../components"

PopoutPanel {
    id: root

    required property var audioItem
    required property var audioService
    required property Component profileBackend
    property bool profilesLoaded: false
    config: audioItem.config
    contentWidth: Math.min(420, audioItem.barWindow.screen ? audioItem.barWindow.screen.width - config.popupGap * 2 : 420)
    padding: 10
    readonly property int rowHeight: popupState.tabIndex === 3 ? 32 : popupState.tabIndex === 2 ? 56 : 44
    readonly property int rowSpacing: 2
    readonly property int chromeHeight: 12 + status.height + root.spacing + footer.height
    readonly property real desiredBodyHeight: popupState.helpOpen ? helpRows.implicitHeight : popupState.contextOpen ? optionRows.implicitHeight : Math.max(rowHeight, popupState.rows.length * (rowHeight + rowSpacing) - rowSpacing)
    readonly property real maximumBodyHeight: Math.max(rowHeight, Math.min(316, root.audioItem.barWindow.screen ? root.audioItem.barWindow.screen.height - root.config.popupGap - root.padding * 2 - chromeHeight - 24 : 316))

    AudioPopupState {
        id: popupState
        objectName: "audioPopupState"
        audioService: root.audioService
        profiles: profileLoader.item
        onTabIndexChanged: if (tabIndex === 3)
            root.profilesLoaded = true
        onCloseRequested: root.audioItem.closePopup()
        onSelectionMoved: selectionViewTimer.restart()
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

    Timer {
        id: selectionViewTimer
        interval: 0
        onTriggered: {
            // ListView geometry can differ by a fraction of a pixel. Don't
            // reposition a short list that already fits in the viewport.
            if (rowsView.contentHeight <= rowsView.height + 1)
                return;
            if (popupState.selectedIndex >= 0)
                rowsView.positionViewAtIndex(popupState.selectedIndex, ListView.Contain);
        }
    }

    // Keyboard navigation, device rows, context actions, and help content.
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
            id: content
            anchors.top: parent.top
            anchors.topMargin: 6
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: status.top
            anchors.bottomMargin: 6

            // Main tab content; row delegate changes by the active tab.
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
                    objectName: "audioRow-" + index
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
                            node: root.audioService.nodeForId(entry.modelData.id)
                            selected: popupState.rows.length > 1 && entry.index === popupState.selectedIndex
                            onPicked: {
                                popupState.selectRow(entry.index);
                                keyboardHandler.forceActiveFocus();
                            }
                            onOptionsRequested: {
                                popupState.selectRow(entry.index);
                                popupState.activateSelected();
                                keyboardHandler.forceActiveFocus();
                            }
                            onMuteRequested: root.audioService.toggleMute(entry.modelData.id)
                            onVolumeRequested: value => root.audioService.setVolume(entry.modelData.id, value)
                        }
                    }
                    Component {
                        id: profileRow
                        ChoiceRow {
                            config: root.config
                            title: (entry.modelData.active ? "✓ " : "") + entry.modelData.name + (entry.modelData.available === false ? " (unavailable)" : "")
                            subtitle: ""
                            selected: popupState.rows.length > 1 && entry.index === popupState.selectedIndex
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
                    text: popupState.tabIndex === 3 ? (popupState.profiles && popupState.profiles.loading ? "Loading audio cards…" : "No audio cards") : popupState.tabIndex === 2 ? "No playback streams" : popupState.tabIndex === 1 ? "No input devices" : "No output devices"
                    color: root.config.muted
                    font.pointSize: root.config.textSizeMedium
                }
            }

            // Actions for the currently selected playback or device row.
            Column {
                id: optionRows
                anchors.left: parent.left
                anchors.right: parent.right
                spacing: 2
                visible: popupState.contextOpen && !popupState.helpOpen
                Repeater {
                    model: popupState.contextActions
                    delegate: ChoiceRow {
                        required property var modelData
                        required property int index
                        width: parent.width
                        height: 32
                        config: root.config
                        title: modelData.name
                        selected: popupState.contextActions.length > 1 && index === popupState.contextIndex
                        onActivated: {
                            popupState.contextIndex = index;
                            popupState.activateSelected();
                            keyboardHandler.forceActiveFocus();
                        }
                    }
                }
            }

            // Keyboard help shown in place of the row list.
            KeyboardHelp {
                id: helpRows
                anchors.left: parent.left
                anchors.right: parent.right
                visible: popupState.helpOpen
                config: root.config
                entries: [
                    {
                        name: "Select row",
                        key: "↑ / ↓   k / j"
                    },
                    {
                        name: "Adjust volume",
                        key: "← / →   h / l"
                    },
                    {
                        name: "Set volume",
                        key: "` / 1–0"
                    },
                    {
                        name: "Toggle mute",
                        key: "m"
                    },
                    {
                        name: "Set default output / input",
                        key: "d"
                    },
                    {
                        name: "Open options",
                        key: "Enter / c"
                    },
                    {
                        name: "Previous tab",
                        key: "Ctrl+← / Shift+Tab / H"
                    },
                    {
                        name: "Next tab",
                        key: "Ctrl+→ / Tab / L"
                    },
                    {
                        name: "Show / hide help",
                        key: "?"
                    },
                    {
                        name: "Back / close",
                        key: "Esc"
                    }
                ]
            }
        }

        // Status line above the tab bar.
        Text {
            id: status
            renderType: Text.NativeRendering
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: footer.top
            anchors.bottomMargin: root.spacing
            height: 18
            text: popupState.helpOpen ? "Volume range: 0–" + Math.round((popupState.tabIndex === 0 ? root.config.maxVolume : Math.min(1, root.config.maxVolume)) * 100) + "% · keyboard step: 5% · ? Close help" : popupState.tabIndex === 3 ? (popupState.profiles && (popupState.profiles.errorText || (popupState.profiles.changing ? "Applying profile…" : "") || (popupState.profiles.loading ? "Loading cards…" : ""))) || (popupState.profileCard ? popupState.profileCard.name + " · Enter Apply · Esc Back" : "Enter Profiles · ? Help") : popupState.contextOpen ? "Options · " + (popupState.selectedRow ? popupState.selectedRow.name : "") + " · Esc Back · ? Help" : "? Help"
            color: popupState.tabIndex === 3 && popupState.profiles && popupState.profiles.errorText ? root.config.urgent : root.config.muted
            font.pointSize: root.config.textSizeSmall
            elide: Text.ElideRight
            verticalAlignment: Text.AlignVCenter

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    popupState.helpOpen = !popupState.helpOpen;
                    keyboardHandler.forceActiveFocus();
                }
            }
        }

        // Footer separator and output/input/playback/profile tabs.
        Item {
            id: footer
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: 26 + root.spacing

            PanelSeparator {
                config: root.config
                anchors.top: parent.top
            }
            Row {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.topMargin: root.spacing
                Repeater {
                    model: popupState.tabs
                    delegate: Item {
                        id: tab
                        required property string modelData
                        required property int index
                        width: parent.width / popupState.tabs.length
                        height: 26
                        readonly property bool highlighted: popupState.tabIndex === index || tabMouse.containsMouse

                        Rectangle {
                            anchors.fill: parent
                            anchors.margins: 2
                            radius: 4
                            color: tab.highlighted ? root.config.selectionBackground : "transparent"
                        }
                        Text {
                            renderType: Text.NativeRendering
                            anchors.centerIn: parent
                            objectName: "audioTabLabel-" + tab.modelData
                            text: tab.modelData
                            color: tab.highlighted ? root.config.selectionForeground : root.config.muted
                            font.pointSize: root.config.textSizeMedium
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
        signal activated
        height: root.rowHeight
        opacity: enabled ? 1 : 0.45

        SelectionIndicator {
            objectName: "audioChoiceSelection"
            config: choice.config
            selected: choice.selected
            verticalInset: 3
        }
        Column {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin: 8
            anchors.rightMargin: 8
            anchors.verticalCenter: parent.verticalCenter
            spacing: 0
            Text {
                renderType: Text.NativeRendering
                width: parent.width
                text: choice.title
                color: choiceMouse.containsMouse ? choice.config.selectionBackground : choice.config.fg
                font.pointSize: choice.config.textSizeMedium
                font.weight: choice.selected ? Font.DemiBold : Font.Normal
                elide: Text.ElideRight
            }
            Text {
                renderType: Text.NativeRendering
                width: parent.width
                visible: choice.subtitle !== ""
                text: choice.subtitle
                color: choice.config.muted
                font.pointSize: choice.config.textSizeSmall
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
