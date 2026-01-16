#!/usr/bin/env bash

kill() {
  pkill ignis
}

case "$1" in
stop)
  pkill ignis
  ;;
*)
  if pgrep -x "ignis" >/dev/null; then
    pkill ignis
    sleep 0.5
    ignis init &
  else
    ignis init &
  fi
  ;;

esac
