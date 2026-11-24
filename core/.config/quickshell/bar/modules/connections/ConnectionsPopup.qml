pragma ComponentBehavior: Bound

import "../../../components"
import "../bluetooth"
import "../network"
import QtQuick

// Bluetooth and network in one popup with a tab bar at the bottom.
// Only the active tab's page exists, so scanning stops when you switch tabs
// or close the popup, exactly like the separate popups did.
PopoutPanel {
    id: root

    required property var popupManager
    required property var bluetoothService
    required property var networkService
    // "bluetooth" or "network"; owned by the bar module.
    required property string tab
    property string selectedAddress: ""

    readonly property bool hasBluetooth: !!bluetoothService.adapter
    readonly property var tabs: hasBluetooth ? [
        {
            key: "network",
            label: "Network"
        },
        {
            key: "bluetooth",
            label: "Bluetooth"
        }
    ] : [
        {
            key: "network",
            label: "Network"
        }
    ]
    // A stale tab (adapter removed) must never load a page that no longer exists.
    readonly property string activeTab: tabs.some(entry => entry.key === tab) ? tab : "network"
    readonly property var page: pageLoader.item
    readonly property bool tabsVisible: tabs.length > 1 && (!page || !page.subpage)

    signal tabRequested(string tab)

    function switchTab(next) {
        if (next !== tab && tabs.some(entry => entry.key === next))
            tabRequested(next);
    }

    focus: true
    Component.onCompleted: Qt.callLater(() => root.forceActiveFocus())

    // The active page gets the first look at every key; Tab switches tabs.
    Keys.onPressed: event => {
        if (root.page && root.page.handleKey(event))
            return;
        if ((event.key === Qt.Key_Tab || event.key === Qt.Key_Backtab) && !(event.modifiers & (Qt.ControlModifier | Qt.AltModifier | Qt.MetaModifier)) && root.tabsVisible) {
            // Follow the visual tab order, so the left icon maps to the left tab.
            const index = root.tabs.findIndex(entry => entry.key === root.activeTab);
            const step = event.key === Qt.Key_Backtab ? -1 : 1;
            root.switchTab(root.tabs[(index + step + root.tabs.length) % root.tabs.length].key);
            event.accepted = true;
        }
    }

    Loader {
        id: pageLoader

        width: parent.width
        height: item ? item.implicitHeight : 0
        sourceComponent: root.activeTab === "network" ? networkPageComponent : bluetoothPageComponent
        onLoaded: Qt.callLater(() => root.forceActiveFocus())
    }

    // Tabs are last, sized like the audio footer tabs.
    Item {
        objectName: "connectionsTabs"
        width: parent.width
        height: tabRow.height + root.spacing
        visible: root.tabsVisible

        PanelSeparator {
            config: root.config
            anchors.top: parent.top
        }

        Row {
            id: tabRow

            anchors.top: parent.top
            anchors.topMargin: root.spacing
            width: parent.width

            Repeater {
                model: root.tabs

                delegate: Item {
                    id: tab

                    required property var modelData
                    width: tabRow.width / root.tabs.length
                    height: 26
                    readonly property bool highlighted: root.activeTab === tab.modelData.key || tabMouse.containsMouse

                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: 2
                        radius: 4
                        color: tab.highlighted ? root.config.selectionBackground : "transparent"
                    }

                    Text {
                        renderType: Text.NativeRendering
                        anchors.centerIn: parent
                        text: tab.modelData.label
                        color: tab.highlighted ? root.config.selectionForeground : root.config.muted
                        font.pointSize: root.config.textSizeMedium
                    }

                    // Mouse-only: keyboard focus stays on the popup, so Enter
                    // never re-clicks the active tab.
                    MouseArea {
                        id: tabMouse

                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.switchTab(tab.modelData.key)
                    }
                }
            }
        }
    }

    Component {
        id: bluetoothPageComponent

        BluetoothPage {
            config: root.config
            bluetoothService: root.bluetoothService
            selectedAddress: root.selectedAddress
            onSelectedAddressChanged: root.selectedAddress = selectedAddress
            onCloseRequested: root.popupManager.closeHost("connections")
            onFocusRequested: Qt.callLater(() => {
                if (root)
                    root.forceActiveFocus();
            })
        }
    }

    Component {
        id: networkPageComponent

        NetworkPage {
            config: root.config
            network: root.networkService
            popupManager: root.popupManager
            onCloseRequested: root.popupManager.closeHost("connections")
            onFocusRequested: Qt.callLater(() => {
                if (root)
                    root.forceActiveFocus();
            })
        }
    }
}
