# Plan: Replace Settings power buttons with page tips

## 1. Goal and expected behavior

Remove the power-action buttons from the Settings menu footer and restore the
per-page "tips"/hints that were removed when the power buttons were added (commit
`eda44b9`, "add settings power buttons and recorder launcher actions").

Expected behavior after the change:

- The Settings footer no longer shows `[E]xit`, `[Z]zz`, `[R]eboot`, `[S]hutdown`,
  nor the `[Y]es`/`[N]o` confirmation row.
- The footer returns to its earlier contract: a status/hint text line on the
  left, the `? Help` toggle on the right, under an inset separator.
- When a page has a hint, the footer shows that hint in muted text. Real status
  messages (errors, `noteText`, "Generating colors…", idle errors) take
  precedence over the hint, exactly as before `eda44b9`.
- Keyboard shortcuts `E`/`Z`/`R`/`S` and confirmation keys `Y`/`N` are removed
  from the Settings menu. Power actions remain available through the launcher
  (`qs ipc call power ...`) and the global `power` IPC target — do not remove
  `services/PowerService.qml` or its IPC handlers.
- The help overlay no longer advertises power actions or Y/N confirmation.
- Hints to restore (from `eda44b9^`, verbatim):
  - Theming: `Colors are generated from the current wallpaper`
  - Audio: `Values above 100% amplify the signal`
  - Notifications: `Excluded apps are comma separated app names`
  - Bluetooth: `0 disables a battery notification`
  - Idle (dynamic, from the old `statusText()`): `30s, 30m, 2h · 0 disables an idle action`

  Keep other pages without a hint (Appearance, Bar, Launcher) so the footer is
  empty there, matching the pre-power-button behavior.

## 2. Existing architecture and relevant files

- `menus/SettingsMenu.qml` — owns the window, page data, keyboard handling, help
  overlay entries, and passes footer state to `SettingsFooter`. Current power
  state lives here: `pendingPower`, `powerActions`, `requestPower()`,
  `confirmPower()`, `cancelPower()`, the required `powerService` property, and
  `footerStatusText()` (comment says "page hints are gone").
- `menus/SettingsPages.js` — data-only `.pragma library` array of page
  descriptors (`id`, `label`, `icon`, `custom`/`staged`, `rows`). This is where
  page `hint` strings belonged before the component split (`6221bcc`); that
  split moved page data here but did not re-add hints.
- `menus/settings/SettingsFooter.qml` — extracted footer component (separator,
  power buttons row, confirm row, status text, help toggle). Since `6221bcc`
  this is the only place the power buttons are drawn.
- `services/PowerService.qml` and `shell.qml` — power actions/IPC and their
  wiring. Shared with launcher actions; must stay.
- `components/QuickshellActions.qml`, `launcher/*` — built-in launcher entries
  calling `qs ipc call power ...`. Unaffected.
- `assets/docs.md` — user docs; the Settings section (lines 112–133) documents
  the footer power buttons and must be updated.
- `README.md` — IPC table lists the `power` target; leave it (IPC still exists).
- Tests: no settings-specific suite exists; `tests/run.py` lists explicit
  suites. Verification relies on the general runner, formatting, static checks,
  and optionally a small new QML test (step 6).

## 3. Exact files to modify

1. `core/.config/quickshell/menus/SettingsPages.js`
2. `core/.config/quickshell/menus/SettingsMenu.qml`
3. `core/.config/quickshell/menus/settings/SettingsFooter.qml`
4. `core/.config/quickshell/assets/docs.md`

Do **not** modify `services/PowerService.qml`, `shell.qml`, launcher files,
`README.md`, or anything in `tests/` unless adding the optional test from step 6.

## 4. Ordered implementation steps

1. **Restore hints in `SettingsPages.js`**: add a `hint:` field to the `theming`,
   `audio`, `notifications`, and `bluetooth` page objects using the exact
   strings from section 1. Place it next to `label`/`icon` (pre-`eda44b9`
   layout).

2. **Simplify `SettingsFooter.qml`**:
   - Update the header comment to describe status/hint + help toggle only.
   - Remove `property var powerActions`, `property string pendingPower`,
     `signal powerRequested(string action)`, `signal confirmRequested`, and
     `signal cancelRequested`.
   - Delete the `FooterButton` component, the `powerButtons` Row/Repeater, and
     the `confirmButtons` Row.
   - Keep only `PanelSeparator`, `footerStatus` Text, and `footerKeys` Text with
     its MouseArea. Make `footerStatus` visible when it has text:
     `visible: root.statusText !== ""`, `text: root.statusText`.
   - Keep color logic: `root.statusIsError ? root.config.urgent : root.config.muted`.
   - Footer API becomes: `config`, `statusText`, `statusIsError`, `helpOpen`,
     `helpToggled`.

3. **Simplify `SettingsMenu.qml`**:
   - Remove `required property var powerService`.
   - Remove `property string pendingPower`, `readonly property var powerActions`,
     and `requestPower()`, `confirmPower()`, `cancelPower()`. Remove all
     `pendingPower = "";` lines from `open()`, `close()`, `toggleHelp()`, and
     `selectPage()`.
   - Rename `footerStatusText()` back to `statusText()` and restore its tail:
     ```qml
     if (noteText !== "")
         return noteText;
     return current.custom === true ? "30s, 30m, 2h · 0 disables an idle action" : current.hint || "";
     ```
     Keep the existing error/theming/idle-error branches above it; update or
     remove the stale "page hints are gone" comment.
   - In `Keys.onPressed` on `card`: remove the Y/N `pendingPower` branch, the
     E/Z/R/S `action` branch, and `const key = event.text.toLowerCase();`.
     Restore plain Up/Down handling (Up/Down + `focusStep`, `event.accepted =
     true`). Remove the `if (root.helpOpen) return;` guard (it existed only for
     power keys) so Up/Down works while help is shown, as before `eda44b9`.
   - In the `Escape` Shortcut, remove the `pendingPower` branch: Esc toggles
     help first, then closes.
   - In the help overlay `entries`, remove "Power actions" and
     "Confirm / cancel power action".
   - In the `SettingsFooter` instantiation, pass only `config`, `statusText`,
     `statusIsError`, `helpOpen`, `onHelpToggled`; remove the four power bindings.

4. **Update `assets/docs.md`**: replace the paragraph at lines 128–131 with a
   short description of the footer status/hint line and `? Help`. Keep the
   surrounding Settings text; do not remove launcher/power IPC docs elsewhere.

5. **Format modified QML** with `/usr/lib/qt6/bin/qmlformat -i FILE.qml` (no
   `--sort-imports`). If qmlformat rejects the `.js` extension, leave
   `SettingsPages.js` formatting untouched.

6. **Check the diff**: `git diff --check`, `git diff --stat`. Confirm only the
   four intended files changed. Pre-existing unrelated changes in
   `apps/.config/opencode/opencode.json` and `apps/.config/opencode/commands/`
   must not be staged or touched.

## 5. Potential issues and compatibility concerns

- **PowerService wiring**: `shell.qml` passes `powerService: appPowerService`
  to `SettingsMenu`. After removing the required property, that binding is
  unused — remove it from `shell.qml` only if QML reports an unknown-property
  warning/error. If so, `shell.qml` is the one permitted exception to the file
  list.
- **Help overlay height**: removing two help entries changes `body.height`
  (derived from `helpPanel.implicitHeight`). Expected; no fixed heights need
  changes.
- **Status vs hint precedence**: show a hint only when there is no real status.
  `noteText` ("Saved", "Colors updated") must continue to override hints.
- **Idle hint**: Idle has `custom: true`, so use the literal fallback string
  rather than adding a `hint` to `SettingsPages.js` — identical to old behavior.
- **Text fields**: removing global E/Z/R/S keys prevents letters typed in
  fields from triggering actions. Ensure Up/Down navigation still works from
  the sidebar and page controls (as documented).
- **Launcher actions**: `QuickshellActions.qml` and `launcher/actions/sys.json`
  still call `qs ipc call power ...`; keeping `PowerService` intact preserves
  them. Do not "clean up" the service.
- **Live shell**: edits hot-reload into the running session; do not reload or
  restart `qs`, or call IPC affecting the desktop, during verification.

## 6. Verification and testing steps

1. Format/syntax: run `/usr/lib/qt6/bin/qmlformat -i` on modified QML (no
   `--sort-imports`). For `SettingsPages.js`, run `node --check
   menus/SettingsPages.js` if node exists; otherwise rely on qmltestrunner.
   (`ast.parse` applies to Python, not JS.)
2. Offline suites from `core/.config/quickshell`: `python -B tests/run.py`
   must pass; at minimum `python -B tests/run.py components services`.
3. Static checks:
   - `grep -n "power" menus/SettingsMenu.qml menus/settings/SettingsFooter.qml`
     → nothing (except unrelated comments).
   - `grep -n "hint:" menus/SettingsPages.js` → exactly four hints.
   - `grep -n "Power actions\|Confirm / cancel" menus/SettingsMenu.qml assets/docs.md`
     → nothing.
4. Optional targeted test: add `tests/components/tst_SettingsFooter.qml` using
   `tests/components/ControlConfig.qml`, asserting no power/confirm buttons,
   status text visible when set and hidden when empty. New `tst_*.qml` files in
   `tests/components` are picked up by the existing `components` suite. Keep it
   under `tests/` (gitignored/local only).
5. Hygiene: `git diff --check`; `git status --short` shows only intended files
   plus the pre-existing opencode changes. Do not stage or commit.
