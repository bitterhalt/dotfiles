#!/usr/bin/env bash

IDLE_DAEMON="hypridle"
if pgrep -x "niri" >/dev/null; then
  IDLE_DAEMON="swayidle"
fi

start_idle_daemon() {
  $IDLE_DAEMON &
  notify-send "Idle timer" "Enabled" -t 1500 -h string:x-canonical-private-synchronous:volume
}

stop_idle_daemon() {
  pkill -x $IDLE_DAEMON
  notify-send "Idle timer" "Disabled" -t 1500 -h string:x-canonical-private-synchronous:volume
}

if [ "$1" = "-t" ]; then
  if pgrep -x $IDLE_DAEMON >/dev/null; then
    stop_idle_daemon
  else
    start_idle_daemon
  fi
  exit 0
fi

if ! pgrep -x $IDLE_DAEMON >/dev/null; then
  start_idle_daemon
fi
