#!/usr/bin/env bash

icons="$HOME/.local/share/icons/feather/"

if pgrep swayidle >/dev/null; then
  pkill swayidle
  notify-send -i "$icons"/eye.svg "Swayidle" "Disabled" -t 1500 -h string:x-canonical-private-synchronous:volume
else
  notify-send -i "$icons"/eye-off.svg "Swayidle" "Enabled" -t 1500 -h string:x-canonical-private-synchronous:volume
  swayidle -w &
fi
