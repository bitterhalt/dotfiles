#!/usr/bin/env bash

if pgrep -x "ignis" >/dev/null; then
  pkill ignis
  sleep 1
  ignis init >~/.local/state/ignis.log 2>&1 &
else
  ignis init >~/.local/state/ignis.log 2>&1 &
fi
