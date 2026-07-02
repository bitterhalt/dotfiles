#!/usr/bin/env bash

CACHE_DIR="$HOME/.cache"
CACHE_FILE="$CACHE_DIR/waybar_weather.json"
CACHE_TIMEOUT=7200
# Leave empty "" for auto-location, or specify a city like "Paris"
LOCATION=""

fetch_weather() {
  curl -s "https://wttr.in/${LOCATION}?format=j1" >"$CACHE_FILE"
}

if [ ! -f "$CACHE_FILE" ]; then
  fetch_weather
else
  LAST_MOD=$(stat -c %Y "$CACHE_FILE")
  NOW=$(date +%s)
  if ((NOW - LAST_MOD > CACHE_TIMEOUT)); then
    fetch_weather
  fi
fi

if [ -s "$CACHE_FILE" ]; then
  temp=$(jq -r '.current_condition[0].temp_C' "$CACHE_FILE")

  # Daily High / Low
  max_temp=$(jq -r '.weather[0].maxtempC' "$CACHE_FILE")
  min_temp=$(jq -r '.weather[0].mintempC' "$CACHE_FILE")
  humidity=$(jq -r '.current_condition[0].humidity' "$CACHE_FILE")
  condition=$(jq -r '.current_condition[0].weatherDesc[0].value' "$CACHE_FILE")
  city=$(jq -r '.nearest_area[0].areaName[0].value' "$CACHE_FILE")

  case "${condition,,}" in
  *sunny* | *clear*) icon="☀️" ;;
  *partly*cloudy*) icon="⛅" ;;
  *cloudy* | *overcast*) icon="☁️" ;;
  *mist* | *fog* | *haze*) icon="🌫️" ;;
  *drizzle* | *light*rain*) icon="🌦️" ;;
  *heavy*rain* | *patchy*rain* | *rain*) icon="🌧️" ;;
  *thunderstorm* | *thundery*) icon="⛈️" ;;
  *snow* | *sleet* | *ice*) icon="❄️" ;;
  *) icon="✨" ;;
  esac

  echo "{\"text\": \"$icon ${temp}°C\", \"tooltip\": \"Weather in ${city}\\n\\n${condition}\\nDaily high: ${max_temp}°C\\nDaily low: ${min_temp}°C\\nHumidity: ${humidity}%\"}"
else
  echo "{\"text\": \"⚠️ N/A\", \"tooltip\": \"Weather data unavailable\"}"
fi
