#!/usr/bin/env bash

if [[ "$1" == "-t" ]]; then
  qs ipc call idle toggle >/dev/null
  exit
fi

if [[ "$(qs ipc call idle isDisabled 2>/dev/null)" != "true" ]]; then
  echo ""
else
  echo "{\"text\": \"󱐋\", \"tooltip\": \"Idle timers are disabled\", \"class\": \"disabled\"}"
fi
