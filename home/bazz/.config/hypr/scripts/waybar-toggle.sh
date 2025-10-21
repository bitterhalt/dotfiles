#!/usr/bin/env bash
set -e

# This script toggles Waybar on/off in Hyprland
#
#  • When disabling Waybar:
#      - Kills existing Waybar.
#      - Starts a background listener that sends notifications when workspaces changes
#
#  • When enabling Waybar:
#      - Restarts Waybar
#      - Stops the listener (and its socat subprocess)
#
#  Requires: socat, jq, notify-send

CFG="$HOME/.config/hypr/waybar"
SOCKET_PATH="/run/user/$UID/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock"
PIDFILE="/tmp/workspace-listener.pid"

# Listener

start_listener() {
  if [ ! -S "$SOCKET_PATH" ]; then
    notify-send "Hyprland" "Error: cannot find socket2 at expected location."
    exit 1
  fi

  setsid bash -c "
    socat -u UNIX-CONNECT:'$SOCKET_PATH' - |
      while read -r line; do
        if [[ \$line == *'workspace>>'* ]]; then
          workspace=\$(hyprctl activeworkspace -j | jq -r '.name // .id')
          notify-send -t 1500 -h string:x-canonical-private-synchronous:notification \"󰍹 Workspace: \$workspace\"
        fi
      done
  " &

  echo $! >"$PIDFILE"
}

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

# Toggle Waybar and manage listener

if pgrep -x waybar >/dev/null; then
  # Waybar is running → disable it and start listener
  killall -q waybar
  start_listener
else
  # Waybar is not running → enable it and stop listener
  stop_listener
  waybar -c "$CFG/config.jsonc" -s "$CFG/style.css" &
fi
