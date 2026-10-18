# QuickShell Config

A personal [QuickShell](https://quickshell.org/) desktop shell for **Niri + Wayland**.

## Features

- Per-screen bar with workspaces, window title, clock, weather, battery, and system tray
- Keyboard-driven Network and Bluetooth popups, plus PipeWire audio controls
- Keyboard-driven audio tabs: Outputs, Inputs, Playback, and card profiles
- Notifications, history, and do-not-disturb mode
- Bluetooth connection and low-battery alerts
- Application launcher with Apps, Run, Emoji, and Timer modes (`Ctrl+A` / `Ctrl+B` / `Ctrl+E` / `Ctrl+T`, or cycle with `Ctrl+←` / `Ctrl+→`)
- Clipboard history
- Lock screen and power menu
- Idle monitoring with editable timeouts
- Fullscreen and region recording
- Wallpaper picker and Pywal themes
- DeepL translator
- Tmux session manager and process killer
- Keyboard shortcuts and IPC controls

Network and Bluetooth popups can also be opened with `qs ipc call network toggle` and `qs ipc call bluetooth toggle`.

In the launcher, `/needle` searches files and `=expression` calculates with `qalc` (plain math works too). The modes are Apps (desktop entries), Run (binaries, recently used first), Emoji (search by name; Enter copies it), and Timer (`25m Focus`, `45s`, `1:30`, `2h`; selecting a running timer cancels it). Enter activates the selected row and Esc closes.

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
│       │   ├── Model.js
│       │   └── tests/
│       │       └── tst_model.qml
│       ├── clock/
│       │   └── Clock.qml
│       ├── idle/
│       │   ├── Idle.qml
│       │   └── IdleNotifier.qml
│       ├── network/
│       │   ├── Model.js
│       │   ├── Network.qml
│       │   ├── NetworkPopup.qml
│       │   ├── NetworkRow.qml
│       │   └── tests/
│       │       └── tst_model.qml
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
│   ├── ToggleSwitch.qml
│   └── tests/
│       └── tst_popoutpanel.qml
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

- [ ] 1. Some sort of clock popup to replace notications when checking clock in barless mode
- [ ] 2. Weather widget looks overhaul = At the moment it's just copy of Waybar tooltip so it need some makeup
- [ ] 3. Barless mode: Draw a watermark-like text in bottom righ with text "Zen Mode is enabled"
