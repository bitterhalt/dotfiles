import os
import asyncio
from pathlib import Path
from ignis import utils, widgets
from modules.utils.signal_manager import SignalManager


def exec_async(cmd: str):
    asyncio.create_task(utils.exec_sh_async(cmd))


class IdleIndicatorWidget(widgets.EventBox):
    def __init__(self):
        self._signals = SignalManager()
        self._pid_file = Path.home() / ".cache" / "hypridle.pid"
        self._monitor = None
        self._pending_update = False

        self._icon = widgets.Icon(
            image="my-caffeine-on-symbolic",
            pixel_size=22,
            css_classes=["idle-icon"],
        )

        super().__init__(
            css_classes=["idle-indicator"],
            child=[self._icon],
            on_click=lambda x: self._toggle_hypridle(),
        )

        self._pid_file.parent.mkdir(parents=True, exist_ok=True)

        if not self._pid_file.exists():
            self._pid_file.touch()

        self._monitor = utils.FileMonitor(
            path=str(self._pid_file),
            callback=lambda *args: self._on_pid_file_changed(args[-2], args[-1]),
        )

        self._update_status()
        self.connect("destroy", lambda *_: self._cleanup())

    def _on_pid_file_changed(self, path, event_type):
        if event_type in ["changed", "changes_done_hint", "created", "deleted"]:
            if not self._pending_update:
                self._pending_update = True
                utils.Timeout(100, self._delayed_update)

    def _delayed_update(self):
        self._pending_update = False
        self._update_status()

    def _update_status(self):
        is_running = self._is_hypridle_running()

        self.visible = not is_running

        if not is_running:
            self.set_tooltip_text("Idle timer disabled\n\nClick to enable")

    def _is_hypridle_running(self):
        if not self._pid_file.exists():
            return False

        try:
            pid_content = self._pid_file.read_text().strip()
            if not pid_content:
                return False

            pid = int(pid_content)

            try:
                os.kill(pid, 0)
                cmdline_path = Path(f"/proc/{pid}/cmdline")
                if cmdline_path.exists():
                    return "hypridle" in cmdline_path.read_text()
                return False
            except (OSError, ProcessLookupError):
                return False

        except (ValueError, FileNotFoundError):
            return False

    def _toggle_hypridle(self):
        exec_async(str(Path.home() / ".config/ignis/scripts/idle.sh"))

    def _cleanup(self):
        self._signals.disconnect_all()
        if self._monitor:
            try:
                self._monitor.cancel()
            except:
                pass
            self._monitor = None
