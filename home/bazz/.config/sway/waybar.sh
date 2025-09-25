#!/usr/bin/env bash

set -e
CFG="$HOME/.config/sway/waybar"

start() {
  if ! pgrep -x waybar >/dev/null; then
    waybar -c "$CFG/config.jsonc" -s "$CFG/style.css" &
  fi
}

toggle() {
  if pgrep -x waybar >/dev/null; then
    killall -q waybar
    notify-send -t 2000 -a System \
      -i ~/.local/share/icons/feather/x.svg \
      "Waybar" "disabled" \
      -h string:x-canonical-private-synchronous:volume
  else
    waybar -c "$CFG/config.jsonc" -s "$CFG/style.css" &
  fi
}

case "$1" in
start) start ;;
toggle) toggle ;;
*)
  echo "Usage: $0 {start|toggle}" >&2
  exit 1
  ;;
esac
