#!/bin/bash

set -euo pipefail

# Get the brightness percentage:
MAX_BRIGHTNESS=$(cat /sys/class/backlight/intel_backlight/max_brightness)
BRIGHTNESS=$(cat /sys/class/backlight/intel_backlight/actual_brightness)
PCT=$(echo $BRIGHTNESS $MAX_BRIGHTNESS | awk '{printf "%4.0f\n",($1/$2)*100}' | tr -d '[:space:]')

# Round the brightness percentage:
LC_ALL=C

case "${1:-}" in
up)
  brightnessctl set 5%+
  ;;
down)
  brightnessctl set 5%-
  ;;
esac

notify-send -t 1500 "󰃞 ${PCT}%" \
  -a System \
  -h string:x-dunst-stack-tag:volume
