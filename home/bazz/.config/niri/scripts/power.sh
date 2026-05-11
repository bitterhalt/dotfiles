#!/usr/bin/env bash

DMENU="wlr-which-key power"
SHELLMENU="goignis toggle-window ignis_POWER_OVERLAY"

if pgrep -x ignis >/dev/null; then
  $SHELLMENU
else
  $DMENU
fi
