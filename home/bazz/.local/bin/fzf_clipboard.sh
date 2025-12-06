#!/usr/bin/env bash
# Clipboard history picker using cliphist, fzf, and wl-copy.
set -euo pipefail

cliphist list | while IFS=$'\t' read -r id content || [[ -n "${id:-}" ]]; do
  [[ -z "${id:-}" ]] && continue

  if [[ "${content:-}" =~ binary\ data ]]; then
    icon="  "
  else
    icon="  "
  fi

  printf "%s\t%s%s\n" "$id" "$icon" "${content:-}"
done |
  fzf \
    -1 \
    --with-nth=2.. \
    --border=rounded \
    --border-label="Clipboard History" \
    --layout=reverse \
    --ansi \
    --bind "alt-0:execute-silent(rm -f ~/.cache/cliphist/db)+abort" \
    --preview-window='down:40%:wrap' \
    --preview '
        ID=$(echo {} | cut -f1)
        ROW=$(echo {})

        # Check if row is binary data for image preview
        if echo "$ROW" | grep -q "binary data"; then
            cliphist decode "$ID" 2>/dev/null | chafa -f sixel -s "${FZF_PREVIEW_COLUMNS}x${FZF_PREVIEW_LINES}"
        else
            # Decode text content and limit lines for preview
            cliphist decode "$ID" 2>/dev/null | sed "s/^/    /" | head -n 80
        fi
    ' |
  cut -f1 | tr -d '\n' | cliphist decode | wl-copy
