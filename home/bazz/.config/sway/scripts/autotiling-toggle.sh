#!/usr/bin/env bash

if pgrep autotiling >/dev/null; then
  pkill autotiling
  notify-send -i ~/.local/share/icons/feather/check.svg "Autotiling" "Disabled" -t 1500 -h string:x-canonical-private-synchronous:volume
else
  autotiling &
  notify-send -i ~/.local/share/icons/feather/x.svg "Autotiling" "Enabled" -t 1500 -h string:x-canonical-private-synchronous:volume
fi
