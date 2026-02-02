from ignis import utils, widgets
from modules.utils import load_bar_state
from settings import config
from .widgets.battery import BatteryWidget
from .widgets.clock import ClockWidget
from .widgets.focused_window import WindowTitleWidget
from .widgets.recorder_indicator import RecordingIndicator
from .widgets.system_indicator import SystemIndicatorWidget
from .widgets.system_tray import SystemTrayWidget
from .widgets.workspaces import WorkspaceWidget
from .widgets.idle_indicator import IdleIndicatorWidget


# ───────────────────────────────────────────────
# LAYOUT
# ───────────────────────────────────────────────


def left_section(monitor_name: str):
    return widgets.Box(
        spacing=12,
        child=[
            WorkspaceWidget.create(monitor_name),
            WindowTitleWidget.create(monitor_name),
        ],
    )


def center_section():
    return widgets.Box(
        spacing=4,
        child=[ClockWidget()],
    )


def right_section():
    widgets_list = []

    # Show tray if enabled
    if config.ui.bar_show_system_tray:
        widgets_list.append(SystemTrayWidget())

    # Other widgets
    widgets_list.extend(
        [
            RecordingIndicator(),
            SystemIndicatorWidget(),
            BatteryWidget(),
            IdleIndicatorWidget(),
        ]
    )

    return widgets.Box(
        spacing=4,
        child=widgets_list,
    )


# ───────────────────────────────────────────────
# BAR WINDOW CLASS
# ───────────────────────────────────────────────


class Bar(widgets.RevealerWindow):
    def __init__(self, monitor_id: int = 0):
        monitor_name = utils.get_monitor(monitor_id).get_connector()
        initial_visible = load_bar_state()

        bar_content = widgets.CenterBox(
            css_classes=["bar"],
            start_widget=left_section(monitor_name),
            center_widget=center_section(),
            end_widget=right_section(),
        )

        revealer = widgets.Revealer(
            child=bar_content,
            reveal_child=True,
            transition_type="slide_down",
            transition_duration=100,
        )

        super().__init__(
            namespace=f"ignis_bar_{monitor_id}",
            monitor=monitor_id,
            anchor=["left", "top", "right"],
            exclusivity="exclusive",
            visible=initial_visible,
            css_classes=["unset"],
            child=revealer,
            revealer=revealer,
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
