#!/usr/bin/env bash

# Terminate already running bar instances
killall -q waybar

# Wait until the waybar processes have been shut down
while pgrep -x waybar >/dev/null; do sleep 1; done

# Launch Waybar
waybar &
