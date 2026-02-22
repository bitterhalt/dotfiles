#!/usr/bin/env bash

SESSION="system"
TOP="btop"
GTOP="amdgpu_top --smi"

if tmux has-session -t "$SESSION" 2>/dev/null; then
  exec tmux attach-session -t "$SESSION"
fi

tmux new-session -d -s "$SESSION" -n logs "journalctl -f"
tmux split-window -h -t "$SESSION:" tail -f ~/.local/state/ignis/ignis.log
tmux new-window -t "$SESSION" -n monitor "$GTOP"
tmux split-window -h -t "$SESSION:monitor" "$TOP"

exec tmux attach-session -t "$SESSION"
