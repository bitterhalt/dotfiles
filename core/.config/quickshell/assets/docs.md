# Install Slimshell

Slimshell runs inside a Niri session you already have up and running. Your compositor config stays exactly as it is.

## 1. Install dependencies

Grab these from your distro's package manager:

- Niri plus a current Qt 6 build of [Quickshell](https://quickshell.org/docs/guide/install-setup/), with its Wayland, PipeWire, Networking, Bluetooth, UPower, Polkit and PAM modules.
- PipeWire, NetworkManager, BlueZ, UPower and polkit, and make sure those services are actually running.
- Symbols Nerd Font Mono for the icons, plus whatever text font you like.
- Git, for cloning the repo.
- `dbus-monitor`, which ships with D-Bus. Clocks refresh right after resume because of it.

Only install the extras for features you'll use:

| Feature                    | Dependencies                                                              |
| -------------------------- | ------------------------------------------------------------------------- |
| Clipboard history          | `cliphist`, `wl-clipboard`                                                |
| File search                | `fd`; file opening also uses `file`, `xdg-open`, a terminal and an editor |
| Administrator file editing | `sudo` with permission to use `sudoedit`                                  |
| Calculator                 | `qalc`, `wl-copy`                                                         |
| Emoji                      | An emoji list, described below; `wl-copy` to copy selections              |
| Audio card profiles        | `pactl` and PipeWire's PulseAudio compatibility service                   |
| Removable drives           | `udisks2` (`udisksctl`) and `lsblk`; `xdg-open` to open mountpoints       |
| Screen recording           | `gpu-screen-recorder`, `notify-send`                                      |
| Wallpaper picker           | Python 3, ImageMagick (`magick`); Hellwal for generated colors            |
| Translation                | Python 3, `wl-copy`, and a DeepL API key                                  |
| Locking and suspension     | Linux-PAM, Bash and systemd/logind; see the lock-screen check below       |

`notify-send` comes from a package called `libnotify` on most distros. Some rename `fd`, but Slimshell looks for `fd` on `PATH`. Menus launch `$TERMINAL` and commands go through a shell, so set `TERMINAL` and `EDITOR` in whatever starts the shell. Leave them unset and file search uses `foot` and `nvim`.

## 2. Install the configuration

Back up any existing `~/.config/quickshell` before you start. Then clone the dotfiles and link the shell in:

```sh
mkdir -p ~/.config
git clone https://github.com/bitterhalt/dotfiles.git ~/dotfiles
ln -sfT ~/dotfiles/core/.config/quickshell ~/.config/quickshell
```

Keep that `~/.config/quickshell` path: several helpers hard-code it. If you put the shell somewhere else, adjust the link accordingly.

Appearance and behavior live in the Settings menu (`qs ipc call settings open`). The optional launcher actions in `launcher/UserActions.qml` cover local tools like `sup`, `vopen`, and `tmux-sysmon.sh`. Some of those entries point at personal scripts from my [dotfiles](https://github.com/bitterhalt/dotfiles), so look them over and swap out anything you don't want. None of this touches your own dmenu scripts.

## 3. Try it in your Niri session

Stop Mako, Dunst, or whatever notification daemon you're running, and don't start a second polkit agent. If you're replacing an old bar, turn off its autostart too.

```sh
qs -p "$HOME/.config/quickshell" --no-detailed-logs
```

Leave the terminal open so you can see errors. Ctrl+C stops the foreground instance.

### Check the lock screen

Open a second terminal while Slimshell is still running:

```sh
qs ipc call lock lock
```

Make sure you can unlock again before you trust automatic locking or suspension. The bundled `lock/pam/quickshell-lock` policy uses `pam_unix` and `pam_faillock`. Adapt it if your distro does authentication differently, and keep another way into your session while you test.

Automatic locking, monitor power-off and suspension are on the Idle page of the Settings menu (`qs ipc call idle settings`). A timeout of `0` turns that action off.

## 4. Add Niri startup and keybindings

Drop this into your Niri config, folding the bindings into your existing `binds` block:

```kdl
spawn-sh-at-startup "qs -n --no-detailed-logs"

binds {
    Mod+Space { spawn-sh "qs ipc call launcher toggle"; }
    Mod+V { spawn-sh "qs ipc call clipboard toggle"; }
    Mod+N { spawn-sh "qs ipc call notificationCenter toggle"; }
    Mod+Shift+L { spawn-sh "qs ipc call lock lock"; }
    XF86AudioRaiseVolume { spawn-sh "qs ipc call volume up"; }
    XF86AudioLowerVolume { spawn-sh "qs ipc call volume down"; }
    XF86AudioMute { spawn-sh "qs ipc call volume mute"; }
}
```

Startup takes effect on your next session. Don't launch a second copy if one is already up. The [README](../README.md#features) lists the other IPC calls.

## 5. Set up optional features

### Settings

`qs ipc call settings open` brings up the Settings menu, and there's a Settings launcher action too. Pages cover Idle, Appearance, Theming, Bar, Audio, Launcher, Notifications and Bluetooth. Tab walks the page list and the controls. Up/Down flip through sidebar pages and move between fields in a page, Left/Right step a value, Ctrl+Up/Down or Ctrl+J/K change pages from anywhere, and Esc closes. Hit `?` or click `? Help` for the full key list.

Your choices land in `~/.local/share/quickshell-config.json`, and Slimshell reloads that file when you edit it. Invalid values get replaced with safe defaults, and a malformed JSON file leaves your previous settings alone. No file yet means the built-in defaults apply. `quickshell-settings.json` holds idle timeouts, workspace layout, bar visibility and the Theming (Hellwal) options. Idle and Theming need Apply (Ctrl+Enter); Theming also rebuilds colors from the current wallpaper.

The footer shows a tip about the current page, like the fact that values over 100% amplify the signal or that `0` disables an idle action. Real messages, errors and save confirmations for instance, push the tip aside for a moment. `? Help` or the `?` key gives you the key list. Power actions sit in the Power menu (`Mod+Escape`) and the launcher.

Animations get toggled in Settings. Each widget keeps its own style and timing.

### Clipboard history

Slimshell shows clipboard history but doesn't collect it. If you have no clipboard watchers yet, add these to Niri's startup entries:

```kdl
spawn-at-startup "wl-paste" "--type" "text" "--watch" "cliphist" "store"
spawn-at-startup "wl-paste" "--type" "image" "--watch" "cliphist" "store"
```

### Wallpaper and colors

Images go in `~/Pictures/wallpaper`. Quickshell draws the wallpaper itself, in `services/WallpaperService.qml` and `wallpaper/WallpaperLayer.qml`, and makes a blurred `overview` copy for niri. You only need this one layer rule. Scripts can force a redraw with `qs ipc call bg reload`:

```kdl
layer-rule {
    match namespace="overview"
    place-within-backdrop true
}
```

`qs ipc call wallpaper open` opens the picker. Generated wallpaper and lock-screen images end up in `~/.local/share/wall`. Until Hellwal writes `~/.cache/hellwal/colors.css`, the shell uses its fallback palette. The Hellwal mode, offsets, grayscale and fixed background are all under Settings → Theming.

### Emoji

The bundled UTF-8 list is `components/emoji/emoji.txt`. One emoji per line, then its search description:

```text
🐀 rat
😀 grinning face
```

### Translation

Set `DEEPL_API` in the environment before you launch Slimshell. Keep the key out of this repo and out of your commits.

### Weather

Hover the clock and click the weather to see the forecast. F5 refreshes it. Set `WEATHER_LOCATION` to a city, or use `WEATHER_LAT` and `WEATHER_LON` with an optional `WEATHER_NAME`, all in the shell's environment. With nothing configured the helper falls back to rough IP geolocation. Conditions come from Open-Meteo and get cached for an hour.

### Launcher actions

The shell's own graphical commands are built in, under the `quickshell` category with the `settings` icon. That covers power actions, lock screen, wallpaper, settings, updates and screen recording. You'll find their definitions in `components/QuickshellActions.qml`, kept apart from personal commands so other menus can share the list. Type `:quickshell` to see them.

Personal commands go in `launcher/UserActions.qml` as a QML list. Every entry needs a `category`, a `label`, a `keyword` and a `command`. `confirm` is optional and defaults to `true`:

```qml
import QtQuick

QtObject {
    readonly property var actions: [
        {
            category: "misc",
            label: "Notification test",
            keyword: "notify",
            command: "notify-send hello",
            confirm: false
        }
    ]
}
```

Quickshell watches QML sources, so edits reload on their own. Since this is QML and not JSON, comments and trailing commas are fine, and a syntax error shows up in the QML logs instead of silently keeping the old list.

Type the keyword or part of the label and pick the result. Slimshell marks actions as `[action] <category>: <name>` and gives personal commands the `utilities-terminal` icon while built-ins use `settings`, so they're easy to tell apart from applications. Want a different icon? Change `actionIcon` in `launcher/Launcher.qml`. With `confirm: true` the launcher asks Yes/No first. Type `:` to list everything, `:quickshell` for built-ins, `:misc` for that personal category, or `:misc notif` to filter inside it. `Ctrl+P` pins the selected command. Pinned commands come first in an empty launcher, ahead of pinned apps, and Slimshell saves them in `~/.local/share/quickshell-launcher-action-pins.json`. Commands go through the shell, so only add ones you trust.

While Slimshell is running, scripts can call `~/.config/quickshell/launcher/dmenu-runner`. The [dmenu examples](../README.md#dmenu-mode) show how.

### Updates

Updates opens from its built-in launcher action in the `quickshell` category, or with `qs ipc call updates toggle`. Nothing polls in the background. The first open in a session runs a package check, later opens reuse the cached report, and **Refresh** (`r`) checks again. Long reports cap at three quarters of the screen and scroll with the wheel, Up/Down, PageUp/PageDown or Home/End. A thin bar on the right shows where you are.

Checks cover `pacman` (plus `checkupdates` when installed) and AUR through `yay` or `paru`, along with `apt`, `dnf`, `flatpak`, `snap` and `pipx` when those tools are present.

**Upgrade** (`u`) opens `$TERMINAL --app-id pop-upgrade -e bash ~/.config/quickshell/updates/upgrade.sh`. That script upgrades whatever managers it finds (Arch via yay/paru or pacman, then apt, dnf, snap, flatpak and pipx) and leaves prompts and build output visible in the terminal. `$TERMINAL` needs to accept `-e`; Slimshell falls back to `foot`. The `--app-id` flag lets a Niri window rule float the upgrade terminal.

## Updating and troubleshooting

Update with `git -C ~/.config/quickshell pull --ff-only`. Commit or stash local changes first, since Git won't overwrite conflicting work.

If startup breaks, stop the running instance and rerun the foreground command from step 3. A missing QML module means your Quickshell build is too old or missing an integration. Missing icons usually means you skipped the Nerd Font.

The offline tests run with `python -B tests/run.py` from the checkout. They need Qt 6's `qmltestrunner` and never touch or reload the live shell.
