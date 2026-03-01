import datetime
from ignis import utils, widgets
from settings import config

_clock_window = None
_clock_overlay = None
_bar_visible = True


class BarlessClockWindow(widgets.Window):
    """Togglable clock"""

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


class BarlessClockOverlay(widgets.Window):
    """Overlay clock that shows only in barless mode"""

    def __init__(self):
        self._timeout = None
        self._time_label = widgets.Label(
            css_classes=["barless-clock-time"],
        )

        self._date_label = widgets.Label(
            css_classes=["barless-clock-date"],
        )

        content = widgets.Box(
            vertical=True,
            spacing=8,
            css_classes=["barless-clock-callable"],
            child=[self._time_label, self._date_label],
        )

        super().__init__(
            monitor=config.ui.primary_monitor,
            layer="overlay",
            anchor=["top", "right"],
            namespace="ignis_BARLESS_CLOCK_OVERLAY",
            visible=False,
            css_classes=["barless-clock-window"],
            child=content,
        )

        self.connect("notify::visible", self._on_visible_changed)

    def _on_visible_changed(self, *_):
        if self.visible:
            self._update_time()

            if self._timeout:
                self._timeout.cancel()

            self._timeout = utils.Timeout(
                config.ui.time_osd_timeout,
                lambda: self.set_visible(False),
            )
        else:
            if self._timeout:
                self._timeout.cancel()
                self._timeout = None

    def _update_time(self):
        now = datetime.datetime.now()
        self._time_label.label = now.strftime("%H:%M")
        self._date_label.label = now.strftime("%A, %d %B")

    def show_overlay(self):
        self.set_visible(True)


def init_barless_clock():
    global _clock_window
    if _clock_window is None:
        _clock_window = BarlessClockWindow()
    return _clock_window


def init_barless_clock_overlay():
    global _clock_overlay
    if _clock_overlay is None:
        _clock_overlay = BarlessClockOverlay()
    return _clock_overlay


def toggle_barless_clock_overlay():
    overlay = init_barless_clock_overlay()
    overlay.show_overlay()


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
