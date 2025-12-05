#!/usr/bin/env bash
set -euo pipefail

# List processes (PID + CMD)
processes=$(ps -u "$USER" -o pid=,comm=)

# If no processes, exit gracefully
[[ -z "$processes" ]] && exit 0

# Select a process
selection=$(
  printf "%s\n" "$processes" |
    fzf --border-label="Kill process > " \
      --with-nth=2.. \
      --layout=reverse \
      --border=rounded \
      --preview='echo PID: $(echo {} | awk "{print \$1}") ; echo CMD: $(echo {} | cut -d" " -f2-) ' \
      --preview-window=down:3:wrap
)

[[ -z "${selection:-}" ]] && exit 0

pid=$(echo "$selection" | awk '{print $1}')
cmd=$(echo "$selection" | cut -d" " -f2-)

# Confirmation
confirm=$(printf "No\nYes" |
  fzf --prompt="Kill $cmd (PID $pid)? > " \
    --height=10 --border=rounded --layout=reverse)

[[ "$confirm" != "Yes" ]] && exit 0

# Kill
kill -9 "$pid" 2>/dev/null

notify-send "Process killed" "$cmd (PID $pid)"
