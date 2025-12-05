#!/usr/bin/env bash
set -euo pipefail

# Build list: id<TAB>icon content
cliphist list |
  while IFS=$'\t' read -r id content || [[ -n "${id:-}" ]]; do
    [[ -z "${id:-}" ]] && continue

    if [[ "${content:-}" =~ binary\ data ]]; then
      icon="  "
    else
      icon="  "
    fi

    printf "%s\t%s%s\n" "$id" "$icon" "${content:-}"
  done |
  fzf \
    --with-nth=2.. \
    --border-label="Clipboard" \
    --border=rounded \
    --layout=reverse \
    --preview="
      id=\$(echo {} | cut -f1)
      row=\$(echo {})

      if echo \"\$row\" | grep -q \"binary data\"; then
          cliphist decode \"\$id\" 2>/dev/null | \
              chafa -f sixel -s \"\${FZF_PREVIEW_COLUMNS}x\${FZF_PREVIEW_LINES}\"
      else
          cliphist decode \"\$id\" 2>/dev/null | sed 's/^/  /' | head -n 80
      fi
    " \
    --bind "alt-0:execute-silent(rm -f ~/.cache/cliphist/db)+abort" |
  cut -f1 |
  cliphist decode |
  wl-copy
