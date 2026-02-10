import datetime
from ignis import utils, widgets


class DatePill(widgets.Box):
    def __init__(self):
        self._name_label = widgets.Label(
            css_classes=["date-pill-name"],
        )

        self._day_label = widgets.Label(
            css_classes=["date-pill-day"],
        )

        self._month_label = widgets.Label(
            css_classes=["date-pill-month"],
        )

        self._year_label = widgets.Label(
            css_classes=["date-pill-year"],
        )

        text_box = widgets.Box(
            spacing=20,
            halign="center",
            hexpand=True,
            child=[
                self._name_label,
                self._day_label,
                self._month_label,
                self._year_label,
            ],
        )

        super().__init__(
            css_classes=["date-pill"],
            child=[text_box],
        )

        self._update_date()
        self._poll = utils.Poll(60000, lambda *_: self._update_date())
        self.connect("destroy", self._cleanup)

    def _update_date(self):
        now = datetime.datetime.now()
        self._name_label.label = now.strftime("%a")
        self._day_label.label = now.strftime("%d")
        self._month_label.label = now.strftime("%B")  # Full month name in uppercase
        self._year_label.label = now.strftime("%Y")
        return True

    def _cleanup(self, *_):
        if self._poll:
            try:
                self._poll.cancel()
            except:
                pass
            self._poll = None
