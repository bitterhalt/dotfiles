#!/usr/bin/env python3
"""Waybar weather module using Open-Meteo (no API key needed).

Location, in order of priority:
  1. WEATHER_LAT + WEATHER_LON  (optionally WEATHER_NAME for the label)
  2. WEATHER_LOCATION           (city name, resolved via Open-Meteo geocoding)
  3. Approximate IP geolocation (fallback)

WTTR_LOCATION is also honoured as an alias for WEATHER_LOCATION.
"""

import json
import math
import os
import time
import urllib.parse
import urllib.request
from datetime import datetime, timezone

CACHE_DIR = os.path.expanduser("~/.cache")
CACHE_FILE = os.path.join(CACHE_DIR, "waybar_weather.json")
CACHE_TIMEOUT = 3600  # 1 hour

LAT = os.environ.get("WEATHER_LAT", "")
LON = os.environ.get("WEATHER_LON", "")
NAME = os.environ.get("WEATHER_NAME", "")
LOCATION = os.environ.get("WEATHER_LOCATION") or os.environ.get("WTTR_LOCATION", "")

# Changing config invalidates the cache
CONFIG_KEY = f"{LAT}|{LON}|{NAME}|{LOCATION}"

os.makedirs(CACHE_DIR, exist_ok=True)


def get_json(url):
    req = urllib.request.Request(url, headers={"User-Agent": "waybar-weather"})
    with urllib.request.urlopen(req, timeout=10) as r:
        return json.loads(r.read().decode())


def resolve_location():
    """Return (lat, lon, name)."""
    if LAT and LON:
        return float(LAT), float(LON), NAME

    if LOCATION:
        q = urllib.parse.urlencode({"name": LOCATION, "count": 1})
        res = get_json(f"https://geocoding-api.open-meteo.com/v1/search?{q}")
        hit = res["results"][0]
        return hit["latitude"], hit["longitude"], hit["name"]

    # Fallback: approximate location from IP
    ip = get_json("http://ip-api.com/json/?fields=status,city,lat,lon")
    if ip.get("status") != "success":
        raise RuntimeError("IP geolocation failed")
    return ip["lat"], ip["lon"], ip.get("city", "")


def fetch_weather():
    try:
        lat, lon, name = resolve_location()

        params = urllib.parse.urlencode(
            {
                "latitude": lat,
                "longitude": lon,
                "current": ",".join(
                    [
                        "temperature_2m",
                        "apparent_temperature",
                        "relative_humidity_2m",
                        "weather_code",
                        "wind_speed_10m",
                        "wind_direction_10m",
                        "visibility",
                        "uv_index",
                        "is_day",
                    ]
                ),
                "daily": ",".join(
                    [
                        "weather_code",
                        "temperature_2m_max",
                        "temperature_2m_min",
                        "precipitation_probability_max",
                        "sunrise",
                        "sunset",
                    ]
                ),
                "timezone": "auto",
                "forecast_days": 7,
            }
        )
        data = get_json(f"https://api.open-meteo.com/v1/forecast?{params}")
        data["_place"] = name
        data["_key"] = CONFIG_KEY

        with open(CACHE_FILE, "w") as f:
            json.dump(data, f)

        return data
    except Exception:
        return None


def read_cache():
    try:
        with open(CACHE_FILE) as f:
            data = json.load(f)
        if data.get("_key") == CONFIG_KEY:
            return data
    except Exception:
        pass
    return None


def load_weather():
    if os.path.exists(CACHE_FILE):
        age = time.time() - os.path.getmtime(CACHE_FILE)
        if age < CACHE_TIMEOUT:
            data = read_cache()
            if data:
                return data

    data = fetch_weather()
    if data:
        return data

    # Network failed: fall back to stale cache
    return read_cache()


# WMO weather interpretation codes -> (description, day icon, night icon)
WMO = {
    0: ("Clear sky", "🌞", "🌙"),
    1: ("Mainly clear", "🌤️", "🌙"),
    2: ("Partly cloudy", "⛅", "☁️"),
    3: ("Overcast", "☁️", "☁️"),
    45: ("Fog", "🌫️", "🌫️"),
    48: ("Rime fog", "🌫️", "🌫️"),
    51: ("Light drizzle", "🌦️", "🌧️"),
    53: ("Drizzle", "🌦️", "🌧️"),
    55: ("Dense drizzle", "🌧️", "🌧️"),
    56: ("Freezing drizzle", "🌨️", "🌨️"),
    57: ("Dense freezing drizzle", "🌨️", "🌨️"),
    61: ("Light rain", "🌦️", "🌧️"),
    63: ("Rain", "🌧️", "🌧️"),
    65: ("Heavy rain", "🌧️", "🌧️"),
    66: ("Freezing rain", "🌨️", "🌨️"),
    67: ("Heavy freezing rain", "🌨️", "🌨️"),
    71: ("Light snow", "🌨️", "🌨️"),
    73: ("Snow", "🌨️", "🌨️"),
    75: ("Heavy snow", "❄️", "❄️"),
    77: ("Snow grains", "🌨️", "🌨️"),
    80: ("Light showers", "🌦️", "🌧️"),
    81: ("Showers", "🌧️", "🌧️"),
    82: ("Violent showers", "🌧️", "🌧️"),
    85: ("Light snow showers", "🌨️", "🌨️"),
    86: ("Heavy snow showers", "❄️", "❄️"),
    95: ("Thunderstorm", "🌩️", "🌩️"),
    96: ("Thunderstorm with hail", "⛈️", "⛈️"),
    99: ("Severe thunderstorm with hail", "⛈️", "⛈️"),
}


def describe(code, is_day=True):
    desc, day, night = WMO.get(code, ("Unknown", "✨", "✨"))
    return desc, (day if is_day else night)


def wind_compass(deg):
    points = [
        "N",
        "NNE",
        "NE",
        "ENE",
        "E",
        "ESE",
        "SE",
        "SSE",
        "S",
        "SSW",
        "SW",
        "WSW",
        "W",
        "WNW",
        "NW",
        "NNW",
    ]
    return points[int((deg % 360) / 22.5 + 0.5) % 16]


def moon_info():
    """Open-Meteo has no moon data, so compute the phase locally."""
    synodic = 29.530588853
    ref_new_moon = datetime(2000, 1, 6, 18, 14, tzinfo=timezone.utc)
    days = (datetime.now(timezone.utc) - ref_new_moon).total_seconds() / 86400
    cycle = (days % synodic) / synodic  # 0..1
    illum = round((1 - math.cos(2 * math.pi * cycle)) / 2 * 100)

    if cycle < 0.03 or cycle >= 0.97:
        name, emoji = "New Moon", "🌑"
    elif cycle < 0.22:
        name, emoji = "Waxing Crescent", "🌒"
    elif cycle < 0.28:
        name, emoji = "First Quarter", "🌓"
    elif cycle < 0.47:
        name, emoji = "Waxing Gibbous", "🌔"
    elif cycle < 0.53:
        name, emoji = "Full Moon", "🌕"
    elif cycle < 0.72:
        name, emoji = "Waning Gibbous", "🌖"
    elif cycle < 0.78:
        name, emoji = "Last Quarter", "🌗"
    else:
        name, emoji = "Waning Crescent", "🌘"

    return emoji, name, illum


def hhmm(iso):
    return iso.split("T")[1][:5] if "T" in iso else iso


def main():
    weather = load_weather()

    if weather is None:
        print(json.dumps({"text": "⚠ N/A", "tooltip": "Weather data unavailable"}))
        return

    cur = weather["current"]
    daily = weather["daily"]

    is_day = bool(cur.get("is_day", 1))
    condition, cur_icon = describe(cur["weather_code"], is_day)

    temp = round(cur["temperature_2m"])
    feels = round(cur["apparent_temperature"])
    humidity = cur["relative_humidity_2m"]
    wind = round(cur["wind_speed_10m"])
    wind_dir = wind_compass(cur["wind_direction_10m"])
    visibility = round(cur.get("visibility", 0) / 1000, 1)
    uv = round(cur.get("uv_index", 0))
    city = weather.get("_place") or "Weather"

    sunrise = hhmm(daily["sunrise"][0])
    sunset = hhmm(daily["sunset"][0])

    tooltip = [
        f"<b>{city}</b>: {cur_icon} {condition}",
        "",
        f"🌡️ <b>Temperature:</b> {temp}°C (feels like {feels}°C)",
        f"💧 <b>Humidity:</b> {humidity}%",
        f"💨 <b>Wind:</b> {wind} km/h {wind_dir}",
        "",
        f"👀 <b>Visibility:</b> {visibility} km",
        f"🌞 <b>UV Index:</b> {uv}",
        f"🌅 <b>Sunrise:</b> {sunrise}",
        f"🌇 <b>Sunset:</b> {sunset}",
    ]

    moon_emj, moon_name, moon_illum = moon_info()
    tooltip.append(f"{moon_emj} <b>Moon:</b> {moon_name} ({moon_illum}%)")
    tooltip.append("")

    for i, date in enumerate(daily["time"]):
        weekday = time.strftime("%a", time.strptime(date, "%Y-%m-%d"))
        _, day_icon = describe(daily["weather_code"][i], True)
        hi = round(daily["temperature_2m_max"][i])
        lo = round(daily["temperature_2m_min"][i])
        rain = daily["precipitation_probability_max"][i] or 0

        tooltip.append(f"{weekday:>3} {day_icon} {hi}°/{lo}°    🌧️ {rain}%")

    print(
        json.dumps(
            {"text": f"{cur_icon} {temp}°C", "tooltip": "\n".join(tooltip)},
            ensure_ascii=False,
        )
    )


if __name__ == "__main__":
    main()
