#!/usr/bin/env bash

COUNT=$(makoctl history -j | jq '. | length')

if makoctl mode | grep -q 'dnd'; then
  MODE="dnd"
  ICON="󰂛"
else
  MODE="default"
  ICON="󰂚"
fi

if [ "$COUNT" -eq 0 ] || [ "$MODE" = "dnd" ]; then
  DISPLAY_TEXT="$ICON"
else
  DISPLAY_TEXT="$ICON $COUNT"
fi

# Output valid JSON with the "class" parameter for styling
printf '{"text": "%s", "class": "%s"}\n' "$DISPLAY_TEXT" "$MODE"
