#!/usr/bin/env bash

menu="dmenu-runner --minimal-lines"

choice=$(printf '%s\n' "Rename" "Reset" |
  $menu -p "Rename workspace") || exit 0

case "$choice" in
Rename)
  name=$(printf '' | $menu -p "Set name") || exit 0
  [[ -z "${name//[[:space:]]/}" ]] && exit 0
  niri msg action set-workspace-name "$name"
  ;;
Reset)
  niri msg action unset-workspace-name
  ;;
esac
