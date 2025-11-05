#!/usr/bin/env bash

# Timer daemon for my fuzzel timer
# Dependencies:
# - inotify-tools
# - libnotify
# - pipewire
# - zenity

queue="$HOME/.local/share/timers/queue"
lock="/tmp/timer_daemon.lock"

idle_sleep=$((60 * 60))         # Sleep when no timers (1 hour)
min_sleep=5                     # Minimum sleep time (seconds)
expire_seconds=$((4 * 60 * 60)) # Remove timers older than 4 hours

mkdir -p "$(dirname "$queue")"
touch "$queue"

# Prevent multiple instances
if [[ -e "$lock" ]]; then
  echo "Timer daemon already running."
  exit 1
fi
echo $$ >"$lock"

cleanup() {
  rm -f "$lock"
  exit 0
}
trap cleanup EXIT SIGINT SIGTERM

while true; do
  now=$(date +%s)
  next_fire_at=""
  tmp=$(mktemp)

  # Timer queue
  if [[ -f "$queue" ]]; then
    while IFS="|" read -r id fire_at message; do
      [[ -z "$id" ]] && continue

      if ((fire_at <= now)); then
        # If expired less than 4 hours ago → notify
        if ((now - fire_at < expire_seconds)); then
          zenity --info --title="⏰ Timer Finished" --text="$message" --width=250 &
          pw-play ~/.local/share/Sounds/complete.oga &
        fi
        # Otherwise silently drop (old entry)
      else
        echo "$id|$fire_at|$message" >>"$tmp"
        if [[ -z "$next_fire_at" || "$fire_at" -lt "$next_fire_at" ]]; then
          next_fire_at="$fire_at"
        fi
      fi
    done <"$queue"
  fi

  mv "$tmp" "$queue"

  # Compute sleep duration
  if [[ -z "$next_fire_at" ]]; then
    sleep_time=$idle_sleep
  else
    now=$(date +%s)
    sleep_time=$((next_fire_at - now))
    ((sleep_time < min_sleep)) && sleep_time=$min_sleep
  fi

  # Wait for file Update or timeout
  inotifywait -qq -t "$sleep_time" -e modify "$queue" 2>/dev/null
done
