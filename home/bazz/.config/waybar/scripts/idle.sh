#!/usr/bin/env bash

if pgrep -x "swayidle" >/dev/null; then
  echo "{\"text\": \"󰤄\", \"tooltip\": \"Idle daemon is enabled\", \"class\": \"enabled\"}"
else
  echo "{\"text\": \"󱐋\", \"tooltip\": \"Idle daemon is disabled\", \"class\": \"disabled\"}"
fi
