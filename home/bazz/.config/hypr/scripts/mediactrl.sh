#!/usr/bin/env bash

is_player_running() {
  playerctl --list-all >/dev/null 2>&1
  return $?
}

ignis_osd() {
  if command -v ignis >/dev/null 2>&1; then
    goignis toggle-window ignis_MEDIA_OSD
  else
    show_fallback_notification
  fi
}

show_fallback_notification() {
  if ! is_player_running; then
    return 0
  fi

  status=$(playerctl status 2>/dev/null || echo "Unknown")
  if [[ "$status" == "Playing" ]]; then
    song_title=$(playerctl metadata title 2>/dev/null || echo "Unknown Title")
    notify-send -t 5000 -a Playerctl "Playing" "$song_title" -h string:x-canonical-private-synchronous:volume
  elif [[ "$status" == "Paused" ]]; then
    notify-send -t 5000 -a Playerctl "Playback Paused" -h string:x-canonical-private-synchronous:volume
  fi
}

# Play the next track
play_next() {
  playerctl next
  ignis_osd
}

# Play the previous track
play_previous() {
  playerctl previous
  ignis_osd
}

# Toggle play/pause
toggle_play_pause() {
  playerctl play-pause
  ignis_osd
}

# Stop playback
stop_playback() {
  playerctl stop
  notify-send -e -u low "Playback Stopped"
}

case "$1" in
"--nxt")
  play_next
  ;;
"--prv")
  play_previous
  ;;
"--play")
  toggle_play_pause
  ;;
"--stop")
  stop_playback
  ;;
"--noti")
  ignis_osd
  ;;
*)
  echo "Usage: $0 [--noti|--nxt|--prv|--play|--stop]"
  exit 1
  ;;
esac
