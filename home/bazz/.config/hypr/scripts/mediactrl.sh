#!/usr/bin/env bash

# Playerctl
# From https://github.com/JaKooLit

# Play the next track
play_next() {
  playerctl next
  show_music_notification
}

# Play the previous track
play_previous() {
  playerctl previous
  show_music_notification
}

# Toggle play/pause
toggle_play_pause() {
  playerctl play-pause
  show_music_notification
}

# Stop playback
stop_playback() {
  playerctl stop
  notify-send -e -u low " Playback Stopped"
}

# Display notification with song information
show_music_notification() {
  status=$(playerctl status)
  if [[ "$status" == "Playing" ]]; then
    song_title=$(playerctl metadata title)
    song_artist=$(playerctl metadata artist)
    notify-send -t 5000 -a Playerctl " Playing:" "$song_title\nby $song_artist" -h string:x-canonical-private-synchronous:volume
  elif [[ "$status" == "Paused" ]]; then
    notify-send -t 5000 -a Playerctl " Playback Paused" -h string:x-canonical-private-synchronous:volume
  fi
}

# Get media control action from command line argument
case "$1" in
"--nxt")
  play_next
  ;;
"--prv")
  play_previous
  ;;
"--pause")
  toggle_play_pause
  ;;
"--stop")
  stop_playback
  ;;
"--noti")
  show_music_notification
  ;;
*)
  echo "Usage: $0 [--noti|--nxt|--prv|--play|--stop]"
  exit 1
  ;;
esac
