#!/usr/bin/env bash

if pgrep waybar >/dev/null; then
  pkill waybar
else
  waybar &
fi
