import QtQuick
import Quickshell.Io
import "LauncherActionsSchema.js" as Schema

// Personal launcher actions live in root launcher-actions.json. Like menus,
// invalid edits keep the last valid list instead of blanking the launcher.
Item {
    id: root

    visible: false

    property var actions: []
    property string errorText: ""
    property bool ready: false

    Component.onCompleted: {
        if (!ready)
            applyActions(actionFile.text());
    }

    function applyActions(text): void {
        try {
            root.actions = Schema.parse(text);
            errorText = "";
        } catch (error) {
            errorText = "Invalid launcher-actions.json: " + error.message;
            console.warn(errorText + "; keeping current actions");
        }
        ready = true;
    }

    FileView {
        id: actionFile

        objectName: "launcherActionsFile"
        path: Qt.resolvedUrl("../launcher-actions.json").toString()
        blockLoading: true
        watchChanges: true
        printErrors: false
        onLoaded: root.applyActions(text())
        onFileChanged: reload()
        onLoadFailed: {
            root.ready = true;
            root.errorText = "Could not load launcher-actions.json; keeping current actions";
            console.warn(root.errorText);
        }
    }
}
