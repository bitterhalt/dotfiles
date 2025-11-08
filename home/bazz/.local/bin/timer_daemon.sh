#!/usr/bin/env bash
# Timer daemon for notifications and Waybar integration
# Dependencies: jq, yad, notify-send, pw-play (optional), inotify-tools

queue="$HOME/.local/share/timers/queue.json"
lock="/tmp/timer_daemon.lock"
notify_cmd="notify-send -t 15000"

idle_sleep=$((60 * 60))         # Sleep 1 hour if no timers
min_sleep=5                     # Minimum sleep between checks (seconds)
expire_seconds=$((4 * 60 * 60)) # Drop timers older than 4 hours

# Command mode: stop daemon
if [[ "$1" == "kill" ]]; then
  if [[ -f "$lock" ]]; then
    pid=$(cat "$lock")
    if ps -p "$pid" >/dev/null 2>&1; then
      echo "Stopping timer daemon (PID $pid)..."
      kill "$pid"
      sleep 0.3
      [[ $(
        ps -p "$pid" >/dev/null 2>&1
        echo $?
      ) -eq 0 ]] && kill -9 "$pid"
    fi
    rm -f "$lock"
    echo "Timer daemon stopped."
    exit 0
  else
    echo "Daemon not running."
    exit 1
  fi
fi

# Functions
yad_notify() {
  yad --info \
    --title="Timer Finished" \
    --text="<big><b>Timer Done</b></big>\n\n$1" \
    --width=300 --button="Close:0"
}

# Ensure queue exists
mkdir -p "$(dirname "$queue")"
[[ ! -f "$queue" ]] && echo "[]" >"$queue"

# Lock file logic
if [[ -f "$lock" ]]; then
  oldpid=$(cat "$lock")
  if ps -p "$oldpid" >/dev/null 2>&1; then
    echo "Timer daemon already running (PID $oldpid)."
    exit 1
  else
    echo "Stale lock removed."
  fi
fi

echo $$ >"$lock"
[[ -t 1 ]] && echo "Timer daemon started (PID $$)"

# Cleanup
cleanup() {
  [[ -n "$INOTIFY_PID" ]] && kill "$INOTIFY_PID" 2>/dev/null
  rm -f "$lock"
  exit 0
}
trap cleanup INT TERM EXIT

# Main loop
while true; do
  now=$(date +%s)
  next_fire_at=""
  timers=$(jq -c '.[]' "$queue" 2>/dev/null)
  new_list="[]"

  while IFS= read -r timer; do
    [[ -z "$timer" ]] && continue
    fire_at=$(jq -r '.fire_at' <<<"$timer")
    message=$(jq -r '.message' <<<"$timer")

    if ((fire_at <= now)); then
      if ((now - fire_at < expire_seconds)); then
        # Notify user
        $notify_cmd "Timer Done" "$message" &
        yad_notify "$message" &
        command -v pw-play >/dev/null && pw-play ~/.local/share/Sounds/complete.oga &

        # Signal Waybar only if running
        if pgrep -x "waybar" >/dev/null; then
          pkill -RTMIN+3 waybar 2>/dev/null
        fi
      fi
    else
      # Keep pending timers
      new_list=$(jq --argjson t "$timer" '. += [$t]' <<<"$new_list")
      if [[ -z "$next_fire_at" || "$fire_at" -lt "$next_fire_at" ]]; then
        next_fire_at="$fire_at"
      fi
    fi
  done <<<"$timers"

  # Write back updated queue
  echo "$new_list" >"$queue"

  # Calculate sleep time
  if [[ -z "$next_fire_at" ]]; then
    sleep_time=$idle_sleep
  else
    now=$(date +%s)
    sleep_time=$((next_fire_at - now))
    ((sleep_time < min_sleep)) && sleep_time=$min_sleep
  fi

  # Wait for queue modification or next timer
  inotifywait -qq -t "$sleep_time" -e modify "$queue" 2>/dev/null &
  INOTIFY_PID=$!
  wait "$INOTIFY_PID" 2>/dev/null
  INOTIFY_PID=""
done
