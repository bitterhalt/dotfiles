#!/usr/bin/env bash

if pgrep swayidle >/dev/null; then
  pkill swayidle
  notify-send -i ~/.local/share/icons/feather/eye.svg "Swayidle" "Disabled" -t 1500 -h string:x-canonical-private-synchronous:volume
else
  notify-send -i ~/.local/share/icons/feather/eye-off.svg "Swayidle" "Enabled" -t 1500 -h string:x-canonical-private-synchronous:volume
  swayidle -w &
fi
