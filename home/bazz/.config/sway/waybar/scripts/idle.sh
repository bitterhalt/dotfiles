#!/usr/bin/env bash

if pgrep -x "swayidle" >/dev/null; then
  echo "{\"text\": \"󰤄\", \"tooltip\": \"<b>swayidle is enabled</b>\n click left or press  + Shift + F11 to disable\", \"class\": \"enabled\"}"
else
  echo "{\"text\": \"󰠠\", \"tooltip\": \"<b>swayidle is disabled</b>\n click left or press  + Shift + F11 to enable\", \"class\": \"disabled\"}"
fi
