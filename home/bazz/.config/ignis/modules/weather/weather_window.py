import asyncio
from datetime import datetime
from typing import List, Optional
from ignis import utils, widgets
from ignis.window_manager import WindowManager
from settings import config
from .data.weather_data import fetch_weather_async, format_time_hm, icon_path

wm = WindowManager.get_default()
CACHE_TTL = config.weather.cache_ttl


class WeatherPopup(widgets.RevealerWindow):
    def __init__(self):
        self._icon_label = widgets.Icon(
            image=icon_path("cloudy"),
            pixel_size=56,
            css_classes=["weather-main-icon"],
        )

        self._city_label = widgets.Label(label="—", css_classes=["weather-city"])
        self._temp_label = widgets.Label(label="--°C", css_classes=["weather-temp"])
        self._desc_label = widgets.Label(label="—", css_classes=["weather-desc"])
        self._extra_label = widgets.Label(label="—", css_classes=["weather-extra"])

        self._moon_label = widgets.Label(
            label="🌕",
            css_classes=["weather-moon-emoji"],
        )

        self._forecast_box = widgets.Box(
            spacing=16,
            halign="center",
            css_classes=["weather-forecast-row"],
        )

        self._weekly_box = widgets.Box(
            spacing=16,
            halign="center",
            visible=False,
            css_classes=["weather-weekly-row"],
        )

        self._weekly_arrow = widgets.Icon(
            image="pan-down-symbolic",
            pixel_size=16,
            css_classes=["weekly-arrow"],
        )

        self._weekly_toggle = widgets.Button(
            on_click=lambda x: self._toggle_weekly(),
            child=widgets.Box(
                spacing=6,
                halign="center",
                child=[
                    widgets.Label(
                        label="Show weekly forecast",
                        css_classes=["weather-weekly-toggle"],
                    ),
                    self._weekly_arrow,
                ],
            ),
            css_classes=["weather-weekly-toggle-btn", "unset"],
        )

        left_row = widgets.Box(
            spacing=12,
            halign="start",
            hexpand=True,
            child=[self._icon_label, self._city_label, self._temp_label],
        )

        header_top = widgets.Box(
            spacing=12,
            halign="fill",
            hexpand=True,
            child=[left_row, self._moon_label],
        )

        middle_column = widgets.Box(
            vertical=True,
            spacing=4,
            halign="center",
            hexpand=True,
            child=[self._desc_label, self._extra_label],
        )

        header = widgets.Box(
            vertical=True,
            spacing=10,
            hexpand=True,
            css_classes=["weather-header"],
            child=[header_top, middle_column],
        )

        popup_box = widgets.Box(
            vertical=True,
            spacing=18,
            css_classes=["weather-popup"],
            child=[
                header,
                self._forecast_box,
                self._weekly_toggle,
                self._weekly_box,
            ],
        )

        revealer = widgets.Revealer(
            child=popup_box,
            reveal_child=True,
            transition_type="slide_down",
            transition_duration=config.animations.revealer_duration,
        )

        super().__init__(
            monitor=config.ui.weather_monitor,
            visible=False,
            anchor=["top"],
            namespace="ignis_WEATHER",
            layer="top",
            popup=True,
            kb_mode="on_demand",
            css_classes=["weather-window"],
            child=widgets.Box(
                child=[
                    widgets.Box(
                        valign="start",
                        halign="center",
                        css_classes=["weather-container"],
                        child=[revealer],
                    ),
                ]
            ),
            revealer=revealer,
        )

        self._last_data: Optional[dict] = None
        self._update_task = None
        self._refresh_poll = None
        self.connect("notify::visible", self._on_visible_change)
        self._refresh_poll = utils.Poll(CACHE_TTL * 1000, lambda *_: self._update_weather())
        self.connect("destroy", self._cleanup)

    def _cleanup(self, *_):
        if self._refresh_poll:
            try:
                self._refresh_poll.cancel()
            except:
                pass
            self._refresh_poll = None
        if self._update_task:
            try:
                self._update_task.cancel()
            except:
                pass
            self._update_task = None

    def _on_visible_change(self, *_):
        if self.visible:
            self._update_weather()
        else:
            self._weekly_box.visible = False
            self._weekly_arrow.set_css_classes(["weekly-arrow"])
            self._weekly_toggle.child.child[0].label = "Show weekly forecast"

    def toggle(self):
        if not self.visible:
            self.visible = True
            self._update_weather()
        else:
            self.visible = False

    def get_last_data(self):
        return self._last_data

    def _toggle_weekly(self):
        current = self._weekly_box.visible
        new_state = not current
        self._weekly_box.visible = new_state
        label = "Hide weekly forecast" if new_state else "Show weekly forecast"
        self._weekly_toggle.child.child[0].label = label
        self._weekly_arrow.set_css_classes(["expand-arrow", "rotated"] if new_state else ["expand-arrow"])

    def _update_weather(self):
        self._update_task = asyncio.create_task(self._update_weather_async())
        return True

    async def _update_weather_async(self):
        data = await fetch_weather_async()

        if not data:
            return

        self._last_data = data
        self._icon_label.image = data["icon"]
        self._city_label.label = data["city"]
        self._temp_label.label = f"{data['temp']}°C"
        self._desc_label.label = data["desc"]
        self._extra_label.label = (
            f"Feels like {data['feels_like']}°C  •  Humidity {data['humidity']}%  •  Wind {data['wind']:.1f} m/s"
        )

        if moon := data.get("moon_icon"):
            self._moon_label.label = moon
        if tip := data.get("moon_tooltip"):
            self._moon_label.set_tooltip_text(tip)

        hourly_items: List[widgets.Widget] = []

        for it in data["forecast"]:
            hourly_items.append(
                widgets.Box(
                    vertical=True,
                    halign="center",
                    spacing=4,
                    css_classes=["weather-forecast-item"],
                    child=[
                        widgets.Label(label=it["time"], css_classes=["weather-forecast-time"]),
                        widgets.Icon(
                            image=it["icon"],
                            pixel_size=40,
                            css_classes=["weather-forecast-icon"],
                        ),
                        widgets.Label(
                            label=f"{it['temp']}°C",
                            css_classes=["weather-forecast-temp"],
                        ),
                    ],
                )
            )
        sunrise = format_time_hm(datetime.fromtimestamp(data["sunrise"]))
        sunset = format_time_hm(datetime.fromtimestamp(data["sunset"]))

        for label, icon in [("Sunrise", "sunrise"), ("Sunset", "sunset")]:
            hourly_items.append(
                widgets.Box(
                    vertical=True,
                    halign="center",
                    spacing=4,
                    css_classes=["weather-forecast-item"],
                    child=[
                        widgets.Label(label=label, css_classes=["weather-forecast-time"]),
                        widgets.Icon(
                            image=icon_path(icon),
                            pixel_size=40,
                            css_classes=["weather-forecast-icon"],
                        ),
                        widgets.Label(
                            label=sunrise if label == "Sunrise" else sunset,
                            css_classes=["weather-forecast-temp"],
                        ),
                    ],
                )
            )

        self._forecast_box.child = hourly_items

        weekly_items = []
        for it in data.get("weekly", []):
            weekly_items.append(
                widgets.Box(
                    vertical=True,
                    halign="center",
                    spacing=4,
                    css_classes=["weather-weekly-item"],
                    child=[
                        widgets.Label(label=it["day"], css_classes=["weather-weekly-day"]),
                        widgets.Icon(
                            image=it["icon"],
                            pixel_size=32,
                            css_classes=["weather-weekly-icon"],
                        ),
                        widgets.Label(
                            label=f"{it['temp']}°C",
                            css_classes=["weather-weekly-temp"],
                        ),
                    ],
                )
            )
        self._weekly_box.child = weekly_items
