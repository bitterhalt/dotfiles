#!/usr/bin/env bash

if pgrep hypridle >/dev/null; then
  pkill hypridle
  notify-send -i ~/.local/share/icons/feather/eye.svg "Hypridle" "Disabled" -t 1500 -h string:x-canonical-private-synchronous:volume
else
  notify-send -i ~/.local/share/icons/feather/eye-off.svg "Hypridle" "Enabled" -t 1500 -h string:x-canonical-private-synchronous:volume
  hypridle &
fi
