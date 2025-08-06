#!/usr/bin/env bash

wl-copy -t image/png <"$1"
notify-send \
  "${1%.*}" \
  "Copied to clipboard"
