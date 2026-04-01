#!/usr/bin/env bash

PID_FILE="$HOME/.cache/hypridle.pid"

start_hypridle() {
  hypridle &
  echo $! >"$PID_FILE"
}

stop_hypridle() {
  pkill -x hypridle
  rm -f "$PID_FILE"
  notify-send -t 1500 -i caffeine "Idle timer" "Disabled"
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
