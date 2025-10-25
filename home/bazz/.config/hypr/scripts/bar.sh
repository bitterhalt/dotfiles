#!/usr/bin/env bash

CFG="$HOME/.config/hypr/waybar"
LISTENER="$HOME/.config/hypr/scripts/workspace-listener.sh"
PIDFILE="/tmp/workspace-listener.pid"

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

case "$1" in
less)
  stop_listener
  "$LISTENER" &
  ;;
toggle)
  if pgrep -x waybar >/dev/null; then
    killall -q waybar && sleep 0.3
    "$LISTENER" &
  else
    stop_listener
    waybar -c "$CFG/config.jsonc" -s "$CFG/style.css" &
  fi
  ;;
*)
  stop_listener
  waybar -c "$CFG/config.jsonc" -s "$CFG/style.css" &
  ;;
esac
