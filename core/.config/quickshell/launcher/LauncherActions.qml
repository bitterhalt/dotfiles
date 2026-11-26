pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Io
import "LauncherActionsSchema.js" as Schema

// Personal launcher actions live in launcher/actions.json. A bad edit keeps the
// last valid entries instead of blanking the launcher.
Item {
    id: root

    visible: false

    property var actions: []

    function applyText(text): void {
        try {
            actions = Schema.parse(text);
        } catch (error) {
            console.warn("Invalid actions.json: " + error.message + "; keeping current actions");
        }
    }

    FileView {
        id: actionsFile

        path: Qt.resolvedUrl("actions.json").toString()
        blockLoading: true
        watchChanges: true
        printErrors: false
        Component.onCompleted: root.applyText(text())
        onFileChanged: reload()
        onLoaded: root.applyText(text())
        onLoadFailed: console.warn("Could not load actions.json; keeping current actions")
    }
}
