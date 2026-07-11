#!/usr/bin/env python3

import json
import os
import time
import urllib.request

CACHE_DIR = os.path.expanduser("~/.cache")
CACHE_FILE = os.path.join(CACHE_DIR, "waybar_weather.json")
CACHE_TIMEOUT = 7200  # 2 hours
LOCATION = ""  # Emty means automatic

os.makedirs(CACHE_DIR, exist_ok=True)


def fetch_weather():
    url = f"https://wttr.in/{LOCATION}?format=j1"

    try:
        req = urllib.request.Request(
            url,
        )

        with urllib.request.urlopen(req, timeout=10) as r:
            data = json.loads(r.read().decode())

        with open(CACHE_FILE, "w") as f:
            json.dump(data, f)

        return data

    except Exception:
        return None


def load_weather():
    if os.path.exists(CACHE_FILE):
        age = time.time() - os.path.getmtime(CACHE_FILE)

        if age < CACHE_TIMEOUT:
            try:
                with open(CACHE_FILE) as f:
                    return json.load(f)
            except Exception:
                pass

    data = fetch_weather()
    if data:
        return data

    if os.path.exists(CACHE_FILE):
        try:
            with open(CACHE_FILE) as f:
                return json.load(f)
        except Exception:
            pass

    return None


def icon(condition):
    c = condition.lower()

    if "sunny" in c or "clear" in c:
        return "🌞"
    if "partly" in c and "cloud" in c:
        return "⛅"
    if "cloud" in c or "overcast" in c:
        return "☁️"
    if any(x in c for x in ("mist", "fog", "haze")):
        return "🌫"
    if "drizzle" in c or "light rain" in c:
        return "🌦️"
    if "rain" in c:
        return "🌧️"
    if "thunder" in c:
        return "🌩️"
    if any(x in c for x in ("snow", "sleet", "ice")):
        return "🌨️"
    return "✨"


weather = load_weather()

if weather is None:
    print(
        json.dumps(
            {
                "text": "⚠ N/A",
                "tooltip": "Weather data unavailable",
            }
        )
    )
    raise SystemExit

current = weather["current_condition"][0]
today = weather["weather"][0]

temp = current["temp_C"]
humidity = current["humidity"]
visibility = current["visibility"]
uv = current["uvIndex"]
wind = current["windspeedKmph"]
wind_dir = current["winddir16Point"]
condition = current["weatherDesc"][0]["value"]
city = weather["nearest_area"][0]["areaName"][0]["value"]

sunrise = today["astronomy"][0]["sunrise"]
sunset = today["astronomy"][0]["sunset"]

# Around noon is a good representation of the day
hour = today["hourly"][4]


tooltip = [
    f"<b>{city}</b>: {icon(condition)} {condition}",
    "",
    f"🌡️ <b>Temperature:</b> {temp}°C",
    f"💧 <b>Humidity:</b> {humidity}%",
    f"💨 <b>Wind:</b> {wind} km/h {wind_dir}",
    "",
    f"👀 <b>Visibility:</b> {visibility} km",
    f"🌞 <b>UV Index:</b> {uv}",
    f"🌅 <b>Sunrise:</b> {sunrise}",
    f"🌇 <b>Sunset:</b> {sunset}",
    "",
]

for day in weather["weather"]:
    weekday = time.strftime(
        "%a",
        time.strptime(day["date"], "%Y-%m-%d"),
    )

    forecast = day["hourly"][4]
    desc = forecast["weatherDesc"][0]["value"]

    rain = max(
        int(forecast.get("chanceofrain", 0)),
        int(forecast.get("chanceofshowers", 0)),
    )

    tooltip.append(
        f"{weekday:>3} {icon(desc)} {day['maxtempC']}°/{day['mintempC']}°   🌧️ {rain}%"
    )

print(
    json.dumps(
        {
            "text": f"{icon(condition)} {temp}°C",
            "tooltip": "\n".join(tooltip),
        },
        ensure_ascii=False,
    )
)
