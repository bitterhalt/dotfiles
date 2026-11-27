import QtQuick

// Personal launcher commands. Add entries here; built-in shell commands live in
// components/QuickshellActions.qml. Each entry needs a category, label, keyword,
// and command. `confirm` is optional and defaults to true. Every entry needs an
// inline category field.
QtObject {
    readonly property var actions: [
        {
            category: "cmd",
            label: "Run Hellwal",
            keyword: "hw",
            command: "hellwal -i ~/.local/share/wall/wallpaper.png --comfort-mode --dark-offset 0.20",
            confirm: false
        },
        {
            category: "cmd",
            label: "mpv (resume)",
            keyword: "mpvr",
            command: "mpv --player-operation-mode=pseudo-gui --script-opts-append=resume=yes",
            confirm: false
        },
        {
            category: "cmd",
            label: "Reload Portals",
            keyword: "reload-portals",
            command: "reload-portals.sh",
            confirm: false
        },
        {
            category: "cmd",
            label: "Arch maintenance",
            keyword: "maintenance",
            command: "$TERMINAL -e arch-maintenance",
            confirm: false
        },
        {
            category: "cmd",
            label: "Toggle Ollama",
            keyword: "ollama",
            command: "toggle_ollama",
            confirm: false
        },
        {
            category: "misc",
            label: "Gif Recorder",
            keyword: "gif",
            command: "wezterm_run --class gifrec -e gif_rec",
            confirm: false
        },
        {
            category: "misc",
            label: "Update System",
            keyword: "sup",
            command: "wezterm_run --class pop-upgrade -e sup",
            confirm: false
        },
        {
            category: "settings",
            label: "Niri Settings",
            keyword: "niri",
            command: "$TERMINAL sh -c 'cd ~/.config/niri/ && nvim *'",
            confirm: false
        },
        {
            category: "settings",
            label: "Nvim Setting",
            keyword: "nvim",
            command: "$TERMINAL sh -c 'cd ~/.config/nvim && vopen .'",
            confirm: false
        },
        {
            category: "settings",
            label: "Hellwal Settings",
            keyword: "hellwal",
            command: "$TERMINAL -e nvim ~/.config/hellwal/templates/*",
            confirm: false
        },
        {
            category: "settings",
            label: "Quickshell Settings",
            keyword: "quickshell",
            command: "$TERMINAL sh -c 'cd ~/.config/quickshell && vopen .'",
            confirm: false
        },
        {
            category: "settings",
            label: "Wezterm Settings",
            keyword: "wezterm",
            command: "$TERMINAL sh -c 'cd ~/.config/wezterm && vopen . *'",
            confirm: false
        },
        {
            category: "settings",
            label: "Launcher Actions",
            keyword: "actions",
            command: "$TERMINAL -e nvim ~/.config/quickshell/launcher/UserActions.qml",
            confirm: false
        },
        {
            category: "sys",
            label: "Bluetooth Off",
            keyword: "bt-off",
            command: "bluetoothctl power off",
            confirm: false
        },
        {
            category: "sys",
            label: "Bluetooth On",
            keyword: "bt-on",
            command: "bluetoothctl power on",
            confirm: false
        },
        {
            category: "sys",
            label: "Bluetooth Settings",
            keyword: "bt-settings",
            command: "wezterm_run --class bluetui -e bluetui",
            confirm: false
        },
        {
            category: "sys",
            label: "Wifi Settings",
            keyword: "wifi-settings",
            command: "wezterm_run --class impala -e impala",
            confirm: false
        },
        {
            category: "sys",
            label: "Install Packages",
            keyword: "packages",
            command: "$TERMINAL --app-id pacseek -e pacseek -m",
            confirm: false
        },
        {
            category: "sys",
            label: "Network Manager",
            keyword: "network",
            command: "$TERMINAL -e nmtui",
            confirm: false
        }
    ]
}
