#!/usr/bin/env bash

CACHE_DIR="$HOME/.cache"
CACHE_FILE="$CACHE_DIR/waybar_weather.json"
CACHE_TIMEOUT=7200
LOCATION=""

mkdir -p "$CACHE_DIR"

fetch_weather() {
  if response=$(curl -sf "https://wttr.in/${LOCATION}?format=j1"); then
    if echo "$response" | jq empty >/dev/null 2>&1; then
      echo "$response" >"$CACHE_FILE"
      return 0
    fi
  fi
  return 1
}

if [ ! -f "$CACHE_FILE" ] || [ ! -s "$CACHE_FILE" ]; then
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

  echo "{\"text\": \"$icon ${temp}°C\", \"tooltip\": \"Weather in ${city}\\n\\n${condition}\\n\\n<b>High:</b> ${max_temp}°C\\n<b>Low:</b> ${min_temp}°C\\n<b>Humidity:</b> ${humidity}%\"}"
else
  echo "{\"text\": \"⚠️ N/A\", \"tooltip\": \"Weather data unavailable\"}"
fi
