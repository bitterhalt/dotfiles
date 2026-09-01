#!/usr/bin/env bash

if pgrep -x "swayidle" >/dev/null; then
  echo ""
else
  echo "{\"text\": \"󱐋\", \"tooltip\": \"<b>Idle daemon is disabled</b>\"}"
fi
