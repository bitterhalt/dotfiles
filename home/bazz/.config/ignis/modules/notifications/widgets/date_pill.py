import asyncio
import datetime
from ignis import utils, widgets
from ignis.window_manager import WindowManager
from modules.weather.data.weather_data import fetch_weather_async

wm = WindowManager.get_default()


class DateWeatherPill(widgets.Button):
    def __init__(self):
        self._date_poll = None
        self._weather_poll = None

        # Date section
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

        self._separator = widgets.Separator(
            css_classes=["date-pill-separator"],
            vertical=True,
        )

        date_box = widgets.Box(
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

        self._weather_temp = widgets.Label(
            label="--°",
            css_classes=["weather-temp-compact"],
        )

        self._weather_desc = widgets.Label(
            label="…",
            css_classes=["weather-desc-compact"],
            ellipsize="end",
            max_width_chars=20,
        )

        weather_box = widgets.Box(
            spacing=20,
            halign="center",
            child=[
                self._weather_temp,
                self._weather_desc,
            ],
        )

        # Combined layout - stacked vertically
        content_box = widgets.Box(
            vertical=True,
            spacing=12,
            halign="fill",
            child=[date_box, self._separator, weather_box],
        )

        super().__init__(
            css_classes=["date-weather-pill", "unset"],
            on_click=lambda *_: self._open_weather_popup(),
            child=content_box,
        )

        self._update_date()
        self._update_weather()

        self._date_poll = utils.Poll(60000, lambda *_: self._update_date())
        self._weather_poll = utils.Poll(600000, lambda *_: self._update_weather())

        self.connect("destroy", self._cleanup)

    def _update_date(self):
        now = datetime.datetime.now()
        self._name_label.label = now.strftime("%a")
        self._day_label.label = now.strftime("%d")
        self._month_label.label = now.strftime("%B")
        self._year_label.label = now.strftime("%Y")
        return True

    def _update_weather(self):
        asyncio.create_task(self._update_weather_async())
        return True

    async def _update_weather_async(self):
        data = await fetch_weather_async()
        if not data:
            return

        self._weather_temp.label = f"{data['temp']}°"
        self._weather_desc.label = data["desc"]

        tooltip = (
            f"Weather @ {data['city']}\n\n"
            f"Feels like {data['feels_like']}°C\n"
            f"Humidity: {data['humidity']}%\n"
            f"Wind: {data['wind']:.1f} m/s\n"
            "\nClick to open weather details"
        )
        self.set_tooltip_text(tooltip)

    def _open_weather_popup(self):
        try:
            wm.close_window("ignis_NOTIFICATION_CENTER")
        except Exception:
            pass

        try:
            wm.open_window("ignis_WEATHER")
        except Exception:
            pass

    def _cleanup(self, *_):
        if self._date_poll:
            try:
                self._date_poll.cancel()
            except:
                pass
            self._date_poll = None

        if self._weather_poll:
            try:
                self._weather_poll.cancel()
            except:
                pass
            self._weather_poll = None
