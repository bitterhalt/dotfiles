#!/usr/bin/env bash

foot -a syspace -T journalctl -e journalctl -f &
sleep 0.2
foot -a syspace -T htop -e htop &
sleep 0.2
foot -a syspace -T atop -e amdgpu_top --smi &
