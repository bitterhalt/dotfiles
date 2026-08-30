#!/usr/bin/env bash

DMENU="fuzzel -d -a top --y 8 -w 24 --minimal-lines"

choice=$(printf "Yes\nNo" | $DMENU --prompt="Launch daily applications? ")

[[ "$choice" == "Yes" ]] || exit 0

brave-origin &
thunderbird &
transmission-gtk &
