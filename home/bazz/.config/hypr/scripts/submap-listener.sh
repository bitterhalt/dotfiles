#!/usr/bin/env bash
# Hyprland submap listener uses fnnot and socat

STATUS="/tmp/submap_notify_active"
SOCKET="$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock"

notify_submap() {
  submap="$(hyprctl submap)"
  if [[ -z "$submap" || "$submap" == "default" ]]; then
    if [[ -f "$STATUS" ]]; then
      fnottctl dismiss
      rm -f "$STATUS"
    fi
    return
  fi

  notify-send "$submap"
  touch "$STATUS"
}

listen_socket() {
  while true; do
    if [[ -S "$SOCKET" ]]; then
      socat -U - UNIX-CONNECT:"$SOCKET" | while read -r line; do
        case "$line" in
        submap*) notify_submap "$line" ;;
        esac
      done
    else
      echo "Waiting for Hyprland socket..."
      sleep 2
    fi
    echo "Socket disconnected, retrying..."
    sleep 1
  done
}

listen_socket
