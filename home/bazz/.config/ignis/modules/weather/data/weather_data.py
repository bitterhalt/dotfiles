import asyncio
import json
import time
from datetime import datetime
from typing import Any, Dict, Optional
from ignis import utils
from settings import config
from .moon import moon_icon_for, moon_tooltip

CACHE_FILE = config.paths.weather_cache
CACHE_TTL = config.weather.cache_ttl
USE_12H = config.weather.use_12h_format
ICON_BASE = config.weather.icon_base_path
API_KEY = config.weather.api_key
CITY_ID = config.weather.city_id


def icon_path(name: str) -> str:
    return f"{ICON_BASE}/{name}.svg"


def format_time_hm(dt: datetime) -> str:
    if USE_12H:
        return dt.strftime("%-I:%M %p").lstrip("0")
    return dt.strftime("%H:%M")


def _load_cache() -> Optional[Dict[str, Any]]:
    try:
        if not CACHE_FILE.exists():
            return None
        return json.loads(CACHE_FILE.read_text())
    except:
        return None


def _save_cache(data: Dict[str, Any]):
    try:
        CACHE_FILE.parent.mkdir(parents=True, exist_ok=True)
        CACHE_FILE.write_text(json.dumps(data))
    except:
        pass


def _build_url(endpoint: str) -> Optional[str]:
    if not API_KEY:
        return None
    base = "https://api.openweathermap.org/data/2.5"
    return f"{base}/{endpoint}?id={CITY_ID}&units=metric&appid={API_KEY}"


async def _curl_json_async(url: str) -> Optional[dict]:
    try:
        res = await utils.exec_sh_async(f"curl -sfL '{url}'")
        if res.returncode != 0:
            return None
        return json.loads(res.stdout)
    except:
        return None


def _map_icon(code: str) -> str:
    if not code:
        return icon_path("not-available")
    base = code[:2]
    day = code.endswith("d")
    if base == "01":
        return icon_path("clear-day" if day else "clear-night")
    if base == "02":
        return icon_path("partly-cloudy-day" if day else "partly-cloudy-night")
    if base in ("03", "04"):
        return icon_path("cloudy")
    if base == "09":
        return icon_path("drizzle")
    if base == "10":
        return icon_path("rain")
    if base == "11":
        return icon_path("thunderstorms")
    if base == "13":
        return icon_path("snow")
    if base == "50":
        return icon_path("fog")
    return icon_path("not-available")


async def fetch_weather_async() -> Optional[Dict[str, Any]]:
    cached = _load_cache()
    now = int(time.time())
    if cached and now - cached.get("timestamp", 0) < CACHE_TTL:
        return cached["data"]
    url_now = _build_url("weather")
    url_fc = _build_url("forecast")
    if not url_now or not url_fc:
        return cached["data"] if cached else None
    now_json, fc_json = await asyncio.gather(
        _curl_json_async(url_now),
        _curl_json_async(url_fc),
    )
    if not now_json or not fc_json:
        return cached["data"] if cached else None
    try:
        main = now_json["main"]
        weather0 = now_json["weather"][0]
        wind = now_json.get("wind", {})
        temp = round(main["temp"])
        feels = round(main["feels_like"])
        humidity = int(main["humidity"])
        wind_speed = float(wind.get("speed", 0.0))
        sunrise = now_json["sys"]["sunrise"]
        sunset = now_json["sys"]["sunset"]
        desc = weather0["description"].title()
        icon_code = weather0["icon"]
        forecast_list = fc_json["list"][:4]
        forecast = []
        for entry in forecast_list:
            dt = datetime.fromtimestamp(entry["dt"])
            w0 = entry["weather"][0]
            forecast.append(
                {
                    "time": format_time_hm(dt),
                    "temp": round(entry["main"]["temp"]),
                    "icon": _map_icon(w0["icon"]),
                }
            )

        current_date = datetime.now()
        data = {
            "city": now_json["name"],
            "temp": temp,
            "desc": desc,
            "feels_like": feels,
            "humidity": humidity,
            "wind": wind_speed,
            "sunrise": sunrise,
            "sunset": sunset,
            "icon": _map_icon(icon_code),
            "icon_code": icon_code,
            "forecast": forecast,
            "moon_icon": moon_icon_for(current_date),
            "moon_tooltip": moon_tooltip(current_date),
        }

        daily_map = {}
        for entry in fc_json["list"]:
            dt = datetime.fromtimestamp(entry["dt"])
            date_key = dt.date()
            daily_map.setdefault(date_key, []).append(entry)
        weekly = []
        today = datetime.now().date()
        for date_key, items in daily_map.items():
            if date_key == today:
                continue
            best = min(items, key=lambda e: abs(datetime.fromtimestamp(e["dt"]).hour - 12))
            w0 = best["weather"][0]
            weekly.append(
                {
                    "day": date_key.strftime("%a"),
                    "temp": round(best["main"]["temp"]),
                    "icon": _map_icon(w0["icon"]),
                }
            )
        weekly = weekly[:5]
        data["weekly"] = weekly
        _save_cache({"timestamp": int(time.time()), "data": data})
        return data
    except:
        return cached["data"] if cached else None
