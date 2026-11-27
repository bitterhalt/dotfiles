# Install Slimshell

Slimshell runs inside an existing Niri session. It does not install or replace
your compositor configuration.

## 1. Install dependencies

Install these with your distribution's package manager:

- Niri and a current Qt 6 build of [Quickshell](https://quickshell.org/docs/guide/install-setup/),
  including its Wayland, PipeWire, Networking, Bluetooth, UPower, Polkit and PAM modules.
- PipeWire, NetworkManager, BlueZ, UPower and polkit, with the relevant services running.
- Symbols Nerd Font Mono for icons, plus your preferred text font.
- Git to clone the repository.
- `dbus-monitor` (shipped with D-Bus) to refresh clocks immediately after resume.

Install these tools only for the features you use:

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

Most distributions supply `notify-send` in a package named `libnotify`. Some ship
`fd` under another name; Slimshell expects `fd` on `PATH`.
Menus launch `$TERMINAL`, and commands run through a shell. Set
`TERMINAL` and `EDITOR` in the environment that starts the shell; file search
falls back to `foot` and `nvim` when they are unset.

## 2. Install the configuration

Back up any existing `~/.config/quickshell` first. Clone the dotfiles and link
the shell into place:

```sh
mkdir -p ~/.config
git clone https://github.com/bitterhalt/dotfiles.git ~/dotfiles
ln -sfT ~/dotfiles/core/.config/quickshell ~/.config/quickshell
```

Several helpers expect `~/.config/quickshell`, so keep that path. Adjust the link
if you install the shell somewhere else.

Change appearance and behavior in the Settings menu (`qs ipc call settings open`).
Optional launcher actions in `launcher/UserActions.qml` include local tools such as `sup`,
`vopen`, and `tmux-sysmon.sh`. Some entries rely on personal scripts or configuration
from my [dotfiles](https://github.com/bitterhalt/dotfiles). Review or replace them.
These menus do not affect your own dmenu scripts.

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
bundled `lock/pam/quickshell-lock` policy uses `pam_unix` and `pam_faillock`;
adapt it to your distribution's authentication policy if needed. Keep another
way to access your session while testing.

Configure automatic locking, monitor power-off, and suspension on the Idle page
of the Settings menu (`qs ipc call idle settings`). Set a timeout to `0` to
disable that action.

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

Open the Settings menu with `qs ipc call settings open` (or the Settings launcher
action). It has pages for Idle, Appearance, Theming, Bar, Audio, Launcher, Notifications
and Bluetooth. Tab moves focus through the page list and the controls. Up/Down switch
pages from the sidebar and walk fields in the page, Left/Right step a value,
Ctrl+Up/Down or Ctrl+J/K switch pages from anywhere, and Esc closes. Press `?` or
click `? Help` for the key list. Slimshell saves choices in
`~/.local/share/quickshell-config.json` and reloads the file when you edit it.
It replaces invalid values with safe defaults and keeps the previous settings
when the JSON is malformed.
Without that file the built-in defaults apply. `quickshell-settings.json` stores
idle timeouts, workspace layout, bar visibility, and Theming (Hellwal) options.
Idle and Theming use Apply (Ctrl+Enter); Theming also regenerates colors from the
current wallpaper.

The footer shows a tip for the current page (for example, that values above 100%
amplify the signal, or that `0` disables an idle action). Real status messages,
such as errors and save confirmations, temporarily replace the tip. Click `? Help`
or press `?` for the key list. Power actions live in the Power menu (`Mod+Escape`)
and the launcher.

Settings toggles animations; each widget owns its style and timing.

### Clipboard history

Slimshell displays history but does not collect it. Add these Niri startup entries
if you do not already run clipboard watchers:

```kdl
spawn-at-startup "wl-paste" "--type" "text" "--watch" "cliphist" "store"
spawn-at-startup "wl-paste" "--type" "image" "--watch" "cliphist" "store"
```

### Wallpaper and colors

Put images in `~/Pictures/wallpaper`. Quickshell draws the wallpaper itself
(`services/WallpaperService.qml` and `wallpaper/WallpaperLayer.qml`), including a
blurred `overview` copy for niri. Only this layer rule is needed (scripts can force
a redraw with `qs ipc call bg reload`):

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

Set `DEEPL_API` in the environment before you launch Slimshell.
Do not put the key in this repository or commit it to your configuration.

### Weather

Hover the clock and click the weather to open the forecast. Press F5 to refresh.
Set `WEATHER_LOCATION` to a city, or `WEATHER_LAT` and `WEATHER_LON` (optionally
`WEATHER_NAME`) in the shell's environment. Without a configured location, the
helper uses approximate IP geolocation. Conditions come from Open-Meteo; the
helper caches them for one hour.

### Launcher actions

The shell's own graphical commands are built in. They live under the
`quickshell` category and use the `settings` icon: power actions, lock screen,
wallpaper, settings, updates, and screen recording. Their definitions live in
`components/QuickshellActions.qml`, separate from personal commands, so other
menus can reuse the same list. Type `:quickshell` to list them.

Add personal commands in `launcher/UserActions.qml`, a QML list. Each entry
needs a `category`, a `label`, a `keyword`, and a `command`; `confirm` is
optional and defaults to `true`:

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

Quickshell watches QML sources, so edits reload automatically. Because this is
QML rather than JSON, comments and trailing commas are allowed; a syntax error
shows in the QML logs instead of silently keeping the previous list.

Type the keyword (or part of the label) in the launcher and pick the result;
Slimshell labels actions `[action] <category>: <name>` and shows the
`utilities-terminal` icon for personal commands (built-ins use `settings`) so
they stay distinct from applications. Change `actionIcon` in
`launcher/Launcher.qml` to use a different icon for personal commands. With
`confirm: true` the launcher asks Yes/No before running the command. Type
`:` to list every action; `:quickshell` lists the built-ins, `:misc` lists that
personal category, and `:misc notif` filters within it. `Ctrl+P` pins the
selected command; pinned commands appear first in an empty launcher, above
pinned apps, and Slimshell stores them in
`~/.local/share/quickshell-launcher-action-pins.json`. Commands run through the
shell, so only add commands you trust.

Scripts can call `~/.config/quickshell/launcher/dmenu-runner` while Slimshell is
running. See the [dmenu examples](../README.md#dmenu-mode).

### Updates

Open **Updates** from the built-in Updates launcher action (category
`quickshell`) or with `qs ipc call updates toggle`. Nothing checks
in the background: the first open in a session runs a package check, later opens
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
`-e`; Slimshell uses `foot` when the variable is unset. The `--app-id` flag lets a
Niri window rule keep the upgrade terminal floating.

## Updating and troubleshooting

Update with `git -C ~/.config/quickshell pull --ff-only`. Preserve or commit your
local changes first; Git will refuse updates that would overwrite conflicting work.

If startup fails, stop the existing instance and run the foreground command from
step 3. If a QML module is missing, your Quickshell build is too old or lacks an
integration. Install the Nerd Font if icons are missing.

Run the offline tests with `python -B tests/run.py` from the checkout. They require
Qt 6's `qmltestrunner` and never start or reload the live shell.
