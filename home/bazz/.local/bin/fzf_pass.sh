#!/usr/bin/env bash
set -euo pipefail

PASSWORD_STORE_DIR="${PASSWORD_STORE_DIR:-$HOME/.password-store}"

passwords=$(find "$PASSWORD_STORE_DIR" -type f -name "*.gpg" ! -path "$PASSWORD_STORE_DIR/.git/*" |
  sed "s|^$PASSWORD_STORE_DIR/||;s/\.gpg$//" |
  sort)

selection=$(
  printf "%s\n" "$passwords" |
    fzf --border-label="Passwords" \
      --border=rounded \
      --layout=reverse \
      --with-nth=1 \
      --preview='echo ":: " {}' \
      --preview-window=down:1:wrap
)

[[ -z "${selection:-}" ]] && exit 0

if pass -c "$selection" >/dev/null 2>&1; then
  notify-send -t 10000 "Copied password" "$selection"
fi
