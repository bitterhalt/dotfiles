#!/usr/bin/env bash

CONFIG_FILE="$HOME/.config/niri/binds.kdl"

grep 'hotkey-overlay-title=' "$CONFIG_FILE" |
  sed -En 's/^[[:space:]]*([[:alnum:]+]+).*hotkey-overlay-title="([^"]+)".*/\1\t\2/p' |
  awk -F'\t' '{ printf "%-18s → %s\n", $1, $2 }' |
  fuzzel -d -a top --y 8 -w 50 -l 15 -p "" --placeholder "Search keybinds"
