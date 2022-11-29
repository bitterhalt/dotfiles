#!/usr/bin/env bash

dir="$HOME/.config/rofi/powermenu"
theme='powermenu4'

uptime="`uptime -p | sed -e 's/up //g'`"

shutdown='  Shutdown'
reboot='  Reboot'
lock='  Lock'
suspend='  Suspend'
logout='  Logout'
yes='  Yes'
no='  No'

# Rofi CMD
rofi_cmd() {
	rofi -dmenu \
		-mesg "Uptime: $uptime" \
		-theme ${dir}/${theme}.rasi
}

run_rofi() {
	echo -e "$lock\n$suspend\n$logout\n$reboot\n$shutdown" | rofi_cmd
}

# Actions
chosen="$(run_rofi)"

if [[ "$chosen" == "$lock" ]]; then
  ~/.config/i3/scripts/i3lock-color
elif
   [[ "$chosen" == "$suspend" ]]; then
   systemctl suspend
 elif
   [[ "$chosen" == "$logout" ]]; then
   i3-msg exit
 elif
   [[ "$chosen" == "$reboot" ]]; then
   systemctl reboot
 elif
   [[ "$chosen" == "$shutdown" ]]; then
   systemctl poweroff
fi
