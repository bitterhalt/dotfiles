#!/usr/bin/env bash
set -euo pipefail

# Safe wrapper around cliphist list to avoid empty lines
cliphist list | {
  while IFS=$'\t' read -r id content || [[ -n "${id:-}" ]]; do
    # Skip empty lines
    [[ -z "${id:-}" ]] && continue

    # Detect binary or text
    if [[ "${content:-}" =~ binary\ data ]]; then
      icon=" "
    else
      icon=" "
    fi

    printf "%s\t%s%s\n" "$id" "$icon" "${content:-}"
  done
} | fzf \
  --ansi \
  --with-nth=2.. \
  --border-label=" Clipboard " \
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
  --preview-window=down:8:wrap \
  \
  --bind "alt-0:execute-silent(rm -f ~/.cache/cliphist/db)+abort" \
  \
  --bind "alt-1:execute-silent(
        id=\$(echo {} | cut -f1);
        cliphist delete \"\$id\";
    )+reload(
        cliphist list | while IFS=$'\''\t'\'' read -r id content || [[ -n \"\${id:-}\" ]]; do
            [[ -z \"\${id:-}\" ]] && continue;
            if [[ \"\${content:-}\" =~ binary\ data ]]; then
                icon=\" \";
            else
                icon=\" \";
            fi;
            printf \"%s\t%s%s\n\" \"\$id\" \"\$icon\" \"\${content:-}\";
        done
    )" |
  cut -f1 |
  xargs -r cliphist decode |
  wl-copy
