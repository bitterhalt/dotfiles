#!/usr/bin/env bash

# Show welcome popup only if Waybar is NOT running

if ! pgrep -x "waybar" >/dev/null; then
  user=$(whoami)
  day=$(date '+%A, %d %B')
  clock=$(date '+%H:%M')

  body=$(printf "%s\n%s\n\n%s" \
    "Today is, $day" \
    "$clock" \
    "Tip: ⭐ press SUPER+B to enable bar")

  notify-send -t 15000 "Welcome back $user ❤️" "\n$body"
fi
