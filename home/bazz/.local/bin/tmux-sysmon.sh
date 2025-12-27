#!/usr/bin/env bash

SESSION="system"

# If session already exists, just attach to it
if tmux has-session -t "$SESSION" 2>/dev/null; then
  notify-send -t 5000 "TMUX" "Re-attaching to existing session: $SESSION"
  exec tmux attach-session -t "$SESSION"
fi

tmux new-session -d -s "$SESSION" -n logs "journalctl -f"
tmux split-window -h -t "$SESSION:" tail -f ~/.local/state/ignis/ignis.log
tmux new-window -t "$SESSION" -n monitor "amdgpu_top --smi"
tmux split-window -h -t "$SESSION:monitor" "htop"

notify-send -t 5000 "TMUX" "Session ready"

exec tmux attach-session -t "$SESSION"
