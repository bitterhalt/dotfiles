#!/usr/bin/env bash

grep 'bind =' ~/.config/hypr/hyprland.conf | grep -v '^\s*#' | sed 's/^bind = //; s/, */ /g; s/\$[Mm]od/Super/g' | fuzzel -d -a top --y 4 -w 50 -l 25 -p "" --placeholder "Search keybinds..."
