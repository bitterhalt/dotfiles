.pragma library

// Page metadata for the settings window: sidebar labels/icons, which pages are
// saved with Apply (`custom` / `staged`), and the rows each page draws.
// Values are read and written by SettingsMenu.valueOf()/save().
var pages = [
    {
        id: "idle",
        label: "Idle",
        icon: "󰤄",
        custom: true,
        rows: []
    },
    {
        id: "appearance",
        label: "Appearance",
        icon: "󰏘",
        rows: [
            {
                kind: "stepper",
                name: "fontScale",
                label: "Font scale",
                step: 0.1,
                decimals: 1
            },
            {
                kind: "stepper",
                name: "iconScale",
                label: "Icon scale",
                step: 0.1,
                decimals: 1
            },
            {
                kind: "text",
                name: "iconFontFamily",
                label: "Icon font",
                wide: true
            },
            {
                kind: "toggle",
                name: "popupAnimations",
                label: "Animations"
            },
            {
                kind: "stepper",
                name: "popupGap",
                label: "Popup gap",
                step: 2,
                suffix: " px"
            },
            {
                kind: "stepper",
                name: "popupRadius",
                label: "Popup radius",
                suffix: " px"
            }
        ]
    },
    {
        id: "theming",
        label: "Theming",
        icon: "󰃣",
        hint: "Colors are generated from the current wallpaper",
        staged: true,
        rows: [
            {
                kind: "choice",
                name: "hellwalMode",
                label: "Mode",
                options: [
                    {
                        value: "dark",
                        label: "Dark"
                    },
                    {
                        value: "light",
                        label: "Light"
                    }
                ]
            },
            {
                kind: "stepper",
                name: "hellwalDarkOffset",
                label: "Dark offset",
                from: 0,
                to: 1,
                step: 0.05,
                decimals: 2
            },
            {
                kind: "stepper",
                name: "hellwalBrightOffset",
                label: "Bright offset",
                from: 0,
                to: 1,
                step: 0.05,
                decimals: 2
            },
            {
                kind: "stepper",
                name: "hellwalGrayScale",
                label: "Grayscale",
                from: 0,
                to: 1,
                step: 0.05,
                decimals: 2
            },
            {
                kind: "choice",
                name: "hellwalBackgroundMode",
                label: "Background",
                options: [
                    {
                        value: "dynamic",
                        label: "Dynamic"
                    },
                    {
                        value: "fixed",
                        label: "Fixed"
                    }
                ]
            },
            {
                kind: "text",
                name: "hellwalBackgroundColor",
                label: "Fixed color",
                when: {
                    name: "hellwalBackgroundMode",
                    value: "fixed"
                }
            }
        ]
    },
    {
        id: "bar",
        label: "Bar",
        icon: "󰍜",
        rows: [
            {
                kind: "choice",
                name: "barVisible",
                label: "Visibility",
                options: [
                    {
                        value: true,
                        label: "Shown"
                    },
                    {
                        value: false,
                        label: "Hidden"
                    }
                ]
            },
            {
                kind: "choice",
                name: "workspaceLayout",
                label: "Workspace layout",
                options: [
                    {
                        value: "dots",
                        label: "Dots"
                    },
                    {
                        value: "minimal",
                        label: "Minimal"
                    }
                ]
            },
            {
                kind: "stepper",
                name: "barHeight",
                label: "Height",
                step: 2,
                suffix: " px"
            },
            {
                kind: "toggle",
                name: "showTray",
                label: "Show tray"
            },
            {
                kind: "text",
                name: "clockFormat",
                label: "Clock format"
            },
            {
                kind: "text",
                name: "clockAlternativeFormat",
                label: "Alternative format"
            }
        ]
    },
    {
        id: "audio",
        label: "Audio",
        icon: "󰕾",
        hint: "Values above 100% amplify the signal",
        rows: [
            {
                kind: "stepper",
                name: "maxVolume",
                label: "Max volume",
                step: 0.05,
                factor: 100,
                suffix: "%"
            }
        ]
    },
    {
        id: "launcher",
        label: "Launcher",
        icon: "󰀻",
        rows: [
            {
                kind: "toggle",
                name: "launcherEnabled",
                label: "Launcher enabled"
            }
        ]
    },
    {
        id: "notifications",
        label: "Notifications",
        icon: "󰂚",
        hint: "Excluded apps are comma separated app names",
        rows: [
            {
                kind: "integer",
                name: "notificationHistoryLimit",
                label: "History limit"
            },
            {
                kind: "list",
                name: "notificationHistoryExcludedApps",
                label: "Excluded apps"
            }
        ]
    },
    {
        id: "bluetooth",
        label: "Bluetooth",
        icon: "󰂯",
        hint: "0 disables a battery notification",
        rows: [
            {
                kind: "stepper",
                name: "bluetoothBatteryWarningPercent",
                label: "Battery warning",
                step: 5,
                suffix: "%"
            },
            {
                kind: "stepper",
                name: "bluetoothBatteryCriticalPercent",
                label: "Battery critical",
                step: 5,
                suffix: "%"
            },
            {
                kind: "stepper",
                name: "bluetoothBatteryRearmMargin",
                label: "Re-arm margin",
                step: 5,
                suffix: "%"
            }
        ]
    }
]
