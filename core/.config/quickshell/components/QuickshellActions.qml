import QtQuick

// Built-in actions for the shell's own graphical commands. Kept separate from
// the user's launcher/UserActions.qml so other menus and widgets can reuse them.
QtObject {
    readonly property var actions: [
        {
            category: "quickshell",
            label: "Reboot",
            keyword: "reboot",
            command: "qs ipc call power reboot",
            confirm: true,
            icon: "settings"
        },
        {
            category: "quickshell",
            label: "Shut down",
            keyword: "shutdown",
            command: "qs ipc call power shutdown",
            confirm: true,
            icon: "settings"
        },
        {
            category: "quickshell",
            label: "zZz",
            keyword: "sleep",
            command: "qs ipc call power suspend",
            confirm: true,
            icon: "settings"
        },
        {
            category: "quickshell",
            label: "Exit",
            keyword: "logout",
            command: "qs ipc call power exit",
            confirm: true,
            icon: "settings"
        },
        {
            category: "quickshell",
            label: "Lock Screen",
            keyword: "lock",
            command: "qs ipc call lock lock",
            confirm: false,
            icon: "settings"
        },
        {
            category: "quickshell",
            label: "Set Wallpaper",
            keyword: "wallpaper",
            command: "qs ipc call wallpaper open",
            confirm: false,
            icon: "settings"
        },
        {
            category: "quickshell",
            label: "Settings (GUI)",
            keyword: "settings",
            command: "qs ipc call settings toggle",
            confirm: false,
            icon: "settings"
        },
        {
            category: "quickshell",
            label: "Updates",
            keyword: "updates",
            command: "qs ipc call updates toggle",
            confirm: false,
            icon: "settings"
        },
        {
            category: "quickshell",
            label: "Record Fullscreen",
            keyword: "rec",
            command: "qs ipc call recorder fullscreen",
            confirm: false,
            icon: "settings"
        },
        {
            category: "quickshell",
            label: "Record Region",
            keyword: "recregion",
            command: "qs ipc call recorder region",
            confirm: false,
            icon: "settings"
        },
        {
            category: "quickshell",
            label: "Stop Recording",
            keyword: "recstop",
            command: "qs ipc call recorder stop",
            confirm: false,
            icon: "settings"
        }
    ]
}
