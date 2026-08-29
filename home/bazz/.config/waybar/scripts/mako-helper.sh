#!/usr/bin/env bash

COUNT=$(makoctl history -j | jq '. | length')

if makoctl mode | grep -q 'dnd'; then
  MODE="dnd"
  DISPLAY_TEXT="󰂛"
  TOOLTIP="Do Not Disturb"
else
  MODE="default"
  if [ "$COUNT" -gt 0 ]; then
    DISPLAY_TEXT="󰂚"
  else
    DISPLAY_TEXT=""
  fi
  TOOLTIP="You have $COUNT notifications"
fi

printf '{"text": "%s", "class": "%s", "tooltip": "%s"}\n' "$DISPLAY_TEXT" "$MODE" "$TOOLTIP"
