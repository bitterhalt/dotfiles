#!/usr/bin/env bash

if pgrep -x "hypridle" >/dev/null; then
  echo "{\"text\": \"󰤄\", \"tooltip\": \"<b>Hypridle is enabled</b>\nClick left to disable\nClick right to Power-menu\",\"class\": \"enabled\"}"
else
  echo "{\"text\": \"󰠠\", \"tooltip\": \"<b>Hypridle is disable</b>\nClick left to enable\nClick right to Power-menu\", \"class\": \"disabled\"}"
fi
