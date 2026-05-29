#!/usr/bin/env bash

COUNT=$(makoctl history -j | jq '. | length')

if makoctl mode | grep -q 'dnd'; then
  MODE="dnd"
  DISPLAY_TEXT="󰂛"
else
  MODE="default"
  if [ "$COUNT" -gt 0 ]; then
    DISPLAY_TEXT="󰂚 $COUNT"
  else
    DISPLAY_TEXT=""
  fi
fi

printf '{"text": "%s", "class": "%s"}\n' "$DISPLAY_TEXT" "$MODE"
