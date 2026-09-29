#!/usr/bin/env bash

APPS=(brave-origin thunderbird transmission-gtk)

DMENU="fuzzel -d -a top --y 8 -w 18 --minimal-lines"

choice=$(printf "Yes\nNo" | $DMENU --prompt="Open Daily Apps? 🤔 ")

[[ "$choice" == "Yes" ]] || exit 0

for app in "${APPS[@]}"; do
  "$app" &
done
