import os

from ignis import utils
from ignis.command_manager import CommandManager
from ignis.config_manager import ConfigManager
from ignis.css_manager import CssInfoPath, CssManager
from ignis.options import options
from modules.bar import Bar, register_bar, toggle_bars
from modules.bar.widgets import SystemPopup
from modules.notifications import NotificationCenter, init_notifications
from modules.osd import (
    MediaOsdWindow,
    VolumeOSD,
    init_workspace_osd,
    set_bar_visibility,
    init_barless_clock,
    init_barless_clock_overlay,
    set_barless_clock_visibility,
    toggle_barless_clock_overlay,
)
from modules.osd.workspace_osd import _osd_window
from modules.menus import PowerOverlay, RecordingOverlay
from modules.utils.recorder import register_recorder_commands
from modules.weather import WeatherPopup
from settings import config

options.notifications.popup_timeout = config.ui.notification_popup_timeout
css = CssManager.get_default()
command_manager = CommandManager.get_default()
config_manager = ConfigManager.get_default()
bar = Bar(config.ui.primary_monitor)

# Delete or set "True for auto-reload"
config_manager.autoreload_config = False


def compile_scss(path):
    compiled = utils.sass_compile(path=path)
    lines = compiled.split("\n")
    filtered_lines = [line for line in lines if not line.strip().startswith("@charset")]
    return "\n".join(filtered_lines)


css.apply_css(
    CssInfoPath(
        name="main",
        compiler_function=compile_scss,
        path=os.path.join(utils.get_current_dir(), "style.scss"),
    )
)


# Initialize notifications FIRST (must be before bars)
init_notifications()

# Initialize rest
init_workspace_osd()
init_barless_clock()
init_barless_clock_overlay()
register_bar(bar)


def _on_visible_changed(window, *_):
    set_bar_visibility(window.visible)
    set_barless_clock_visibility(window.visible)
    if not window.visible and _osd_window:
        _osd_window.show_osd()


bar.connect("notify::visible", _on_visible_changed)


def _handle_initial_bar_state():
    """Show workspace OSD on startup if bar starts hidden"""
    if not bar.visible:
        set_bar_visibility(False)
        set_barless_clock_visibility(False)
        from modules.osd.workspace_osd import _osd_window

        if _osd_window:
            utils.Timeout(500, lambda: _osd_window.show_osd())


utils.Timeout(100, _handle_initial_bar_state)

# Initialize components
VolumeOSD()
MediaOsdWindow()
WeatherPopup()
PowerOverlay()
RecordingOverlay()
SystemPopup()
NotificationCenter()

# Register custom commands
command_manager.add_command("toggle-bar", toggle_bars)
command_manager.add_command("toggle-barless-clock", toggle_barless_clock_overlay)
register_recorder_commands()
