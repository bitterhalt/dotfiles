#!/usr/bin/env bash

notify_track() {
  if playerctl status == "Playing" >/dev/null; then
    title=$(playerctl metadata title 2>/dev/null || echo "Unknown Title")
    artist=$(playerctl metadata artist 2>/dev/null || echo "")
    notify-send -a Media-notify -t 5000 -i media-playback-playing "$artist" "$title" -h string:x-canonical-private-synchronous:volume
  fi
}

play_next() {
  playerctl next
}

play_previous() {
  playerctl previous
}

toggle_play_pause() {
  playerctl play-pause
}

stop_playback() {
  playerctl stop
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
  notify_track
  ;;
*)
  echo "Usage: $0 [--nxt|--prv|--play|--stop|--noti]"
  exit 1
  ;;
esac
