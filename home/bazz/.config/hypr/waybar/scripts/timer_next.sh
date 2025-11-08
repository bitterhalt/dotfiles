#!/usr/bin/env bash

queue="$HOME/.local/share/timers/queue.json"

# Default display
text="󰂚" tooltip="No tasks today"

# Only proceed if queue has timers
if [[ -f "$queue" ]] && [[ $(jq length "$queue" 2>/dev/null) -gt 0 ]]; then
  entry=$(jq -c 'sort_by(.fire_at) | .[0]' "$queue")
  if [[ -n "$entry" && "$entry" != "null" ]]; then
    fire_at=$(jq -r '.fire_at' <<<"$entry")
    msg=$(jq -r '.message' <<<"$entry")
    if ((fire_at > $(date +%s))); then
      # Determine display text
      if [[ $(date +%Y-%m-%d) == $(date -d "@$fire_at" +%Y-%m-%d) ]]; then
        text="! $msg"
        date_label="Today"
      else
        date_label=$(date -d "@$fire_at" "+%d.%m")
      fi
      # Tooltip always shows time and message
      tooltip="<b>Next task</b>\n\n📅 $date_label ⏰ <b>$(date -d "@$fire_at" +%H:%M)</b>\n\n$msg"
    fi
  fi
fi

# Escape quotes and output JSON
printf '{"text":"%s","tooltip":"%s"}\n' \
  "$(printf '%s' "$text" | sed 's/"/\\"/g')" \
  "$(printf '%s' "$tooltip" | sed 's/"/\\"/g')"
