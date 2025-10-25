#!/usr/bin/env bash

wait="sleep 0.2"

foot -a syspace -T htop -e htop &
$wait
foot -a syspace -T atop -e amdgpu_top --smi &
$wait
foot -a syspace -T journalctl -e journalctl -f &
