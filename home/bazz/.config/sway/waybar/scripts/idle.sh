#!/usr/bin/env bash

if pgrep -x "swayidle" >/dev/null; then
  echo "{\"text\": \"󰤄\", \"tooltip\": \"<b>Swayidle is enabled</b>\n click left or press  + Shift + F11 to disable\"}"
else
  echo "{\"text\": \"󰠠\", \"tooltip\": \"<b>Swayidle is disabled</b>\n click left or press  + Shift + F11 to enable\"}"
fi
