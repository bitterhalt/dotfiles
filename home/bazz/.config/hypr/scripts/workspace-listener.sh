#!/usr/bin/env bash

# Script starts a background listener that sends notifications when workspaces change
# Requires: socat, jq, notify-send

PIDFILE="/tmp/workspace-listener.pid"
SOCKET_PATH="/run/user/$UID/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock"

if [ ! -S "$SOCKET_PATH" ]; then
  notify-send "Hyprland" "Error: cannot find socket2 at expected location."
  exit 1
fi

# Starts listener in its own process group
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
