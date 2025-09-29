#!/usr/bin/env bash

locker="hyprlock"
icons="$HOME/.local/share/icons/feather/"

toggle() {
  if pgrep swayidle >/dev/null; then
    pkill swayidle
    notify-send -i "$icons"/eye.svg "Swayidle" "Disabled" -t 1500 -h string:x-canonical-private-synchronous:volume
  else
    notify-send -i "$icons"/eye-off.svg "Swayidle" "Enabled" -t 1500 -h string:x-canonical-private-synchronous:volume
    swayidle -w \
      timeout 1700 "pidof $locker >/dev/null || $locker" &
    timeout 1800 "swaymsg 'output * power off'" resume "swaymsg 'output * power on'" \
      before-sleep "$locker" &
  fi
}

start() {
  swayidle -w \
    timeout 1700 "pidof $locker >/dev/null || $locker" &
  timeout 1800 "swaymsg 'output * power off'" resume "swaymsg 'output * power on'" \
    before-sleep "$locker" &
}

case "$1" in
"--toggle")
  toggle
  ;;
*)
  start
  ;;
esac
