#!/usr/bin/env bash

icons="$HOME/.local/share/icons/feather/"

if pgrep hypridle >/dev/null; then
  pkill hypridle
  notify-send -i "$icons"/eye.svg "Hypridle" "Disabled" -t 1500 -h string:x-canonical-private-synchronous:volume
else
  notify-send -i "$icons"/eye-off.svg "Hypridle" "Enabled" -t 1500 -h string:x-canonical-private-synchronous:volume
  hypridle &
fi
