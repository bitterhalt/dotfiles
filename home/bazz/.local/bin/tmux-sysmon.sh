#!/usr/bin/env bash

SESSION="system"
TOP="btop"
GTOP="amdgpu_top --smi"

if tmux has-session -t "$SESSION" 2>/dev/null; then
  exec tmux attach-session -t "$SESSION"
fi

tmux new-session -d -s "$SESSION" -n logs "journalctl -f"
tmux new-window -t "$SESSION" -n monitor "$GTOP"
tmux split-window -v -t "$SESSION:monitor" "$TOP"

tmux attach-session -t "$SESSION"
