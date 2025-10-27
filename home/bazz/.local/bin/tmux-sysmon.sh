#!/usr/bin/env bash

SESSION="system"

# If session already exists, just attach to it
if tmux has-session -t "$SESSION" 2>/dev/null; then
  exec tmux attach-session -t "$SESSION"
fi

# Create session with journalctl in the first window
tmux new-session -d -s "$SESSION" -n logs "journalctl -f"

# Create second window for GPU + system monitoring
tmux new-window -t "$SESSION" -n monitor "amdgpu_top --smi"
tmux split-window -h -t "$SESSION:monitor" "htop"

# Attach session
exec tmux attach-session -t "$SESSION"
