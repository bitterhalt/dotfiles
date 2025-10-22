#!/usr/bin/env bash
# Hyprland submap listener for fnott + notify-send (clean output)

PIDFILE="/tmp/submap_listener.pid"
SOCKET="$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock"
STATUS="/tmp/submap_notify_active"

if [[ ! -S "$SOCKET" ]]; then
  echo "Error: Hyprland socket not found at $SOCKET" >&2
  exit 1
fi

# Only one instance
if [[ -e "$PIDFILE" ]] && kill -0 "$(cat "$PIDFILE")" 2>/dev/null; then
  echo "Already running (PID $(cat "$PIDFILE"))"
  exit 0
fi
echo $$ >"$PIDFILE"
trap 'rm -f "$PIDFILE"' EXIT

notify_submap() {
  submap="$(hyprctl submap)"
  if [[ -z "$submap" || "$submap" == "default" ]]; then
    if [[ -f "$STATUS" ]]; then
      fnottctl dismiss all
      rm -f "$STATUS"
    fi
    return
  fi

  notify-send "Submap" "$submap"
  touch "$STATUS"
}

socat -U - UNIX-CONNECT:"$SOCKET" | while read -r line; do
  case "$line" in
  submap*) notify_submap ;;
  esac
done
