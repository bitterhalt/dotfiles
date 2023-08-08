#!/bin/sh
# DWM autostart script

# Processes to check
processes=( "dwmblocks" "picom" "/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1" )
# locker
locker="$HOME/.local/bin/locker-toggler"

# Iterate over the processes and check if they are already running
for process in "${processes[@]}"; do
    if ! pgrep -x "$process" > /dev/null; then
        "$process" &
    fi
done

sleep 2 && setbg &
~/.config/.screenlayout/monitor.sh &
sleep 3 && $locker -e &
#xset s 3600 dpms 3600 3600 3600 &
xclip &



