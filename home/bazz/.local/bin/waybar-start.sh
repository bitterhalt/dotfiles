#!/usr/bin/env bash

# Kill already running Waybar instances
if pgrep -x "waybar" >/dev/null; then
  pkill waybar
  sleep 0.2
fi

# Detect current Wayland WM / compositor
wm=$(echo "$XDG_CURRENT_DESKTOP$WAYLAND_DISPLAY$DESKTOP_SESSION" | tr '[:upper:]' '[:lower:]')

if [[ $wm == *"hyprland"* ]]; then
  echo "Starting Waybar for Hyprland..."
  waybar -c ~/.config/hypr/waybar/config.jsonc -s ~/.config/hypr/waybar/style.css &

elif [[ $wm == *"sway"* ]]; then
  echo "Starting Waybar for Sway..."
  waybar -c ~/.config/sway/waybar/config.jsonc -s ~/.config/sway/waybar/style.css &

else
  echo "Could not detect Hyprland or Sway."
  echo "Starting Waybar with default config..."
  waybar &
fi
