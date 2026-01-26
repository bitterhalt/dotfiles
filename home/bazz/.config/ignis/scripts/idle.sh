#!/usr/bin/env bash

PID_FILE="$HOME/.cache/hypridle.pid"

start_hypridle() {
  hypridle &
  echo $! >"$PID_FILE"
}

stop_hypridle() {
  pkill hypridle
  rm -f "$PID_FILE"
  notify-send -i caffeine "Idle timer" "Disabled" -t 1500 -h string:x-canonical-private-synchronous:volume
}

if [ "$1" = "-t" ]; then
  if pgrep hypridle >/dev/null; then
    stop_hypridle
  else
    start_hypridle
  fi
  exit 0
fi

if ! pgrep hypridle >/dev/null; then
  start_hypridle
fi
