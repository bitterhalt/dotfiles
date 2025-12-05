#!/usr/bin/env bash
set -euo pipefail

cliphist list |
  while IFS=$'\t' read -r id content; do
    if [[ "$content" =~ binary\ data ]]; then
      icon=""
    else
      icon=""
    fi

    printf "%s\t%s %s\n" "$id" "$icon" "$content"
  done |
  fzf --with-nth=2.. \
    --border-label=Clipboard \
    --layout=reverse \
    --border=rounded \
    --preview='
        id=$(echo {} | cut -f1)
        if echo {} | grep -q "binary data"; then
            echo "  <binary data>"
            echo "  (image preview disabled)"
        else
            cliphist decode "$id" | sed "s/^/  /" | head -n 80
        fi
    ' \
    --preview-window=down:8:wrap |
  cut -f1 |
  cliphist decode |
  wl-copy
