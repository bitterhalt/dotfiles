# Slimshell

Slimshell combines my bar, notifications, and menus. It replaces several separate tools and Bash scripts.

## Why?

Many Quickshell setups use large Material Design menus and features I never touch. Slimshell keeps menus small and keyboard-driven. Every control works from the keyboard, and the Bluetooth and Wi-Fi menus take only the space they need.

## Features

|              | What's included                                                                                                 |
| ------------ | --------------------------------------------------------------------------------------------------------------- |
| **Bar**      | Workspaces, Window title, Clock, Weather, Battery, Connections, Privacy indicators, Removable drives, Tray etc. |
| **Menus**    | Keyboard-driven menus for Bluetooth and Wi-Fi (one tabbed popup), Audio, and Notifications                      |
| **Launcher** | Dmenu-compatible app launcher with modes for File search, Calculator, Emojis, and Quick actions                 |
| **Tools**    | Clipboard, DeepL translation, Screen recording, Update checker                                                  |
| **Session**  | Lock screen, Wallpaper picker, Dynamic theming with [Hellwal](https://hellwal.danihek.xyz/)                     |

<details>
<summary>IPC reference</summary>

| Target               | Calls                                                                               | Effect                                                             |
| -------------------- | ----------------------------------------------------------------------------------- | ------------------------------------------------------------------ |
| `audio`              | `toggle`, `open`, `close`                                                           | Show or hide the audio menu                                        |
| `bar`                | `toggle`, `hide`, `show`, `isVisible`                                               | Control or query bar visibility; the state persists                |
| `bluetooth`          | `toggle`, `open`, `close`                                                           | Show or hide the connections menu (Bluetooth tab)                  |
| `clipboard`          | `toggle`, `open`, `close`, `refresh`, `copySelected`, `deleteSelected`              | Control the clipboard picker                                       |
| `drives`             | `status`, `refresh`, `mount <dev>`, `unmount <dev>`, `poweroff <dev>`, `open <dev>` | Inspect and control removable drives                               |
| `idle`               | `toggle`, `isDisabled`, `settings`                                                  | Control idle handling or open its settings                         |
| `settings`           | `open`, `toggle`, `close`                                                           | Open the settings window                                           |
| `launcher`           | `toggle`, `open`, `close`, `apps`, `search`, `emoji`, `files`, `calculator`         | Open, switch, or toggle launcher modes; `search` opens File Search |
| `lock`               | `lock`                                                                              | Lock the session                                                   |
| `locker`             | `isSecure`                                                                          | Query whether the separate lock-screen process is secure           |
| `network`            | `toggle`, `open`, `close`                                                           | Show or hide the connections menu (Network tab)                    |
| `notificationCenter` | `toggle`, `open`, `close`                                                           | Show or hide notification history                                  |
| `notifications`      | `toggleDnd`, `enableDnd`, `disableDnd`, `isDnd`, `clear`, `count`                   | Control DND or notification history                                |
| `power`              | `exit`, `suspend`, `reboot`, `shutdown`                                             | Run a session power action                                         |
| `recorder`           | `fullscreen`, `region`, `stop`, `isRecording`                                       | Start or stop a recording, or query its state                      |
| `theme`              | `refresh`, `usingHellwal`                                                           | Reload or query the active theme                                   |
| `translator`         | `toggle`, `open`, `close`                                                           | Control the translator                                             |
| `updates`            | `toggle`, `open`, `close`                                                           | Show or hide the package updates popup                             |
| `volume`             | `up`, `down`, `mute`                                                                | Adjust or mute the default audio output; shows the OSD             |
| `wallpaper`          | `toggle`, `open`, `close`                                                           | Control the wallpaper picker                                       |
| `weather`            | `toggle`, `open`, `close`                                                           | Show or hide the weather forecast                                  |

`qs ipc call volume up` raises the volume by one step. `launcher/dmenu-runner` uses the launcher IPC internally; call the script to open a picker.

</details>

## Launcher

Switch modes with the shortcuts below, or cycle with **Ctrl+← / Ctrl+→**.

| Mode  | Shortcut | What it does                |
| ----- | -------- | --------------------------- |
| Apps  | `Ctrl+A` | Launch desktop applications |
| Emoji | `Ctrl+E` | Emoji Selector              |
| Files | `Ctrl+S` | Search local files          |

Type `=1+2` in Apps mode to use the calculator. Plain math works without the prefix. Use `Ctrl+S` or cycle modes to search files.

Press `Ctrl+P` on an app or quick command to pin or unpin it. Pinned items appear first with a pin and are stored in `~/.local/share/quickshell-launcher-action-pins.json` and `~/.local/share/quickshell-launcher-pins.json`.

## Dmenu mode

For scripts that use dmenu-style pickers:

```bash
printf '%s\n' Search 'New Note' TODO Delete | ./launcher/dmenu-runner -p "Notes" -l 4 --minimal-lines
```

- Supported options: `-p`/`--prompt`, `-l <number>`/`--lines <number>`, `--minimal-lines`, and `--index` (returns the original zero-based input index; typed text returns `-1`).

Slimshell must be running. It is a small dmenu-compatible runner, not a dmenu/rofi replacement.

## Getting started

Follow the [installation guide](assets/docs.md) for dependencies, Niri startup, keybindings, and optional feature setup. Install into `~/.config/quickshell`, then run:

```bash
qs -p "$HOME/.config/quickshell" --no-detailed-logs
```

## Structure

```text
shell.qml       Shell entrypoint and service wiring
bar/            Bar and its modules
components/     Reusable UI and popup components
services/       Shared desktop state and integrations
tests/          Offline tests and fixtures, grouped by feature
launcher/       Launcher, actions.json, dmenu runner, and search helpers
menus/          Settings and wallpaper menus
notifications/  Notification popups and history
clipboard/      Clipboard picker and previews
lock/           Lock screen components and PAM setup
recorder/       Region selection overlay for the recorder
translator/     DeepL translator
updates/        Package update checks, popup, and upgrade script
wallpaper/      Wallpaper helpers
weather/        Weather forecast popup and helper
osd/            Volume and workspace overlays
```

## Transparency

I build this shell with LLM assistance, direct the design, review every change, and test it on my desktop. These are personal dotfiles; review and adapt them before use. Expect rough edges.

## ISSUES 🔨

- ~~dmenu-runner can't display special symbols (Nerd fonts etc.)~~
- Other issues likely exist. Fixes and suggestions are welcome.

## TODO

- [x] Workspaces OSD on barless mode, once I nail the correct style
- [ ] Improve comments
