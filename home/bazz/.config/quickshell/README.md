# Quickshell layout

The config is split into four clear layers:

```text
quickshell/
├── shell.qml              # global wiring, IPC and screens
├── Config.qml             # settings: geometry, fonts and current static palette
├── bar/
│   └── Bar.qml            # complete bar module order in one file
├── components/            # reusable UI primitives
├── services/              # long-lived event/state services
└── modules/               # one feature per folder
```

## Bar order

`bar/Bar.qml` is the only place you need to open to see or change what appears
on the bar. It contains LEFT, CENTER and RIGHT rows in display order.

All three rows use:

```qml
spacing: config.barModuleSpacing
```

and the outside bar margin uses:

```qml
config.barEdgeMargin
```

Edit these in `Config.qml`:

```qml
property int barHeight: 34
property int barEdgeMargin: 10
property int barModuleSpacing: 8
property int barItemPadding: 6

property int popupGap: 8
property int popupRadius: 4
property int popupPadding: 12
property int popupItemHeight: 38
property int popupItemSpacing: 2
```

`barItemPadding`, `popupItemHeight`, and `popupItemSpacing` are now named
settings for the next cleanup pass; current modules do not all consume them yet.

## Modules

```text
modules/
├── workspaces/Workspaces.qml
├── window/WindowTitle.qml
├── clock/Clock.qml
├── weather/
│   ├── WeatherData.qml
│   ├── WeatherPopup.qml
│   └── weather.py
├── notifications/Notifications.qml
├── recorder/Recorder.qml
├── network/
│   ├── Network.qml
│   └── Model.js
├── bluetooth/
│   ├── Bluetooth.qml
│   └── Model.js
├── audio/
│   ├── Audio.qml
│   └── Model.js
├── idle/Idle.qml
├── battery/Battery.qml
└── tray/TrayPower.qml
```

The clock is now easy to find. Its hover reveal lives in `clock/Clock.qml`;
weather fetching and the popup live under `weather/`.

## IPC retained

```bash
qs ipc call bar toggle
qs ipc call bar hide
qs ipc call bar show
qs ipc call idle toggle
qs ipc call idle refresh
qs ipc call recorder refresh
```

Pywal is intentionally not part of this refactor yet.
