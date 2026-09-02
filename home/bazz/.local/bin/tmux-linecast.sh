#!/usr/bin/env bash

SESSION="linecast"

if tmux has-session -t "$SESSION" 2>/dev/null; then
  tmux attach-session -t "$SESSION"
  exit 0
fi

tmux new-session -d -s "$SESSION" "linecast weather"
tmux split-window -h -t "$SESSION" "linecast moon"
tmux split-window -v -t "$SESSION" "linecast sunshine"
tmux attach-session -t "$SESSION"
