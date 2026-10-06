#!/usr/bin/env bash

APPS=(brave-origin thunderbird transmission-gtk)

DMENU="${DMENU:-vicinae dmenu}"

choice=$(printf "Yes\nNo" | $DMENU --placeholder="Open Communications? 🤔 ")

[[ "$choice" == "Yes" ]] || exit 0

for app in "${APPS[@]}"; do
  "$app" &
done
