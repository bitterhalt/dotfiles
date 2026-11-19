#!/usr/bin/env python3
"""Open-Meteo conditions and seven-day forecast for the clock popup.

Location: WEATHER_LAT/WEATHER_LON (+ WEATHER_NAME), WEATHER_LOCATION,
WTTR_LOCATION, or approximate IP location. Cached for one hour; --refresh
bypasses freshness checks. An offline refresh can reuse the previous data.
"""

import json
import math
import os
from pathlib import Path
import sys
import tempfile
import time
import urllib.parse
import urllib.request
from datetime import datetime, timezone


CACHE_FILE = Path(os.environ.get("XDG_CACHE_HOME") or Path.home() / ".cache") / "quickshell/weather.json"
CACHE_TIMEOUT = 3600
LAT = os.environ.get("WEATHER_LAT", "")
LON = os.environ.get("WEATHER_LON", "")
NAME = os.environ.get("WEATHER_NAME", "")
LOCATION = os.environ.get("WEATHER_LOCATION") or os.environ.get("WTTR_LOCATION", "")
CONFIG_KEY = f"{LAT}|{LON}|{NAME}|{LOCATION}"

WMO = {
    0: ("Clear sky", "🌞", "🌙"), 1: ("Mainly clear", "🌤️", "🌙"),
    2: ("Partly cloudy", "⛅", "☁️"), 3: ("Overcast", "☁️", "☁️"),
    45: ("Fog", "🌫️", "🌫️"), 48: ("Rime fog", "🌫️", "🌫️"),
    51: ("Light drizzle", "🌦️", "🌧️"), 53: ("Drizzle", "🌦️", "🌧️"),
    55: ("Dense drizzle", "🌧️", "🌧️"), 56: ("Freezing drizzle", "🌨️", "🌨️"),
    57: ("Dense freezing drizzle", "🌨️", "🌨️"),
    61: ("Light rain", "🌦️", "🌧️"), 63: ("Rain", "🌧️", "🌧️"),
    65: ("Heavy rain", "🌧️", "🌧️"), 66: ("Freezing rain", "🌨️", "🌨️"),
    67: ("Heavy freezing rain", "🌨️", "🌨️"),
    71: ("Light snow", "🌨️", "🌨️"), 73: ("Snow", "🌨️", "🌨️"),
    75: ("Heavy snow", "❄️", "❄️"), 77: ("Snow grains", "🌨️", "🌨️"),
    80: ("Light showers", "🌦️", "🌧️"), 81: ("Showers", "🌧️", "🌧️"),
    82: ("Violent showers", "🌧️", "🌧️"),
    85: ("Light snow showers", "🌨️", "🌨️"), 86: ("Heavy snow showers", "❄️", "❄️"),
    95: ("Thunderstorm", "🌩️", "🌩️"),
    96: ("Thunderstorm with hail", "⛈️", "⛈️"),
    99: ("Severe thunderstorm with hail", "⛈️", "⛈️"),
}


def get_json(url):
    request = urllib.request.Request(url, headers={"User-Agent": "quickshell-weather"})
    with urllib.request.urlopen(request, timeout=10) as response:
        return json.load(response)


def resolve_location():
    if LAT and LON:
        return float(LAT), float(LON), NAME or "Weather"
    if LOCATION:
        query = urllib.parse.urlencode({"name": LOCATION, "count": 1})
        hit = get_json(f"https://geocoding-api.open-meteo.com/v1/search?{query}")["results"][0]
        return hit["latitude"], hit["longitude"], hit["name"]
    result = get_json("https://ipwho.is/")
    if not result.get("success"):
        raise ValueError("IP geolocation failed")
    return result["latitude"], result["longitude"], result.get("city") or "Weather"


def fetch_weather():
    lat, lon, place = resolve_location()
    query = urllib.parse.urlencode({
        "latitude": lat, "longitude": lon, "timezone": "auto", "forecast_days": 7,
        "current": "temperature_2m,apparent_temperature,relative_humidity_2m,weather_code,"
                   "wind_speed_10m,wind_direction_10m,visibility,uv_index,is_day",
        "daily": "weather_code,temperature_2m_max,temperature_2m_min,"
                 "precipitation_probability_max,sunrise,sunset",
    })
    data = get_json(f"https://api.open-meteo.com/v1/forecast?{query}")
    data.update(_place=place, _key=CONFIG_KEY)
    # Validate before replacing a usable cache.
    format_weather(data)
    CACHE_FILE.parent.mkdir(parents=True, exist_ok=True)
    temporary = None
    try:
        with tempfile.NamedTemporaryFile(mode="w", dir=CACHE_FILE.parent, delete=False) as file:
            temporary = Path(file.name)
            json.dump(data, file)
        temporary.replace(CACHE_FILE)
    finally:
        if temporary is not None:
            temporary.unlink(missing_ok=True)
    return data


def read_cache():
    try:
        data = json.loads(CACHE_FILE.read_text())
        if data.get("_key") == CONFIG_KEY:
            format_weather(data)
            return data
    except (OSError, ValueError, KeyError, TypeError, IndexError, OverflowError):
        pass
    return None


def load_weather(force_refresh=False):
    if not force_refresh:
        try:
            if time.time() - CACHE_FILE.stat().st_mtime < CACHE_TIMEOUT:
                cached = read_cache()
                if cached:
                    return cached
        except OSError:
            pass
    try:
        return fetch_weather()
    except Exception:
        return read_cache()


def describe(code, is_day=True):
    description, day, night = WMO.get(code, ("Unknown", "✨", "✨"))
    return description, day if is_day else night


def wind_compass(degrees):
    points = "N NNE NE ENE E ESE SE SSE S SSW SW WSW W WNW NW NNW".split()
    return points[int((degrees % 360) / 22.5 + 0.5) % 16]


def moon_info():
    reference = datetime(2000, 1, 6, 18, 14, tzinfo=timezone.utc)
    cycle = ((datetime.now(timezone.utc) - reference).total_seconds() / 86400 % 29.530588853) / 29.530588853
    phases = [(0.03, "New Moon", "🌑"), (0.22, "Waxing Crescent", "🌒"),
              (0.28, "First Quarter", "🌓"), (0.47, "Waxing Gibbous", "🌔"),
              (0.53, "Full Moon", "🌕"), (0.72, "Waning Gibbous", "🌖"),
              (0.78, "Last Quarter", "🌗"), (0.97, "Waning Crescent", "🌘"),
              (1, "New Moon", "🌑")]
    _, name, icon = next(phase for phase in phases if cycle < phase[0])
    return {"name": name, "icon": icon,
            "illumination": round((1 - math.cos(2 * math.pi * cycle)) * 50)}


def hhmm(value):
    return value.split("T")[1][:5] if "T" in value else value


def format_weather(weather):
    current, daily = weather["current"], weather["daily"]
    condition, icon = describe(current["weather_code"], bool(current.get("is_day", 1)))
    temperature = round(current["temperature_2m"])
    forecast = []
    for index, date in enumerate(daily["time"]):
        forecast.append({
            "day": datetime.strptime(date, "%Y-%m-%d").strftime("%a"), "date": date,
            "icon": describe(daily["weather_code"][index])[1],
            "high": round(daily["temperature_2m_max"][index]),
            "low": round(daily["temperature_2m_min"][index]),
            "rain": daily["precipitation_probability_max"][index] or 0,
        })
    return {
        "available": True, "text": f"{icon} {temperature}°C", "icon": icon,
        "place": weather.get("_place") or "Weather", "condition": condition,
        "temperature": temperature, "feels": round(current["apparent_temperature"]),
        "humidity": current["relative_humidity_2m"], "wind": round(current["wind_speed_10m"]),
        "windDirection": wind_compass(current["wind_direction_10m"]),
        "visibility": round((current.get("visibility") or 0) / 1000, 1),
        "uv": round(current.get("uv_index") or 0),
        "sunrise": hhmm(daily["sunrise"][0]), "sunset": hhmm(daily["sunset"][0]),
        "moon": moon_info(), "forecast": forecast,
    }


def main():
    weather = load_weather("--refresh" in sys.argv[1:])
    result = format_weather(weather) if weather else {"available": False, "text": "⚠ N/A", "forecast": []}
    print(json.dumps(result, ensure_ascii=False))


if __name__ == "__main__":
    main()
