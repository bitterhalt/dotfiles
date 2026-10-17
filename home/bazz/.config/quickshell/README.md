# QuickShell Config

A personal [QuickShell](https://quickshell.org/) desktop shell for **Niri + Wayland**.

## Features

- Per-screen bar with workspaces, window title, clock, weather, battery, and system tray
- Network, Bluetooth, and PipeWire audio controls
- Keyboard-driven audio tabs: Outputs, Inputs, Playback, and card profiles
- Notifications, history, and do-not-disturb mode
- Bluetooth connection and low-battery alerts
- Application launcher with file search, calculator, run, emoji, and timer modes
- Clipboard history
- Lock screen and power menu
- Idle monitoring with editable timeouts
- Fullscreen and region recording
- Wallpaper picker and Pywal themes
- DeepL translator
- Tmux session manager and process killer
- Keyboard shortcuts and IPC controls

## Structure

```text
quickshell/
├── shell.qml
├── Config.qml
├── bar/
│   ├── Bar.qml
│   └── modules/
│       ├── audio/
│       │   ├── Audio.qml
│       │   ├── AudioPopup.qml
│       │   ├── AudioPopupState.qml
│       │   ├── AudioProfiles.qml
│       │   ├── AudioVolumeRow.qml
│       │   ├── Model.js
│       │   ├── Profiles.js
│       │   └── tests/
│       │       ├── AudioFixture.qml
│       │       ├── ProfileFixture.qml
│       │       └── tst_audio.qml
│       ├── battery/
│       │   └── Battery.qml
│       ├── bluetooth/
│       │   ├── Bluetooth.qml
│       │   ├── BluetoothNotifier.qml
│       │   └── Model.js
│       ├── clock/
│       │   └── Clock.qml
│       ├── idle/
│       │   ├── Idle.qml
│       │   └── IdleNotifier.qml
│       ├── network/
│       │   ├── Model.js
│       │   ├── Network.qml
│       │   ├── NetworkPopup.qml
│       │   └── NetworkRow.qml
│       ├── tray/
│       │   ├── Power.qml
│       │   ├── Tray.qml
│       │   └── TrayMenu.qml
│       ├── window/
│       │   └── WindowTitle.qml
│       └── workspaces/
│           └── Workspaces.qml
├── clipboard/
│   └── Clipboard.qml
├── components/
│   ├── PanelSeparator.qml
│   ├── PopoutPanel.qml
│   ├── PopupCatcher.qml
│   ├── PopupManager.qml
│   ├── SectionHeader.qml
│   └── ToggleSwitch.qml
├── launcher/
│   ├── Emoji.js
│   ├── Launcher.qml
│   ├── Scorer.js
│   └── tests/
│       └── tst_emoji.qml
├── lock/
│   ├── LockContext.qml
│   ├── LockSurface.qml
│   ├── lock.sh
│   └── pam/
│       └── quickshell-lock
├── lock.qml
├── lock-test.qml
├── menus/
│   ├── IdleSettings.qml
│   ├── MainMenu.qml
│   ├── ProcessMenu.qml
│   ├── processes.py
│   ├── ThemeMenu.qml
│   ├── TmuxMenu.qml
│   └── WallpaperMenu.qml
├── notifications/
│   ├── NotificationCard.qml
│   ├── NotificationCenter.qml
│   ├── NotificationIndicator.qml
│   └── NotificationPopup.qml
├── osd/
│   └── VolumeOsd.qml
├── recorder/
│   ├── Recorder.qml
│   └── RegionSelector.qml
├── services/
│   ├── BatteryService.qml
│   ├── BluetoothService.qml
│   ├── IdleService.qml
│   ├── LockService.qml
│   ├── NiriService.qml
│   ├── NotificationService.qml
│   ├── RecorderService.qml
│   ├── ShellUiService.qml
│   ├── ThemeService.qml
│   ├── TimerService.qml
│   ├── WeatherService.qml
│   ├── bluetooth/
│   │   ├── BatteryWarning.js
│   │   └── tests/
│   │       └── tst_batterywarning.qml
│   └── idle/
│       ├── Duration.js
│       ├── suspend.sh
│       └── tests/
│           └── tst_duration.qml
├── translator/
│   ├── Languages.js
│   ├── Translator.qml
│   ├── TranslatorButton.qml
│   ├── TranslatorWindow.qml
│   ├── deepl.py
│   ├── test_deepl.py
│   └── tests/
│       └── tst_languages.qml
├── wallpaper/
│   ├── Wallpaper.qml
│   ├── setbg.py
│   └── test_setbg.py
└── weather/
    ├── WeatherPopup.qml
    └── weather.py
```

## Requirements

QuickShell, Niri, PipeWire, NetworkManager, BlueZ, and UPower.

Feature helpers use Python, `wl-clipboard`, `cliphist`, `gpu-screen-recorder`, ImageMagick, `awww`, and Pywal. Audio card profiles require `pactl` and PipeWire's PulseAudio compatibility service. The translator requires `DEEPL_API` in the shell's environment.

## Transparency

This shell was developed with LLM assistance under my supervision. I direct the design, review the changes, and test them on my own desktop. These are personal dotfiles, so review and adapt them before using them on yours.

## TODO

- [ ] Make remaining bar popups keyboard-driven: Bluetooth and Network
- [ ] Weather widget looks overhaul = At the moment it's just copy of Waybar tooltip so it need some makeup
