#!/usr/bin/env bash

queue="$HOME/.local/share/timers/queue.json"

# Default display
text="󰂚"
tooltip="No tasks today"

# Only proceed if queue has timers
if [[ -f "$queue" ]] && [[ $(jq length "$queue" 2>/dev/null) -gt 0 ]]; then
  entry=$(jq -c 'sort_by(.fire_at) | .[0]' "$queue")

  if [[ -n "$entry" && "$entry" != "null" ]]; then
    fire_at=$(jq -r '.fire_at' <<<"$entry")
    msg=$(jq -r '.message' <<<"$entry")
    now=$(date +%s)

    if ((fire_at > now)); then
      fire_date=$(date -d "@$fire_at" +%Y-%m-%d)
      today=$(date +%Y-%m-%d)

      # Determine display date
      if [[ "$fire_date" == "$today" ]]; then
        date_label="Today"
        text="! $msg"
      else
        date_label=$(date -d "@$fire_at" "+%d.%m")
        text="󰂚"
      fi

      # Time for tooltip
      time_label=$(date -d "@$fire_at" +%H:%M)

      # Tooltip always shows time and message
      tooltip="<b>Next task</b>\n\n📅 $date_label ⏰ <b>$time_label</b>\n\n$msg"
    fi
  fi
fi

# Escape quotes and output JSON
printf '{"text":"%s","tooltip":"%s"}\n' \
  "$(printf '%s' "$text" | sed 's/"/\\"/g')" \
  "$(printf '%s' "$tooltip" | sed 's/"/\\"/g')"
