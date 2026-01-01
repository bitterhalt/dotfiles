#!/usr/bin/env bash

sounds="$HOME/.local/share/Sounds"

set -euo pipefail

# Toggle mute state
wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle

# Check the current state
if wpctl get-volume @DEFAULT_AUDIO_SOURCE@ | grep -qi 'MUTED'; then
  # Mic is muted
  pw-play "$sounds"/device-removed.oga &
else
  # Mic is unmuted
  pw-play "$sounds"/audio-volume-change.oga &
fi
