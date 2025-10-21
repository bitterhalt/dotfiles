#!/usr/bin/env bash
set -e

# This script toggles Waybar on/off in Hyprland
#
#  • When disabling Waybar:
#      - Kills existing Waybar.
#      - Starts a background listener that sends notifications when workspace changes.
#
#  • When enabling Waybar:
#      - Restarts Waybar.
#      - Stops the listener (and its socat subprocess).

CFG="$HOME/.config/hypr/waybar"
LISTENER="$HOME/.config/hypr/scripts/workspace-listener.sh"
PIDFILE="/tmp/workspace-listener.pid"

# Kill the entire process group (listener + socat)
stop_listener() {
  if [ -f "$PIDFILE" ]; then
    PID=$(cat "$PIDFILE")
    if kill -0 "$PID" 2>/dev/null; then
      PGID=$(ps -o pgid= "$PID" | tr -d ' ')
      kill -TERM -"$PGID" 2>/dev/null || true
    fi
    rm -f "$PIDFILE"
  fi
}

if pgrep -x waybar >/dev/null; then
  killall -q waybar
  sleep 0.3
  "$LISTENER"
else
  stop_listener
  waybar -c "$CFG/config.jsonc" -s "$CFG/style.css" &
fi
