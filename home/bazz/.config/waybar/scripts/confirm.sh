#!/usr/bin/env bash

set -euo pipefail

ACTION="$1"
FLAGS="-d -a top --y 24 -w 20 --minimal-lines"

confirm_action() {
  local action_name="$1"
  local selection
  selection=$(echo -e "n ➜ No, Cancel\ny ➜ Yes, ${action_name}" | fuzzel $FLAGS)
  if [[ "$selection" == *"Yes"* ]]; then
    return 0
  fi
  return 1
}

case "$ACTION" in
"shutdown")
  confirm_action "Shutdown" && systemctl poweroff
  ;;
"reboot")
  confirm_action "Reboot" && systemctl reboot
  ;;
"exit")
  confirm_action "Exit" && niri msg action quit
  ;;
*)
  exit 1
  ;;
esac
