pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: root

    required property var config
    required property var targetScreen

    readonly property ClipboardPanel panel: panelLoader.active ? panelLoader.item as ClipboardPanel : null
    readonly property bool opened: panel ? panel.opened : false

    function open(): void {
        // Construct synchronously; the panel is destroyed again after it closes.
        panelLoader.active = true;
        panel.open();
    }

    function toggle(): void {
        opened ? close() : open();
    }

    function close(): void {
        if (panel)
            panel.close();
    }

    function refresh(): void {
        if (panel)
            panel.refresh();
    }

    function copySelected(): void {
        if (panel)
            panel.copySelected();
    }

    function deleteSelected(): void {
        if (panel)
            panel.deleteSelected();
    }

    LazyLoader {
        id: panelLoader
        active: false

        ClipboardPanel {
            config: root.config
            targetScreen: root.targetScreen

            onCloseFinished: {
                // Detached so the temp preview image is removed even though
                // the panel (and its Process objects) is about to be destroyed.
                Quickshell.execDetached(["rm", "-f", previewPath]);
                // Deferred so the panel isn't destroyed inside its own signal
                // handler; skipped if it was reopened during the fade-out.
                Qt.callLater(() => {
                    if (panelLoader && !opened)
                        panelLoader.active = false;
                });
            }
        }
    }

    IpcHandler {
        target: "clipboard"

        function toggle(): void {
            root.toggle();
        }
        function open(): void {
            root.open();
        }
        function close(): void {
            root.close();
        }
        function refresh(): void {
            root.refresh();
        }
        function copySelected(): void {
            root.copySelected();
        }
        function deleteSelected(): void {
            root.deleteSelected();
        }
    }
}
