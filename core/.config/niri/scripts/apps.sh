#!/usr/bin/env bash

APPS=(brave-origin thunderbird transmission-gtk)

is_running() {
  local app="$1"
  local process_name="$app"

  # Brave is launched through a wrapper but its main process is named "brave".
  [[ "$app" == "brave-origin" ]] && process_name="brave"

  pgrep -x "$process_name" >/dev/null
}

for app in "${APPS[@]}"; do
  is_running "$app" && continue
  command -v "$app" >/dev/null 2>&1 || continue

  "$app" >/dev/null 2>&1 &
done
