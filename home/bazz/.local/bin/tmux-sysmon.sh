#!/usr/bin/env bash

SESSION="system"

# If session already exists, notify and exit
if tmux has-session -t "$SESSION" 2>/dev/null; then
  notify-send "System Monitor" "Session exists. Run: tmux attach -t $SESSION"
  exit 0
fi

# Create tmux session only if it doesn't exist
tmux new-session -d -s "$SESSION" -n system "journalctl -f"
tmux split-window -h -t "$SESSION" "amdgpu_top --smi"
tmux split-window -v -t "$SESSION" "htop"

# Attach session
exec tmux attach-session -t "$SESSION"
