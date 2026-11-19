#!/usr/bin/env bash

if pgrep -x qs >/dev/null; then
  qs ipc call bar toggle
elif pgrep -x waybar >/dev/null; then
  pkill -x waybar
else
  waybar &
fi
