#!/usr/bin/env bash
img="$1"
rot=0
while true; do
  swayimg --exec "Shift+f:quit" -- "$img" &
  wait $!
  rot=$((rot + 90))
  [ $rot -ge 360 ] && rot=0
  tmp=$(mktemp /tmp/swayimg-XXXX.jpg)
  convert "$img" -rotate "$rot" "$tmp"
  img="$tmp"
done
