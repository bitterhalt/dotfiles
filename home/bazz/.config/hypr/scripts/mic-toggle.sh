#!/usr/bin/env bash

sounds="$HOME/.local/share/Sounds"

set -euo pipefail

wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle

if wpctl get-volume @DEFAULT_AUDIO_SOURCE@ | grep -qi 'MUTED'; then
  pw-play "$sounds"/device-removed.oga &
else
  pw-play "$sounds"/audio-volume-change.oga &
fi
