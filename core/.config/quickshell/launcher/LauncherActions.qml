pragma ComponentBehavior: Bound

import QtQuick
import QtQml.Models
import Quickshell.Io
import Qt.labs.folderlistmodel
import "ActionFiles.js" as ActionFiles

// Personal launcher actions live in launcher/actions/<category>.json, one list
// per category. A bad edit keeps that file's last valid entries instead of
// blanking the launcher.
Item {
    id: root

    visible: false

    readonly property url actionsDir: Qt.resolvedUrl("actions")
    property var actions: []
    property var fileNames: []
    property var loaded: ({})

    function applyFile(fileName, text): void {
        try {
            loaded = ActionFiles.load(loaded, fileName, text);
        } catch (error) {
            console.warn("Invalid " + fileName + ": " + error.message + "; keeping current actions");
        }
        rebuild();
    }

    function syncFiles(): void {
        const names = [];
        for (let i = 0; i < folderModel.count; ++i)
            names.push(folderModel.get(i, "fileName"));
        fileNames = names;
        rebuild();
    }

    function rebuild(): void {
        actions = ActionFiles.merge(fileNames, loaded);
    }

    FolderListModel {
        id: folderModel

        folder: root.actionsDir
        nameFilters: ["*.json"]
        showDirs: false
        sortField: FolderListModel.Name
        onCountChanged: root.syncFiles()
        Component.onCompleted: root.syncFiles()
    }

    // FileView is a QObject, so it needs Instantiator rather than Repeater.
    Instantiator {
        model: folderModel

        delegate: FileView {
            required property string fileName

            path: Qt.resolvedUrl("actions/" + fileName).toString()
            blockLoading: true
            watchChanges: true
            printErrors: false
            Component.onCompleted: root.applyFile(fileName, text())
            onFileChanged: reload()
            onLoaded: root.applyFile(fileName, text())
            onLoadFailed: console.warn("Could not load " + fileName + "; keeping current actions")
        }
    }
}
