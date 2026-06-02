#!/usr/bin/env bash

command -v gm >/dev/null || {
  printf "'graphicsmagick' not installed\n"
  exit 1
}

output=$(niri msg pick-color)
color=${output##*Hex: }

[ "$color" ] && {
  printf "%s" "$color" | wl-copy
  printf "%s\n" "$color"
  prev="$(mktemp -u).png"
  trap 'rm -f "$prev"' EXIT
  gm convert -size 32x32 "xc:$color" "$prev" && icon="$prev" || icon=""
  notify-send -t 3000 -a niripick ${icon:+-i "$icon"} "Color picker" "$color\nCopied to clipboard!"
}
