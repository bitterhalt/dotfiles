#!/usr/bin/env bash
#
# Hyprland submap listener for Ignis overlay
# Uses socat for reliable socket handling
#
PIDFILE="/tmp/submap_watcher.pid"
SOCKET="$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock"

if [[ ! -S "$SOCKET" ]]; then
  echo "[Watcher] ERROR: Hyprland socket not found at $SOCKET" >&2
  exit 1
fi

# Only one instance
if [[ -e "$PIDFILE" ]] && kill -0 "$(cat "$PIDFILE")" 2>/dev/null; then
  echo "[Watcher] Already running (PID $(cat "$PIDFILE"))"
  exit 0
fi

echo $$ >"$PIDFILE"
trap 'rm -f "$PIDFILE"; echo "[Watcher] Stopped."; exit 0' EXIT SIGTERM SIGINT

echo "[Watcher] Started (pid $$)"
echo "[Watcher] Connected to $SOCKET"

# Trigger Ignis overlay
show_overlay() {
  local submap="$1"

  if [[ -z "$submap" || "$submap" == "reset" ]]; then
    ignis run-command submap-hide &>/dev/null
  else
    ignis run-command submap-show "$submap" &>/dev/null
  fi
}

# Listen to socket events
socat -U - UNIX-CONNECT:"$SOCKET" | while read -r line; do
  case "$line" in
  submap\>\>*)
    submap="${line#submap>>}"
    echo "[Watcher] Submap: ${submap:-reset}"
    show_overlay "$submap"
    ;;
  esac
done
