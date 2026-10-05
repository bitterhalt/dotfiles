#!/usr/bin/env python3
"""Quickshell weather data using Open-Meteo.

Location priority:
  1. WEATHER_LAT + WEATHER_LON (optionally WEATHER_NAME)
  2. WEATHER_LOCATION
  3. WTTR_LOCATION
  4. Approximate IP geolocation

Cache:
  ~/.cache/quickshell/weather.json
Refresh:
  3600 seconds
"""

import json
import math
import os
import time
import urllib.parse
import urllib.request
from datetime import datetime, timezone

CACHE_DIR = os.path.expanduser("~/.cache/quickshell")
CACHE_FILE = os.path.join(CACHE_DIR, "weather.json")
CACHE_TIMEOUT = 3600

LAT = os.environ.get("WEATHER_LAT", "")
LON = os.environ.get("WEATHER_LON", "")
NAME = os.environ.get("WEATHER_NAME", "")
LOCATION = os.environ.get("WEATHER_LOCATION") or os.environ.get("WTTR_LOCATION", "")
CONFIG_KEY = f"{LAT}|{LON}|{NAME}|{LOCATION}"

os.makedirs(CACHE_DIR, exist_ok=True)

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


def get_json(url):
    req = urllib.request.Request(url, headers={"User-Agent": "quickshell-weather"})
    with urllib.request.urlopen(req, timeout=10) as response:
        return json.loads(response.read().decode())


def resolve_location():
    if LAT and LON:
        return float(LAT), float(LON), NAME or "Weather"

    if LOCATION:
        q = urllib.parse.urlencode({"name": LOCATION, "count": 1})
        result = get_json(f"https://geocoding-api.open-meteo.com/v1/search?{q}")
        hit = result["results"][0]
        return hit["latitude"], hit["longitude"], hit["name"]

    ip = get_json("http://ip-api.com/json/?fields=status,city,lat,lon")
    if ip.get("status") != "success":
        raise RuntimeError("IP geolocation failed")

    return ip["lat"], ip["lon"], ip.get("city") or "Weather"


def fetch_weather():
    lat, lon, place = resolve_location()

    params = urllib.parse.urlencode({
        "latitude": lat,
        "longitude": lon,
        "current": ",".join([
            "temperature_2m",
            "apparent_temperature",
            "relative_humidity_2m",
            "weather_code",
            "wind_speed_10m",
            "wind_direction_10m",
            "visibility",
            "uv_index",
            "is_day",
        ]),
        "daily": ",".join([
            "weather_code",
            "temperature_2m_max",
            "temperature_2m_min",
            "precipitation_probability_max",
            "sunrise",
            "sunset",
        ]),
        "timezone": "auto",
        "forecast_days": 7,
    })

    data = get_json(f"https://api.open-meteo.com/v1/forecast?{params}")
    data["_place"] = place
    data["_key"] = CONFIG_KEY

    with open(CACHE_FILE, "w") as f:
        json.dump(data, f)

    return data


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
            cached = read_cache()
            if cached:
                return cached

    try:
        return fetch_weather()
    except Exception:
        return read_cache()


def describe(code, is_day=True):
    desc, day, night = WMO.get(code, ("Unknown", "✨", "✨"))
    return desc, day if is_day else night


def wind_compass(deg):
    points = [
        "N", "NNE", "NE", "ENE",
        "E", "ESE", "SE", "SSE",
        "S", "SSW", "SW", "WSW",
        "W", "WNW", "NW", "NNW",
    ]
    return points[int((deg % 360) / 22.5 + 0.5) % 16]


def moon_info():
    synodic = 29.530588853
    ref_new_moon = datetime(2000, 1, 6, 18, 14, tzinfo=timezone.utc)
    days = (datetime.now(timezone.utc) - ref_new_moon).total_seconds() / 86400
    cycle = (days % synodic) / synodic
    illumination = round((1 - math.cos(2 * math.pi * cycle)) / 2 * 100)

    if cycle < 0.03 or cycle >= 0.97:
        name, icon = "New Moon", "🌑"
    elif cycle < 0.22:
        name, icon = "Waxing Crescent", "🌒"
    elif cycle < 0.28:
        name, icon = "First Quarter", "🌓"
    elif cycle < 0.47:
        name, icon = "Waxing Gibbous", "🌔"
    elif cycle < 0.53:
        name, icon = "Full Moon", "🌕"
    elif cycle < 0.72:
        name, icon = "Waning Gibbous", "🌖"
    elif cycle < 0.78:
        name, icon = "Last Quarter", "🌗"
    else:
        name, icon = "Waning Crescent", "🌘"

    return {
        "icon": icon,
        "name": name,
        "illumination": illumination,
    }


def hhmm(value):
    return value.split("T")[1][:5] if "T" in value else value


def main():
    weather = load_weather()

    if weather is None:
        print(json.dumps({
            "available": False,
            "text": "⚠ N/A",
        }))
        return

    cur = weather["current"]
    daily = weather["daily"]

    condition, icon = describe(
        cur["weather_code"],
        bool(cur.get("is_day", 1))
    )

    temp = round(cur["temperature_2m"])
    feels = round(cur["apparent_temperature_2m"]) if "apparent_temperature_2m" in cur else round(cur["apparent_temperature"])

    forecast = []
    for i, date in enumerate(daily["time"]):
        weekday = time.strftime("%a", time.strptime(date, "%Y-%m-%d"))
        _, day_icon = describe(daily["weather_code"][i], True)

        forecast.append({
            "day": weekday,
            "date": date,
            "icon": day_icon,
            "high": round(daily["temperature_2m_max"][i]),
            "low": round(daily["temperature_2m_min"][i]),
            "rain": daily["precipitation_probability_max"][i] or 0,
        })

    result = {
        "available": True,
        "text": f"{icon} {temp}°C",
        "place": weather.get("_place") or "Weather",
        "condition": condition,
        "icon": icon,
        "temperature": temp,
        "feels": feels,
        "humidity": cur["relative_humidity_2m"],
        "wind": round(cur["wind_speed_10m"]),
        "windDirection": wind_compass(cur["wind_direction_10m"]),
        "visibility": round(cur.get("visibility", 0) / 1000, 1),
        "uv": round(cur.get("uv_index", 0)),
        "sunrise": hhmm(daily["sunrise"][0]),
        "sunset": hhmm(daily["sunset"][0]),
        "moon": moon_info(),
        "forecast": forecast,
    }

    print(json.dumps(result, ensure_ascii=False))


if __name__ == "__main__":
    main()
