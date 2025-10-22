#!/usr/bin/env bash

wait="sleep 0.2"

pgrep -af "foot -a syspace -T journalctl" >/dev/null || foot -a syspace -T journalctl -e journalctl -f &
$wait
pgrep -af "foot -a syspace -T htop" >/dev/null || foot -a syspace -T htop -e htop &
$wait
pgrep -af "foot -a syspace -T atop" >/dev/null || foot -a syspace -T atop -e amdgpu_top --smi &
