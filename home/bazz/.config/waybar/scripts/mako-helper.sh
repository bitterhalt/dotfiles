#!/usr/bin/env bash

COUNT=$(makoctl history -j | jq '. | length')

if [ "$COUNT" -eq 0 ]; then
  DISPLAY_COUNT=""
else
  DISPLAY_COUNT="$COUNT"
fi

if makoctl mode | grep -q 'dnd'; then
  MODE="dnd"
else
  MODE="default"
fi

printf '{"text": " %s", "alt": "%s"}\n' "$DISPLAY_COUNT" "$MODE"
