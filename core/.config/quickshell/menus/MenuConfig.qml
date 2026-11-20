import QtQuick
import Quickshell.Io
import "MenuSchema.js" as Schema

Item {
    id: root
    visible: false
    property var menus: ({
            "user-menu1": [],
            "user-menu2": [],
            "user-menu3": [],
            "user-menu4": []
        })
    property string errorText: ""
    property bool ready: false

    Component.onCompleted: {
        if (!ready)
            applyMenus(menuFile.text());
    }

    function applyMenus(text): void {
        try {
            const parsed = Schema.parse(text);
            errorText = "";
            menus = parsed;
        } catch (error) {
            errorText = "Invalid menus.json: " + error.message;
            console.warn(errorText + "; keeping current menus");
        }
        ready = true;
    }

    FileView {
        id: menuFile
        objectName: "menuConfigurationFile"
        path: Qt.resolvedUrl("../menus.json").toString()
        blockLoading: true
        watchChanges: true
        printErrors: false
        onLoaded: root.applyMenus(text())
        onFileChanged: reload()
        onLoadFailed: {
            root.ready = true;
            root.errorText = "Could not load menus.json; keeping current menus";
            console.warn(root.errorText);
        }
    }
}
