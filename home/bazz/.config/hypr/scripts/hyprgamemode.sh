#!/usr/bin/env bash

HYPRGAMEMODE=$(hyprctl getoption animations:enabled | awk 'NR==1{print $2}')

if [ "$HYPRGAMEMODE" = 1 ]; then
  hyprctl --batch "\
        keyword animations:enabled 0;\
        keyword decoration:shadow:enabled 0;\
        keyword decoration:blur:enabled 0; \
        keyword decoration:rounding 0"
  notify-send -t 5000 "Hyprland" "Fancy stuff disabled"
  exit
else
  hyprctl reload
  notify-send -t 5000 "Hyprland" "Fancy stuff enabled"
fi
