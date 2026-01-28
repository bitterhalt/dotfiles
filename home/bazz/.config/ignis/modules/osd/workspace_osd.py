from ignis import utils, widgets
from ignis.services.hyprland import HyprlandService
from ignis.services.niri import NiriService
from modules.utils.signal_manager import SignalManager
from modules.utils.workspace_utils import WorkspaceNameFormatter
from settings import config

TIMEOUT = config.ui.workspace_osd_timeout

hypr = HyprlandService.get_default()
niri = NiriService.get_default()

_osd_window = None
_bar_visible = True


class WorkspaceOSD(widgets.Window):
    def __init__(self):
        self._timeout = None
        self._signals = SignalManager()
        self._label = widgets.Label(css_classes=["workspace-osd-label"])

        icon = widgets.Icon(
            image="media-record-symbolic",
            pixel_size=22,
            css_classes=["workspace-osd-icon"],
        )

        content = widgets.Box(
            css_classes=["workspace-osd"],
            spacing=12,
            child=[icon, self._label],
        )

        super().__init__(
            monitor=config.ui.primary_monitor,
            layer="overlay",
            anchor=["top"],
            namespace="ignis_WORKSPACE_OSD",
            visible=False,
            css_classes=["workspace-osd-window"],
            child=content,
        )

        self.connect("notify::visible", self._on_visible_changed)

        if hypr.is_available:
            self._signals.connect(hypr, "notify::active-workspace", self._on_workspace_change)
        elif niri.is_available:
            self._signals.connect(niri, "notify::active-workspace", self._on_workspace_change)

        self.connect("destroy", self._cleanup)

    def _cleanup(self, *_):
        self._signals.disconnect_all()
        if self._timeout:
            try:
                self._timeout.cancel()
            except:
                pass
            self._timeout = None

    def _on_visible_changed(self, *_):
        if self.get_visible():
            self._start_timeout()
        else:
            self._cancel_timeout()

    def _start_timeout(self):
        if self._timeout:
            self._timeout.cancel()
        self._timeout = utils.Timeout(TIMEOUT, lambda: self.set_visible(False))

    def _cancel_timeout(self):
        if self._timeout:
            self._timeout.cancel()
            self._timeout = None

    def show_osd(self):
        self.set_visible(True)

    def _on_workspace_change(self, *_):
        if _bar_visible:
            return

        ws_name = WorkspaceNameFormatter.get_workspace_name()
        if ws_name is None:
            return

        self._label.set_label(f"Workspace: {ws_name}")
        self.show_osd()

    def update_workspace_label(self):
        ws_name = WorkspaceNameFormatter.get_workspace_name()
        if ws_name:
            self._label.set_label(f"Workspace: {ws_name}")


def init_workspace_osd():
    global _osd_window
    if _osd_window is None:
        _osd_window = WorkspaceOSD()
    return _osd_window


def set_bar_visibility(visible: bool):
    global _bar_visible
    _bar_visible = visible

    if not visible and _osd_window:
        _osd_window.update_workspace_label()
        _osd_window.show_osd()
