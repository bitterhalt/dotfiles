from ignis import utils, widgets
from ignis.services.hyprland import HyprlandService
from ignis.services.niri import NiriService
from settings import config

hypr = HyprlandService.get_default()
niri = NiriService.get_default()


class WindowInfoFormatter:
    @staticmethod
    def get_window_text(window, compositor: str) -> str:
        if not window:
            return ""

        if compositor == "hyprland":
            if not window.initial_class or window.address == "0x0":
                return ""

            win_class = window.initial_class
            win_title = window.title or ""

            if win_class.lower() in config.ui.bar_window_title_exceptions:
                return win_title
            return win_class

        elif compositor == "niri":
            if not window.app_id:
                return ""

            win_class = window.app_id
            win_title = window.title or ""

            if win_class.lower() in config.ui.bar_window_title_exceptions:
                return win_title
            return win_class

        return ""

    @staticmethod
    def get_window_icon(window, compositor: str) -> str:
        if not window:
            return "application-x-executable-symbolic"

        if compositor == "hyprland":
            if not window.initial_class or window.address == "0x0":
                return "application-x-executable-symbolic"
            win_class = window.initial_class

        elif compositor == "niri":
            if not window.app_id:
                return "application-x-executable-symbolic"
            win_class = window.app_id
        else:
            return "application-x-executable-symbolic"

        icon_name = utils.get_app_icon_name(win_class)
        return icon_name if icon_name else "application-x-executable-symbolic"

    @staticmethod
    def should_show_icon(window, compositor: str) -> bool:
        if not window:
            return False

        if compositor == "hyprland":
            return bool(window.initial_class and window.address != "0x0")
        elif compositor == "niri":
            return bool(window.app_id)

        return False


class HyprlandWindowTitle(widgets.Box):
    def __init__(self):
        self._icon = widgets.Icon(
            pixel_size=22,
            css_classes=["window-title-icon"],
            image=hypr.bind(
                "active_window",
                transform=lambda win: WindowInfoFormatter.get_window_icon(win, "hyprland"),
            ),
            visible=hypr.bind(
                "active_window",
                transform=lambda win: WindowInfoFormatter.should_show_icon(win, "hyprland"),
            ),
        )

        self._title_label = widgets.Label(
            css_classes=["window-title"],
            ellipsize="end",
            max_width_chars=42,
            halign="start",
            label=hypr.bind(
                "active_window",
                transform=lambda win: WindowInfoFormatter.get_window_text(win, "hyprland"),
            ),
        )

        super().__init__(
            spacing=8,
            child=[self._icon, self._title_label],
        )


class NiriWindowTitle(widgets.Box):
    def __init__(self, monitor_name: str):
        self._monitor_name = monitor_name

        self._icon = widgets.Icon(
            pixel_size=22,
            css_classes=["window-title-icon"],
            image=niri.bind(
                "active_window",
                transform=lambda win: WindowInfoFormatter.get_window_icon(win, "niri"),
            ),
            visible=niri.bind(
                "active_window",
                transform=lambda win: WindowInfoFormatter.should_show_icon(win, "niri")
                and niri.active_output == monitor_name,
            ),
        )

        self._title_label = widgets.Label(
            css_classes=["window-title"],
            ellipsize="end",
            max_width_chars=42,
            halign="start",
            label=niri.bind(
                "active_window",
                transform=lambda win: WindowInfoFormatter.get_window_text(win, "niri"),
            ),
            visible=niri.bind(
                "active_window",
                transform=lambda win: niri.active_output == monitor_name,
            ),
        )

        super().__init__(
            spacing=8,
            child=[self._icon, self._title_label],
        )


class WindowTitleWidget:
    @staticmethod
    def create(monitor_name: str) -> widgets.Widget:
        """Create window title widget for the current WM."""
        if hypr.is_available:
            return HyprlandWindowTitle()
        elif niri.is_available:
            return NiriWindowTitle(monitor_name)
        return widgets.Box()
