#!/bin/bash

~/.config/.screenlayout/monitor.sh &
nitrogen --restore &
xset s 3600 dpms 3600 3600 3600


autostart="xclip dwmblocks picom corectrl /usr/lib/polkit-gnome-authentication-agent-1"

for program in $autostart; do
	pidof -sx "$program" || "$program" &
done >/dev/null 2>&1
