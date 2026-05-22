#!/usr/bin/env bash

CONFIG_FILE="$HOME/.config/niri/binds.kdl"

grep "hotkey-overlay-title=" "$CONFIG_FILE" |
  sed -E 's/^[[:space:]]*//;
          s/([[:alnum:]+]+) hotkey-overlay-title="([^"]+)".*/\1  ➜  \2/' |
  fuzzel -d -a top --y 8 -w 50 -l 15 -p "" --placeholder "Search keybinds..."
