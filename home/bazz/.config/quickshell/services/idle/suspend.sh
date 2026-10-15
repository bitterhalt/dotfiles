#!/usr/bin/env bash
# QuickShell has no logind before-sleep hook, so lock the session here first.
# lock.sh returns only once the compositor confirms the lock is secure.
set -eu

bash "$HOME/.config/quickshell/lock/lock.sh"
# Give the compositor a moment to present the lock before the system sleeps.
sleep 1
exec systemctl suspend
