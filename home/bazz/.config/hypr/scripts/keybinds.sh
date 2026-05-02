#!/usr/bin/env bash

grep 'bind =' ~/.config/hypr/modules/05-binds.conf | grep -v '^\s*#' | sed 's/^bind = //; s/, */ /g; s/\$[Mm]od/Super/g' | fuzzel -d -a top --y 4 -w 40 -l 10 -p "" --placeholder "Search keybinds..."
