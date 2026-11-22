# mpv: with persistent workflow

Two ways to launch mpv, both using the same config.

| Launcher                   | What it does                                                                |
| -------------------------- | --------------------------------------------------------------------------- |
| **mpv** (stock `.desktop`) | Opens an empty, persistent window. Drop or open a file when you want.       |
| **mpv (Resume)**           | Opens mpv and continues the last video you watched, from where you stopped. |

## How it works

1. **Per-file resume** (`mpv.conf`)

   ```ini
   save-position-on-quit=yes
   ```

   On a normal quit (`q` or closing the window), mpv saves the position for
   that file. Opening the file again resumes it. Files watched to the end are
   not remembered.

2. **Last-file history** (`scripts/memo.lua`)

   `memo.lua` keeps a history of played files. Its `memo-last` action opens the
   most recent one. It is bound to `Ctrl+l` in `input.conf`, and `Ctrl+h` opens
   the history menu.

3. **Auto-resume on empty start** (`scripts/resume-last.lua`)

   If mpv starts with no file **and** the `resume=yes` script option is set, the
   script waits 0.5 s and then runs `memo/memo-last`. Per-file resume (1) then
   puts you at the saved position.

   Without the flag, the script does nothing, which gives the plain empty
   persistent window.

4. **Persistent window**

   The stock launcher uses `--player-operation-mode=pseudo-gui`, which keeps
   mpv open when started with no file. No `idle=` option is needed.

## Launchers

`~/.local/share/applications/mpv-resume.desktop`:

```ini
[Desktop Entry]
Type=Application
Name=mpv (Resume)
Comment=Continue the last played video
Exec=mpv --player-operation-mode=pseudo-gui --script-opts-append=resume=yes -- %U
Icon=mpv
Terminal=false
Categories=AudioVideo;Video;Player;
```

There is no `MimeType` line on purpose, so it doesn't compete with the stock
mpv as the default video player. If it doesn't appear in the launcher:

```bash
update-desktop-database ~/.local/share/applications
```

`--script-opts-append` is used instead of `--script-opts` so it adds to any
`script-opts` already in `mpv.conf` rather than replacing them.

## Behavior notes

- Opening a file directly (double-click, "Open with") always plays that file.
  The resume script only acts on an empty start.
- If the last file was watched to the end, Resume reopens it from the start.
- With empty history (first run), Resume shows "[memo] no recent files to open"
  and stays idle.
- Quit with `q` or the window close button so the position is saved. A crash or
  `kill` won't save it.

## Keybinds

| Key                        | Action                       |
| -------------------------- | ---------------------------- |
| `Ctrl+h`                   | Recent files menu (memo)     |
| `Ctrl+l`                   | Open last played file (memo) |
| `Ctrl+Right` / `Ctrl+Left` | Next / previous in playlist  |
| `+` / `-`                  | Subtitle scale up / down     |
