#!/usr/bin/env bash

COUNT=$(makoctl history -j | jq '. | length')

if makoctl mode | grep -q 'dnd'; then
  MODE="dnd"
else
  MODE="default"
fi

printf '{"text": " %s", "alt": "%s"}\n' "$COUNT" "$MODE"
