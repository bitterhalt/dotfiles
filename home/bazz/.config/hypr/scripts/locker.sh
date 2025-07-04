#!/usr/bin/env bash
# Times the screen off and puts it to background
swayidle \
  timeout 120 "hyprctl dispatch dpms off" \
  resume "hyprctl dispatch dpms on" &
# Locks the screen immediately
swaylock
# Kills last background task so idle timer doesn't keep running
kill %%
