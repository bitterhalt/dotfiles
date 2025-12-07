#!/usr/bin/env bash

grep 'bind =' ~/.config/hypr/modules/05-binds.conf | grep -v '^\s*#' | sed 's/^bind = //; s/, */ /g; s/\$[Mm]od/Super/g' | fuzzel -d -a top --y 4 -w 70 -l 25 -p "" --placeholder "Search keybinds..."
