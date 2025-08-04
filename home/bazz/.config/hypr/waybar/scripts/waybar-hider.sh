#!/usr/bin/env bash

# Terminate already running Waybar instances
if pgrep -x waybar >/dev/null; then
  killall -q waybar
  # Send notication
  notify-send -t 2000 -a System -i ~/.local/share/icons/feather/x.svg "Waybar" "disabled" -h string:x-canonical-private-synchronous:volume
else
  # Launch Waybar
  waybar -c ~/.config/hypr/waybar/config-hypr.jsonc -s ~/.config/hypr/waybar/style-hypr.css
fi
