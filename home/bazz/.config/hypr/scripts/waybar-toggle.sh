#!/usr/bin/env bash
set -e

CFG="$HOME/.config/hypr/waybar"

if pgrep -x waybar >/dev/null; then
  killall -q waybar
  notify-send -t 2000 -a System \
    -i ~/.local/share/icons/feather/x.svg \
    "Waybar" "disabled" \
    -h string:x-canonical-private-synchronous:volume
else
  waybar -c "$CFG/config.jsonc" -s "$CFG/style.css" &
fi
