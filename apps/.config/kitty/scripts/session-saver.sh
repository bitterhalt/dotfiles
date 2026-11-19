#!/usr/bin/env bash

base="$HOME/.local/share/kitty/sessions"
self=$(realpath "$0")
mkdir -p -- "$base"

list_sessions() {
  find "$base" -type f -printf '%P\n' | sort
}

valid_name() {
  [[ -n $1 && $1 != *..* && $1 != /* ]]
}

delete_session() {
  local name=$1 ans
  valid_name "$name" || return 1
  [[ -f "$base/$name" ]] || return 1
  printf 'Delete "%s"? [y/N] ' "$name" >/dev/tty
  read -r -n1 ans </dev/tty
  echo >/dev/tty
  [[ $ans == [yY] ]] && rm -- "$base/$name"
}

case "$1" in
--list)
  list_sessions
  exit 0
  ;;
--delete)
  delete_session "$2"
  exit 0
  ;;
esac

out=$(
  list_sessions |
    fzf --print-query \
      --expect=ctrl-n \
      --no-info \
      --no-sort \
      --layout=reverse \
      --prompt="save as: " \
      --header="Enter: Overwrite selected / Del: Delete" \
      --bind "enter:accept-or-print-query" \
      --bind "del:execute(\"$self\" --delete {})+reload(\"$self\" --list)"
)
rc=$?
[[ $rc -eq 130 ]] && exit 0

mapfile -t lines <<<"$out"
query=${lines[0]}
key=${lines[1]}
sel=${lines[2]}

# ctrl-n or no match -> use typed name, otherwise overwrite the highlighted one
if [[ $key == ctrl-n || -z $sel ]]; then
  name=$query
else
  name=$sel
fi

valid_name "$name" || exit 1
path="$base/$name"

if [[ -e $path ]]; then
  printf 'Overwrite "%s"? [y/N] ' "$name" >/dev/tty
  read -r -n1 ans </dev/tty
  echo >/dev/tty
  [[ $ans == [yY] ]] || exit 0
fi

mkdir -p -- "$(dirname -- "$path")"
kitty @ action save_as_session --use-foreground-process --base-dir "$base" "$path"
# remove the saver's own overlay window from the saved session
sed -i '/session-saver\.sh/d' "$path"
