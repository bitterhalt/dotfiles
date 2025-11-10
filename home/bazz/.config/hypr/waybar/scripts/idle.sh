#!/usr/bin/env bash

if pgrep -x "hypridle" >/dev/null; then
  echo "{\"text\": \"󰤄\", \"tooltip\": \"<b>Hypridle is enabled</b>\n\nClick right to disable\nClick left to Power-menu\",\"class\": \"enabled\"}"
else
  echo "{\"text\": \"󰠠\", \"tooltip\": \"<b>Hypridle is disable</b>\n\nClick right to enable\nClick left to Power-menu\", \"class\": \"disabled\"}"
fi
