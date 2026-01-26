#!/usr/bin/env bash

if pgrep -x ignis >/dev/null; then
  goignis toggle-window ignis_RECORDING_OVERLAY
else
  fuzzel_screenshot
fi
