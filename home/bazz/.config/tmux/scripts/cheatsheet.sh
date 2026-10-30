#!/usr/bin/env bash

set -euo pipefail

prefix=$(tmux show -gv prefix)

bindings() {
  tmux list-keys -F '#{key_table}	#{key_string}	#{key_note}	#{key_command}' |
    while IFS= read -r line; do
      IFS=$'\t' read -r table key note command <<<"$line"

      # Only show our own marked bindings
      [[ "$note" == @* ]] || continue

      case "$table" in
      prefix) shortcut="$prefix $key" ;;
      root) shortcut="$key" ;;
      *) continue ;;
      esac

      printf '%-14s\t%s\t%s\n' \
        "$shortcut" "${note#@}" "$command"
    done
}

selection=$(
  bindings | fzf \
    --reverse \
    --no-sort \
    --border=none \
    --no-info \
    --no-separator \
    --no-header \
    --prompt='> ' \
    --delimiter=$'\t' \
    --with-nth=1,2 \
    --height=100%
) || exit 0

[[ -n "$selection" ]] || exit 0

command=${selection##*$'\t'}

tmux "$command"
