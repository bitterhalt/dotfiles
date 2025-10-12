#!/usr/bin/env bash

# Sleep to make sure all start correct order
wait="sleep 0.2"

# Launch some monitor stuff in worksspace 1
# Make sure that class "syspace" rule is addet in Hyprland rules

foot -a syspace -T journalctl -e journalctl -f &
$wait
foot -a syspace -T htop -e htop &
$wait
foot -a syspace -T atop -e amdgpu_top --smi &
