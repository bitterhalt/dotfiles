from ignis import widgets
from ignis.options import options
from ignis.window_manager import WindowManager
from .notifications import NotificationList
from .widgets.date_pill import DateWeatherPill
from .widgets.media_pill import MediaCenterWidget
from settings import config

wm = WindowManager.get_default()


class NotificationCenter(widgets.RevealerWindow):
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

        self._date_weather_pill = DateWeatherPill()

        right_column = widgets.Box(
            vertical=True,
            css_classes=["right-column"],
            child=[
                self._date_weather_pill,
                self._media_pill,
            ],
        )

        two_columns = widgets.Box(
            css_classes=["notification-center"],
            child=[left_column, right_column],
        )

        revealer = widgets.Revealer(
            child=two_columns,
            reveal_child=False,
            transition_type="slide_down",
            transition_duration=config.animations.revealer_duration,
        )

        container = widgets.Box(
            valign="start",
            halign="center",
            css_classes=["center-container"],
            child=[revealer],
        )

        super().__init__(
            monitor=config.ui.notification_center_monitor,
            visible=False,
            popup=True,
            anchor=["top"],
            layer="top",
            namespace="ignis_NOTIFICATION_CENTER",
            css_classes=["center-window"],
            kb_mode="on_demand",
            child=widgets.Box(
                child=[
                    container,
                ]
            ),
            revealer=revealer,
        )

        self.connect("destroy", self._cleanup)

    def _cleanup(self, *_):
        pass
