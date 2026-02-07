import asyncio
from ignis import utils, widgets
from ignis.window_manager import WindowManager
from modules.weather.data.weather_data import fetch_weather_async

wm = WindowManager.get_default()


class WeatherPill:
    def __init__(self):
        self._poll = None
        self._weather_icon = widgets.Icon(
            image="weather-clouds-symbolic",
            pixel_size=32,
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

        self.button = widgets.Button(
            css_classes=["weather-compact", "unset"],
            on_click=lambda *_: self._open_weather_popup(),
            child=widgets.Box(
                spacing=10,
                halign="center",
                child=[
                    self._weather_icon,
                    self._weather_temp,
                    self._weather_desc,
                ],
            ),
        )
        self.update()
        self._poll = utils.Poll(600000, self.update)

    def destroy(self):
        if self._poll:
            try:
                self._poll.cancel()
            except Exception:
                pass
            self._poll = None

    def update(self, *_):
        asyncio.create_task(self._update_async())
        return True

    async def _update_async(self):
        data = await fetch_weather_async()
        if not data:
            return

        self._weather_icon.image = data["icon"]
        self._weather_temp.label = f"{data['temp']}°"
        self._weather_desc.label = data["desc"]

        tooltip = (
            f"{data['city']}\n"
            f"Feels like {data['feels_like']}°C\n"
            f"Humidity: {data['humidity']}%\n"
            f"Wind: {data['wind']:.1f} m/s\n"
            "\nClick to open weather details"
        )
        self._weather_icon.set_tooltip_text(tooltip)

    def _open_weather_popup(self):
        try:
            wm.close_window("ignis_NOTIFICATION_CENTER")
        except Exception:
            pass

        try:
            wm.open_window("ignis_WEATHER")
        except Exception:
            pass
