#!/usr/bin/env bash

COUNT=$(makoctl history -j | jq '. | length')

if makoctl mode | grep -q 'dnd'; then
  MODE="dnd"
  ICON="󰂛"
else
  MODE="default"
  ICON="󰂚"
fi

if [ "$COUNT" -eq 0 ]; then
  DISPLAY_TEXT="$ICON"
else
  DISPLAY_TEXT="$ICON $COUNT"
fi

printf '{"text": "%s", "alt": "%s"}\n' "$DISPLAY_TEXT" "$MODE"
