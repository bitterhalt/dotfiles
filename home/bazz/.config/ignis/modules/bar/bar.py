from ignis import utils, widgets
from modules.utils import load_bar_state
from settings import config
from .widgets.battery import BatteryWidget
from .widgets.clock import ClockWidget
from .widgets.focused_window import WindowTitleWidget
from .widgets.recorder import RecordingIndicator
from .widgets.system_indicator import SystemIndicatorWidget
from .widgets.workspaces import WorkspaceWidget

# ───────────────────────────────────────────────
# LAYOUT
# ───────────────────────────────────────────────


def left_section(monitor_name: str):
    return widgets.Box(
        spacing=18,
        child=[
            WorkspaceWidget.create(monitor_name),
            WindowTitleWidget.create(monitor_name),
        ],
    )


def center_section():
    return widgets.Box(
        spacing=12,
        child=[ClockWidget()],
    )


def right_section():
    return widgets.Box(
        spacing=12,
        child=[
            RecordingIndicator(),
            SystemIndicatorWidget(),
            BatteryWidget(),
        ],
    )


# ───────────────────────────────────────────────
# BAR WINDOW CLASS
# ───────────────────────────────────────────────


class Bar(widgets.Window):
    def __init__(self, monitor_id: int = 0):
        monitor_name = utils.get_monitor(monitor_id).get_connector()
        initial_visible = load_bar_state()

        super().__init__(
            namespace=f"ignis_bar_{monitor_id}",
            monitor=monitor_id,
            anchor=["left", "top", "right"],
            exclusivity="exclusive",
            visible=initial_visible,
            child=widgets.CenterBox(
                css_classes=["bar"],
                start_widget=left_section(monitor_name),
                center_widget=center_section(),
                end_widget=right_section(),
            ),
        )


# ───────────────────────────────────────────────
# INITIALIZATION FUNCTION
# ───────────────────────────────────────────────


def init_bars():
    primary_monitor = config.ui.bar_monitor
    bar = Bar(primary_monitor)

    def _on_visible_changed(window, *_):
        from modules.osd.workspace_osd import _osd_window, set_bar_visibility

        set_bar_visibility(window.visible)

        if not window.visible and _osd_window:
            _osd_window.show_osd()

    bar.connect("notify::visible", _on_visible_changed)

    return bar
