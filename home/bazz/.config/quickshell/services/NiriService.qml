import QtQuick
import Quickshell.Io

Item {
    id: service

    // Niri state is fed by one long-running IPC event stream.
    // This avoids polling workspaces/focused-window every ~1 second.
    property var workspaces: []
    property var windows: ({
    })
    property int focusedWindowId: -1
    readonly property string focusedOutput: {
        for (let i = 0; i < workspaces.length; ++i) {
            if (workspaces[i].is_focused)
                return workspaces[i].output || ""
        }

        return ""
    }

    function updateWorkspaceActivation(id, focused) {
        let target = null;
        for (let i = 0; i < workspaces.length; ++i) {
            if (workspaces[i].id === id) {
                target = workspaces[i];
                break;
            }
        }
        if (!target)
            return ;

        const updated = [];
        for (let i = 0; i < workspaces.length; ++i) {
            const old = workspaces[i];
            const ws = Object.assign({
            }, old);
            if (ws.output === target.output)
                ws.is_active = ws.id === id;

            if (focused)
                ws.is_focused = ws.id === id;

            updated.push(ws);
        }
        workspaces = updated;
    }

    function updateWorkspaceUrgency(id, urgent) {
        const updated = [];
        for (let i = 0; i < workspaces.length; ++i) {
            const ws = Object.assign({
            }, workspaces[i]);
            if (ws.id === id)
                ws.is_urgent = urgent;

            updated.push(ws);
        }
        workspaces = updated;
    }

    function replaceWindows(newWindows) {
        const next = {
        };
        let focused = -1;
        for (let i = 0; i < newWindows.length; ++i) {
            const win = newWindows[i];
            next[win.id] = win;
            if (win.is_focused)
                focused = win.id;

        }
        windows = next;
        focusedWindowId = focused;
    }

    function updateWindow(win) {
        const next = Object.assign({
        }, windows);
        next[win.id] = win;
        windows = next;
        if (win.is_focused)
            focusedWindowId = win.id;

    }

    function removeWindow(id) {
        const next = Object.assign({
        }, windows);
        delete next[id];
        windows = next;
        if (focusedWindowId === id)
            focusedWindowId = -1;

    }

    function handleNiriEvent(line) {
        if (!line || !line.trim())
            return ;

        try {
            const event = JSON.parse(line);
            if (event.WorkspacesChanged) {
                workspaces = event.WorkspacesChanged.workspaces || [];
                return ;
            }
            if (event.WorkspaceActivated) {
                updateWorkspaceActivation(
                    event.WorkspaceActivated.id,
                    event.WorkspaceActivated.focused === true
                );
                return ;
            }
            if (event.WorkspaceUrgencyChanged) {
                updateWorkspaceUrgency(event.WorkspaceUrgencyChanged.id, event.WorkspaceUrgencyChanged.urgent);
                return ;
            }
            if (event.WindowsChanged) {
                replaceWindows(event.WindowsChanged.windows || []);
                return ;
            }
            if (event.WindowOpenedOrChanged) {
                updateWindow(event.WindowOpenedOrChanged.window);
                return ;
            }
            if (event.WindowClosed) {
                removeWindow(event.WindowClosed.id);
                return ;
            }
            if (event.WindowFocusChanged) {
                focusedWindowId = event.WindowFocusChanged.id ?? -1;
                return ;
            }
        } catch (error) {
            console.warn("Could not parse niri event:", error);
        }
    }

    visible: false

    Process {
        id: niriEvents

        running: true
        command: ["niri", "msg", "--json", "event-stream"]

        stdout: SplitParser {
            onRead: (data) => {
                return service.handleNiriEvent(data);
            }
        }

    }

}
