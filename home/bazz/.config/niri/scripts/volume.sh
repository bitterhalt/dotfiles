#!/usr/bin/env bash

set -euo pipefail

noti="notify-send -t 1000 -a vol-osd -h string:x-canonical-private-synchronous:volume"

case "${1:-}" in
up)
  wpctl set-mute @DEFAULT_AUDIO_SINK@ 0
  wpctl set-volume -l 1.1 @DEFAULT_AUDIO_SINK@ 5%+
  ;;
down)
  wpctl set-mute @DEFAULT_AUDIO_SINK@ 0
  wpctl set-volume -l 1.1 @DEFAULT_AUDIO_SINK@ 5%-
  ;;
mute)
  wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle
  ;;
esac

vol="$(wpctl get-volume @DEFAULT_AUDIO_SINK@)"

[ "$vol" != "${vol%\[MUTED\]}" ] && $noti "Muted" && exit

vol="${vol#Volume: }"

split() {
  IFS=$2
  set -- $1
  printf '%s' "$@"
}

vol="$(printf "%.0f" "$(split "$vol" ".")")"

case 1 in
$((vol >= 1))) ;;
*) $noti "Muted" && exit ;;
esac

$noti \
  "$vol%" \
  -h int:value:"${vol}" \
  -h string:x-canonical-private-synchronous:volume
