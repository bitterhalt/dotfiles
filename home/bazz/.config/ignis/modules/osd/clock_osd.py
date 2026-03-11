import datetime
from ignis import widgets
from settings import config

_clock_window = None
_bar_visible = True


class BarlessClockWindow(widgets.Window):
    def __init__(self):
        self._time_label = widgets.Label(
            css_classes=["barless-clock-time"],
        )

        self._day_name_label = widgets.Label(
            css_classes=["barless-clock-date"],
        )

        self._day_num_label = widgets.Label(
            css_classes=["barless-clock-day-number"],
        )

        self._month_label = widgets.Label(
            css_classes=["barless-clock-date"],
        )

        date_box = widgets.Box(
            child=[self._day_name_label, self._day_num_label, self._month_label],
        )

        content = widgets.Box(
            vertical=True,
            spacing=8,
            css_classes=["barless-clock"],
            child=[self._time_label, date_box],
        )

        super().__init__(
            monitor=config.ui.primary_monitor,
            layer="bottom",
            anchor=["top", "right"],
            namespace="ignis_BARLESS_CLOCK",
            visible=False,
            css_classes=["barless-clock-window"],
            child=content,
        )

        self.update_time()
        self.connect("notify::visible", lambda *_: self.update_time() if self.visible else None)

    def update_time(self):
        now = datetime.datetime.now()
        self._time_label.label = now.strftime("%H:%M")
        self._day_name_label.label = now.strftime("%A, ")
        self._day_num_label.label = now.strftime("%d")
        self._month_label.label = now.strftime(" %B")


def init_barless_clock():
    global _clock_window
    if _clock_window is None:
        _clock_window = BarlessClockWindow()
    return _clock_window


def update_barless_clock():
    global _clock_window
    if _clock_window is not None and _clock_window.visible:
        _clock_window.update_time()


def set_barless_clock_visibility(bar_visible: bool):
    global _bar_visible, _clock_window
    _bar_visible = bar_visible

    if _clock_window is None:
        return
    _clock_window.visible = not bar_visible
