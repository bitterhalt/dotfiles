#!/usr/bin/env bash

# label:directory pairs
session_dirs=(
  "data:$HOME/.local/share/kitty/sessions"
  "config:$HOME/.config/kitty/sessions"
)
self=$(realpath "$0")

# Output: "<name>  [<label>]<TAB><full path>"
list_sessions() {
  local entry label dir
  for entry in "${session_dirs[@]}"; do
    label=${entry%%:*}
    dir=${entry#*:}
    [[ -d $dir ]] || continue
    find "$dir" -type f -printf "%P  [$label]\t%p\n"
  done | sort
}

# Print the session dir that contains $1; fail if none does
dir_of() {
  local entry dir
  for entry in "${session_dirs[@]}"; do
    dir=${entry#*:}
    [[ $1 == "$dir"/* ]] && {
      printf '%s\n' "$dir"
      return 0
    }
  done
  return 1
}

edit_session() {
  local path=$1 editor=${EDITOR:-} e
  dir_of "$path" >/dev/null || return 1
  [[ -f $path ]] || return 1
  if [[ -z $editor ]]; then
    for e in nvim vim vi; do
      command -v "$e" >/dev/null && {
        editor=$e
        break
      }
    done
  fi
  $editor "$path" </dev/tty >/dev/tty
}

delete_session() {
  local path=$1 ans
  dir_of "$path" >/dev/null || return 1
  [[ -f $path ]] || return 1
  printf 'Delete "%s"? [y/N] ' "${path/#$HOME/\~}" >/dev/tty
  read -r -n1 ans </dev/tty
  echo >/dev/tty
  [[ $ans == [yY] ]] && rm -- "$path"
}

rename_session() {
  local path=$1 dir old new
  dir=$(dir_of "$path") || return 1
  [[ -f $path ]] || return 1
  old=${path#"$dir"/}

  read -e -i "$old" -p "Rename: " new </dev/tty >/dev/tty
  [[ -z $new || $new == "$old" ]] && return 0
  [[ $new == *..* || $new == /* ]] && return 0

  if [[ -e "$dir/$new" ]]; then
    printf '"%s" already exists. Press any key...' "$new" >/dev/tty
    read -r -n1 </dev/tty
    return 0
  fi

  mkdir -p -- "$(dirname -- "$dir/$new")"
  mv -- "$path" "$dir/$new"
}

case "$1" in
--list)
  list_sessions
  exit 0
  ;;
--edit)
  edit_session "$2"
  exit 0
  ;;
--delete)
  delete_session "$2"
  exit 0
  ;;
--rename)
  rename_session "$2"
  exit 0
  ;;
esac

selected=$(
  list_sessions |
    fzf --no-sort \
      --no-info \
      --prompt="Select session > " \
      --layout=reverse \
      --border-label="" \
      --delimiter=$'\t' --with-nth=1 \
      --header="Enter: Open  Ctrl-e: Edit  Ctrl-r: Rename  Del: Delete" \
      --bind "ctrl-e:execute(\"$self\" --edit {2})" \
      --bind "ctrl-r:execute(\"$self\" --rename {2})+reload(\"$self\" --list)" \
      --bind "del:execute(\"$self\" --delete {2})+reload(\"$self\" --list)"
)

[[ -z "$selected" ]] && exit 0

kitty @ action goto_session "${selected#*$'\t'}"
