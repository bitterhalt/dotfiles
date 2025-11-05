#!/usr/bin/env bash

# Timer daemon for my fuzzel timer
# Dependencies:
# - inotify-tools
# - libnotify
# - pipewire
# - zenity

QUEUE_DIR="$HOME/.local/share/timers"
QUEUE="$QUEUE_DIR/queue"
LOCK="$QUEUE_DIR/daemon.lock"

IDLE_SLEEP=$((60 * 60)) # Sleep when no timers (1 hour)
MIN_SLEEP=5             # Minimum sleep time (seconds)

mkdir -p "$QUEUE_DIR"

# Prevent multiple instances
if [[ -e "$LOCK" ]]; then
  echo "Timer daemon already running."
  exit 1
fi
echo $$ >"$LOCK"

cleanup() {
  rm -f "$LOCK"
  exit 0
}
trap cleanup EXIT SIGINT SIGTERM

while true; do
  now=$(date +%s)
  next_fire_at=""
  tmp=$(mktemp)

  # Timer queue
  if [[ -f "$QUEUE" ]]; then
    while IFS="|" read -r id fire_at message; do
      [[ -z "$id" ]] && continue

      if ((fire_at <= now)); then
        zenity --info --title="⏰ Timer Finished" --text="$message" --width=250 &
        pw-play ~/.local/share/Sounds/complete.oga &
      else
        echo "$id|$fire_at|$message" >>"$tmp"
        if [[ -z "$next_fire_at" || "$fire_at" -lt "$next_fire_at" ]]; then
          next_fire_at="$fire_at"
        fi
      fi
    done <"$QUEUE"
  fi

  mv "$tmp" "$QUEUE"

  # Compute Sleep Duration
  if [[ -z "$next_fire_at" ]]; then
    sleep_time=$IDLE_SLEEP
  else
    now=$(date +%s)
    sleep_time=$((next_fire_at - now))
    ((sleep_time < MIN_SLEEP)) && sleep_time=$MIN_SLEEP
  fi

  #  Wait for File Update or Timeout
  inotifywait -qq -t "$sleep_time" -e modify "$QUEUE" 2>/dev/null
done
