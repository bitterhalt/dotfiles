#!/usr/bin/env bash

# Timer daemon for my fuzzel timer
# Dependencies:
# - inotify-tools
# - libnotify
# - pipewire
# - yad

notify="notify-send -t 15000"
queue="$HOME/.local/share/timers/queue"
lock="/tmp/timer_daemon.lock"

idle_sleep=$((60 * 60))         # Sleep when no timers (1 hour)
min_sleep=5                     # Minimum sleep time (seconds)
expire_seconds=$((4 * 60 * 60)) # Remove timers older than 4 hours

# YAD popup
yad_notify() {
  yad --info \
    --title="Timer Finished" \
    --text="<big><b>⏰ Timer Done</b></big>\n\n$1" \
    --width=300 \
    --button="Close:0"
}

mkdir -p "$(dirname "$queue")"
touch "$queue"

# Lock file
if [[ -f "$lock" ]]; then
  oldpid=$(cat "$lock")
  if ps -p "$oldpid" >/dev/null 2>&1; then
    echo "Timer daemon already running."
    exit 1
  else
    echo "Stale lock detected — cleaning."
    echo $$ >"$lock"
  fi
else
  echo $$ >"$lock"
fi

cleanup() {
  rm -f "$lock"
  exit 0
}
trap cleanup EXIT SIGINT SIGTERM

while true; do
  now=$(date +%s)
  next_fire_at=""
  tmp=$(mktemp)

  if [[ -f "$queue" ]]; then
    while IFS="|" read -r id fire_at message; do
      [[ -z "$id" ]] && continue

      if ((fire_at <= now)); then
        # Notify only if timer not too old
        if ((now - fire_at < expire_seconds)); then
          $notify "⏰ Timer Done" "$message" &
          yad_notify "$message" &
          pw-play ~/.local/share/Sounds/complete.oga &
        fi
      else
        echo "$id|$fire_at|$message" >>"$tmp"

        if [[ -z "$next_fire_at" || "$fire_at" -lt "$next_fire_at" ]]; then
          next_fire_at="$fire_at"
        fi
      fi
    done <"$queue"
  fi

  mv "$tmp" "$queue"

  if [[ -z "$next_fire_at" ]]; then
    sleep_time=$idle_sleep
  else
    now=$(date +%s)
    sleep_time=$((next_fire_at - now))
    ((sleep_time < min_sleep)) && sleep_time=$min_sleep
  fi

  inotifywait -qq -t "$sleep_time" -e modify "$queue" 2>/dev/null
done
