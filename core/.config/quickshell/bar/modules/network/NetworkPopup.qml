pragma ComponentBehavior: Bound

import "../../../components"
import QtQuick

// Standalone network popup. The page owns all state and key handling; this
// wrapper only supplies the panel surface and forwards lifecycle signals.
PopoutPanel {
    id: root

    required property var popupManager
    required property var networkService

    readonly property var page: networkPage

    focus: true
    Component.onCompleted: Qt.callLater(() => root.forceActiveFocus())

    // The page gets the first look at every key.
    Keys.onPressed: event => root.page && root.page.handleKey(event)

    NetworkPage {
        id: networkPage

        width: root.width - root.padding * 2
        config: root.config
        network: root.networkService
        popupManager: root.popupManager
        onCloseRequested: root.popupManager.closeHost("network")
        onFocusRequested: Qt.callLater(() => {
            if (root)
                root.forceActiveFocus();
        })
    }
}
