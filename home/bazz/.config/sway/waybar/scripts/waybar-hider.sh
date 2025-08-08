#!/usr/bin/env bash

# Terminate already running Waybar instances
if pgrep -x waybar >/dev/null; then
  killall -q waybar
  # Send notication
  notify-send -t 2000 -a System -i ~/.local/share/icons/feather/x.svg "Waybar" "disabled" -h string:x-canonical-private-synchronous:volume
else
  # Launch Waybar
  waybar -c ~/.config/sway/waybar/config.jsonc -s ~/.config/sway/waybar/style.css &
fi
