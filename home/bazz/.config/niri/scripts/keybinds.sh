#!/usr/bin/env bash

CONFIG_FILE="$HOME/.config/niri/binds.kdl"
DMENU="${DMENU:-vicinae dmenu}"

grep 'hotkey-overlay-title=' "$CONFIG_FILE" |
  sed -En 's/^[[:space:]]*([[:alnum:]+]+).*hotkey-overlay-title="([^"]+)".*/\1\t\2/p' |
  awk -F'\t' '{ printf "%-18s → %s\n", $1, $2 }' |
  $DMENU --placeholder "Search keybinds"
