#!/usr/bin/env bash

PID_FILE="$HOME/.cache/hypridle.pid"

start_hypridle() {
  hypridle &
  echo $! >"$PID_FILE"
}

stop_hypridle() {
  pkill hypridle
  rm -f "$PID_FILE"
  notify-send -i caffeine "Hypridle" "Disabled" -t 1500 -h string:x-canonical-private-synchronous:volume
}

if [ "$1" = "start" ]; then
  if ! pgrep hypridle >/dev/null; then
    start_hypridle
  else
    if [ ! -f "$PID_FILE" ]; then
      pgrep hypridle >"$PID_FILE"
    fi
  fi
  exit 0
fi

if pgrep hypridle >/dev/null; then
  stop_hypridle
else
  start_hypridle
fi
