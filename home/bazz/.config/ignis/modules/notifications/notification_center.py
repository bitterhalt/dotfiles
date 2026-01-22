from ignis import utils, widgets
from ignis.options import options
from ignis.window_manager import WindowManager
from .notification_center_notifications import NotificationList
from .widgets.weather_pill import WeatherPill
from .widgets.media_pill import MediaCenterWidget
from settings import config

wm = WindowManager.get_default()


class NotificationCenter(widgets.Window):
    def __init__(self):
        self._media_pill = MediaCenterWidget()
        self._notification_list = NotificationList()
        dnd_switch = widgets.Switch(
            active=options.notifications.bind("dnd"),
            on_change=lambda _, s: options.notifications.set_dnd(s),
        )

        dnd_box = widgets.Box(
            spacing=8,
            css_classes=["dnd-box"],
            hexpand=True,
            halign="start",
            child=[
                widgets.Label(label="Do Not Disturb", css_classes=["dnd-label"]),
                dnd_switch,
            ],
        )

        clear_btn = widgets.Button(
            child=widgets.Label(label="Clear All"),
            css_classes=["header-action-btn", "unset"],
            on_click=lambda *_: self._notification_list.clear_all(),
        )

        left_column = widgets.Box(
            vertical=True,
            css_classes=["left-column"],
            child=[
                self._notification_list.scroll,
                widgets.Box(
                    spacing=8,
                    halign="fill",
                    valign="end",
                    css_classes=["left-bottom-bar"],
                    child=[dnd_box, clear_btn],
                ),
            ],
        )

        self._weather_pill = WeatherPill()
        self._calendar = widgets.Calendar(
            css_classes=["center-calendar"],
            show_day_names=True,
            show_heading=True,
        )

        right_column = widgets.Box(
            vertical=True,
            css_classes=["right-column"],
            child=[
                self._weather_pill.button,
                self._calendar,
                self._media_pill,
            ],
        )

        two_columns = widgets.Box(
            css_classes=["notification-center"],
            child=[left_column, right_column],
        )

        self._revealer = widgets.Revealer(
            child=two_columns,
            reveal_child=False,
            transition_type="slide_down",
            transition_duration=config.animations.revealer_duration,
        )

        overlay_button = widgets.Button(
            vexpand=True,
            hexpand=True,
            can_focus=False,
            css_classes=["center-overlay", "unset"],
            on_click=lambda x: wm.close_window("ignis_NOTIFICATION_CENTER"),
        )

        root_overlay = widgets.Overlay(
            child=overlay_button,
            overlays=[
                widgets.Box(
                    valign="start",
                    halign="center",
                    css_classes=["center-container"],
                    child=[self._revealer],
                )
            ],
        )

        super().__init__(
            monitor=config.ui.notification_center_monitor,
            visible=False,
            popup=True,
            anchor=["top", "bottom", "left", "right"],
            layer="top",
            namespace="ignis_NOTIFICATION_CENTER",
            css_classes=["center-window"],
            child=root_overlay,
            kb_mode="on_demand",
        )

        self.connect("notify::visible", self._on_visible_change)
        self.connect("destroy", self._cleanup)

    def _cleanup(self, *_):
        if hasattr(self, "_weather_pill") and self._weather_pill:
            try:
                self._weather_pill.destroy()
            except:
                pass

    def _on_visible_change(self, *_):
        if self.visible:
            utils.Timeout(10, lambda: setattr(self._revealer, "reveal_child", True))
        else:
            self._revealer.reveal_child = False
