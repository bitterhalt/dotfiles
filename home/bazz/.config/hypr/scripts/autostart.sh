#!/usr/bin/env bash

hypridle &
waybar -c ~/.config/hypr/waybar/config.jsonc -s ~/.config/hypr/waybar/style.css &
foot --server &
swww-daemon &
wl-paste --type text --watch cliphist store &
wl-paste --type image --watch cliphist store &
/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1 &
~/.config/hypr/scripts/submap-listener.sh &
(sleep 6 && transmission-gtk) &
