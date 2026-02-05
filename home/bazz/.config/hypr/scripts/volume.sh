#!/usr/bin/env bash

set -euo pipefail

SOUND="$HOME/.local/share/Sounds/audio-volume-change.oga"

play_sound() {
  [ -f "$SOUND" ] && pw-play "$SOUND" &
}

case "${1:-}" in
up)
  wpctl set-mute @DEFAULT_AUDIO_SINK@ 0
  wpctl set-volume -l 1.1 @DEFAULT_AUDIO_SINK@ 5%+
  play_sound
  goignis open-window ignis_VOLUME_OSD
  ;;
down)
  wpctl set-mute @DEFAULT_AUDIO_SINK@ 0
  wpctl set-volume -l 1.1 @DEFAULT_AUDIO_SINK@ 5%-
  play_sound
  goignis open-window ignis_VOLUME_OSD
  ;;
mute)
  wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle
  ;;
esac
