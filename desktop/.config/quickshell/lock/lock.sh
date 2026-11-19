#!/usr/bin/env bash
set -eu

config="$HOME/.config/quickshell/lock.qml"
qs -n -d -p "$config" --no-detailed-logs

# Like swaylock -f, return once the compositor confirms the lock, not merely
# once the application starts. There is no fallback or fixed waiting period.
while true; do
  secure=$(qs ipc -p "$config" call locker isSecure) || exit 1
  [[ "$secure" == "true" ]] && exit 0
  sleep 0.05
done
