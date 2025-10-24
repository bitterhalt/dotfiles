#!/usr/bin/env bash

# Script starts a background listener that sends notifications when workspaces change
# Requires: socat, jq, notify-send

PIDFILE="/tmp/workspace-listener.pid"
SOCKET_PATH="/run/user/$UID/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock"

# Run only without Waybar
if pgrep -x "waybar" >/dev/null; then
  echo "Waybar is running — workspace listener will not start."
  exit 0
fi
# Check if socket exists
if [ ! -S "$SOCKET_PATH" ]; then
  notify-send "Hyprland" "Error: cannot find socket2 at expected location."
  exit 1
fi

# Check for existing running instance
if [ -f "$PIDFILE" ]; then
  old_pid=$(cat "$PIDFILE")
  if ps -p "$old_pid" -o comm= | grep -q "bash"; then
    echo "Listener already running (PID: $old_pid)"
    exit 0
  else
    echo "Removing stale PID file."
    rm -f "$PIDFILE"
  fi
fi

# Start listener in background
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
