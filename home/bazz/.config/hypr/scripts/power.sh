#!/usr/bin/env bash

if pgrep -x ignis >/dev/null; then
  goignis toggle-window ignis_POWER_OVERLAY
else
  fuzzel_power
fi
