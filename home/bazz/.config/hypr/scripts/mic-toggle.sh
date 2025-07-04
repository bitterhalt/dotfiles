#!/usr/bin/env bash

set -euo pipefail

# Toggle mute state
wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle

# Check the current state
if wpctl get-volume @DEFAULT_AUDIO_SOURCE@ | grep -qi 'MUTED'; then
  # Mic is muted
  pw-play "${HOME}/.local/share/Sounds/device-removed.oga" &
  notify-send -i ~/.local/share/icons/feather/mic-off.svg "Microphone" "Muted" -t 1500 -h string:x-canonical-private-synchronous:volume
else
  # Mic is unmuted
  pw-play "${HOME}/.local/share/Sounds/audio-volume-change.oga" &
  notify-send -i ~/.local/share/icons/feather/mic.svg "Microphone" "Active" -t 1500 -h string:x-canonical-private-synchronous:volume
fi
