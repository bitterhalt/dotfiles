#!/usr/bin/env bash

if pgrep -x "hypridle" >/dev/null; then
  echo ""
else
  echo "{\"text\": \"󰒳\", \"tooltip\": \"<b>Hypridle is disabled</b>\n click left or press  + Shift + F11 to enable\"}"
fi
