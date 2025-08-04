#!/usr/bin/env bash

if pgrep -x "swayidle" >/dev/null; then
  echo ""
else
  echo "{\"text\": \"󰒳\", \"tooltip\": \"<b>Idle timer is disabled</b>\n click left or press  +Control+F11 to enable\"}"
fi
