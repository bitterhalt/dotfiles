#!/usr/bin/env bash

DMENU="fuzzel_screenshot"
SHELLMENU="goignis toggle-window ignis_RECORDING_OVERLAY"

if pgrep -x ignis >/dev/null; then
  $SHELLMENU
else
  $DMENU
fi
