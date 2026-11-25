# Install Slimshell

Slimshell runs inside an existing Niri session. It does not install or replace
your compositor configuration.

## 1. Install dependencies

Install these using your distribution's package manager:

- Niri and a current Qt 6 build of [Quickshell](https://quickshell.org/docs/guide/install-setup/),
  including its Wayland, PipeWire, Networking, Bluetooth, UPower, Polkit and PAM modules.
- PipeWire, NetworkManager, BlueZ, UPower and polkit, with the relevant services running.
- Symbols Nerd Font Mono for icons, plus your preferred text font.
- Git to clone the repository.
- `dbus-monitor` for refreshing clocks immediately after resume (usually included with D-Bus).

Additional tools are needed only for the features you use:

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

`notify-send` is usually supplied by a package named `libnotify`. Some distributions
install `fd` under a different command name; Slimshell expects `fd` on `PATH`.
The shipped menus launch `$TERMINAL`, and menu commands run through a shell. Set
`TERMINAL` and `EDITOR` in the environment that starts the shell; file search
falls back to `foot` and `nvim` when they are unset.

## 2. Install the configuration

Back up any existing `~/.config/quickshell` first. Then clone into that exact path:

```sh
mkdir -p ~/.config
git clone https://github.com/bitterhalt/slimshell.git ~/.config/quickshell
```

Several helpers currently expect `~/.config/quickshell`, so do not install into a
named subconfiguration or another directory unless you also adjust those paths.

Appearance and behavior are changed in the Settings menu (`qs ipc call settings open`). Optional commands in
`menus.json` still include local tools such as `sup`, `vopen` and
`tmux-sysmon.sh`. Menus and other integrations may rely on personal scripts or
configuration from my [dotfiles](https://github.com/bitterhalt/dotfiles).
Review those before borrowing them, or replace/remove entries you do not use.
Your own dmenu scripts are independent of these built-in menus.

## 3. Try it in your Niri session

Stop any other notification daemon, such as Mako or Dunst, and avoid running a
second polkit authentication agent. Disable the old bar's autostart if replacing it.

```sh
qs -p "$HOME/.config/quickshell" --no-detailed-logs
```

Keep the terminal open to see errors. Press Ctrl+C to stop this foreground instance
before starting it another way.

### Check the lock screen

From another terminal, while Slimshell is running:

```sh
qs ipc call lock lock
```

Test that you can unlock before relying on automatic locking or suspension. The
bundled `lock/pam/quickshell-lock` policy uses `pam_unix` and `pam_faillock`; it may
need adapting to your distribution's authentication policy. Keep another way to
access your session while testing.

Automatic locking, monitor power-off and suspension are configured on the Idle
page of the Settings menu (`qs ipc call idle settings`). Set a timeout to `0` to disable that action.

## 4. Add Niri startup and keybindings

Add the following to your Niri configuration, merging the bindings into your
existing `binds` block:

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

The startup command takes effect next session. Do not start a second copy if one
is already running. More IPC calls are listed in the [README](../README.md#features).

## 5. Set up optional features

### Settings

Open the Settings menu with `qs ipc call settings open` (or the Settings entry in the
main menu). It has pages for Idle, Appearance, Theming, Bar, Audio, Launcher, Notifications
and Bluetooth. Tab moves focus through the page list and the controls. Up/Down switch
pages from the sidebar and walk fields in the page, Left/Right step a value,
Ctrl+Up/Down or Ctrl+J/K switch pages from anywhere, and Esc closes. Press `?` or
click `? Help` for the key list. Choices are saved in
`~/.local/share/quickshell-config.json`, which is also reloaded when edited by hand:
invalid values use safe defaults, and malformed JSON keeps the previous settings.
Without that file the built-in defaults apply. Idle timeouts, workspace layout, bar
visibility and the Theming (Hellwal) options are saved in
`quickshell-settings.json`. Idle and Theming are
saved with Apply (Ctrl+Enter); Theming also regenerates the colors from the current wallpaper.

Animations can be enabled or disabled in settings; each widget owns its style and timing.

Edit `menus.json` to customize `user-menu1` through `user-menu4`; the fourth is an empty placeholder.
Open one with `qs ipc call menu open user-menu1`.
Changes reload automatically; invalid edits keep the last working menus. Power
actions remain built in.

### Clipboard history

Slimshell displays history but does not collect it. Add these Niri startup entries
if you do not already run clipboard watchers:

```kdl
spawn-at-startup "wl-paste" "--type" "text" "--watch" "cliphist" "store"
spawn-at-startup "wl-paste" "--type" "image" "--watch" "cliphist" "store"
```

### Wallpaper and colors

Put images in `~/Pictures/wallpaper`. Quickshell draws the wallpaper itself
(`services/WallpaperService.qml` and `wallpaper/WallpaperLayer.qml`), including a blurred `overview` copy for niri.
Only this layer rule is needed (scripts can force a redraw with `qs ipc call bg reload`):

```kdl
layer-rule {
    match namespace="overview"
    place-within-backdrop true
}
```

Open the picker with `qs ipc call wallpaper open`. Generated wallpaper/lock-screen
images go into `~/.local/share/wall`. The shell uses its fallback palette until
Hellwal supplies `~/.cache/hellwal/colors.css`. Change the Hellwal mode, offsets,
grayscale, and fixed background under Settings → Theming.

### Emoji

The bundled UTF-8 list is at `components/emoji/emoji.txt`, with an emoji followed by
its search description on each line:

```text
🐀 rat
😀 grinning face
```

### Translation

Set `DEEPL_API` in the environment inherited by Slimshell before launching it.
Do not put the key in this repository or commit it to your configuration.

### Weather

Hover the clock and click the weather to open the forecast. Press F5 to refresh.
Set `WEATHER_LOCATION` to a city, or `WEATHER_LAT` and `WEATHER_LON` (optionally
`WEATHER_NAME`) in the shell's environment. Without a configured location, the
helper uses approximate IP geolocation. Conditions come from Open-Meteo and
are cached for one hour.

### Your own menus

Edit `menus.json` to replace or extend the `user-menu1` through `user-menu4`
lists. Each item needs a label and one of `command`, `action`, or `page`:

```json
{
  "user-menu1": [
    {
      "label": "Terminal",
      "icon": "󰆍",
      "shortcut": "t",
      "command": "$TERMINAL"
    },
    { "label": "Settings", "shortcut": "s", "action": "settings" }
  ]
}
```

Icons and shortcuts are optional. Shortcuts are single letters or digits and
must be unique within a list. Commands run through the shell when activated;
only add commands you trust. Set `"confirm": true` on a command to ask before
running it. Built-in actions are `settings`, `wallpaper`, `lock`, `suspend`,
and `updates`; page links accept `user-menu1` through `user-menu4`, or `power`.
Open a list with `qs ipc call menu open user-menu1`, or use `menu toggle user-menu1`.
The old `menu packages`, `menu settings`, and `menu system` calls remain aliases
for the first three menus, so existing keybindings still work. The fourth list
ships empty as a placeholder.
Omitted lists are empty. Invalid edits or a missing file keep the last loaded
menus; if none have loaded yet, the custom lists are empty and Power still works.

Scripts can call `~/.config/quickshell/launcher/dmenu-runner` while Slimshell is
running. See the [dmenu examples](../README.md#dmenu-mode).

### Launcher actions

Edit `launcher/launcher-actions.json` to add custom commands to the launcher's normal
search. Each entry needs a `label`, a `keyword`, and a `command`; `confirm` is
optional and defaults to `true`, and `category` is optional and defaults to
`misc`:

```json
[
  {
    "label": "Reboot",
    "keyword": "reboot",
    "command": "systemctl reboot",
    "confirm": true,
    "category": "pwr"
  },
  {
    "label": "Lock screen",
    "keyword": "lock",
    "command": "qs ipc call lock lock",
    "confirm": false,
    "category": "pwr"
  }
]
```

Type the keyword (or part of the label) in the launcher and pick the result;
actions are labelled `[action] <name>` and show the `utilities-terminal` icon
so they stay distinct from applications. Change `actionIcon` in
`launcher/Launcher.qml` to use a different icon. With `confirm: true` the launcher
asks Yes/No before running the command. Type just `:` to list every action as
`[action] <category>: <name>`; `:pwr` lists only that category, and `:pwr reb`
filters within it. `Ctrl+P` pins the selected command; pinned commands appear
first in an empty launcher, above pinned apps, and are stored in
`~/.local/share/quickshell-launcher-action-pins.json`. Commands run through the
shell, so only add commands you trust. Invalid edits or a missing file keep the
last loaded list.

### Updates

Open **Updates** through an `updates` entry in `menus.json` (or
`qs ipc call updates toggle`) to see pending package updates. Nothing checks in
the background: the first open in a session runs a package check, later opens
reuse the cached report, and **Refresh** (`r`) checks again. Long reports stay
at most three quarters of the screen high and scroll with the wheel or
Up/Down/PageUp/PageDown/Home/End; a thin bar on the right shows the position.

Checks cover `pacman` (with `checkupdates` when installed) and AUR through `yay`
or `paru`, plus `apt`, `dnf`, `flatpak`, `snap`, and `pipx` when those tools
exist.

**Upgrade** (`u`) opens `$TERMINAL --app-id pop-upgrade -e bash
~/.config/quickshell/updates/upgrade.sh`. The script upgrades every manager it
finds (Arch via yay/paru or pacman, plus apt, dnf, snap, flatpak, and pipx) and
keeps prompts and build output visible in the terminal. `$TERMINAL` must accept
`-e`; `foot` is used when the variable is unset. The `--app-id` flag lets a Niri
window rule keep the upgrade terminal floating.

## Updating and troubleshooting

Update with `git -C ~/.config/quickshell pull --ff-only`. Preserve or commit your
local changes first; Git will refuse updates that would overwrite conflicting work.

If startup fails, run the foreground command from step 3 after stopping the existing
instance. Missing QML modules usually mean the installed Quickshell build is too old
or lacks a required integration. Missing icons usually mean the Nerd Font is absent.

Offline tests are available with `python -B tests/run.py` from the checkout.
They require Qt 6's `qmltestrunner` and do not start or reload the live shell.
