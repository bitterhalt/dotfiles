#!/usr/bin/env bash

if pgrep -x "ignis" >/dev/null; then
  pkill ignis
  sleep 1
  ignis init &
else
  ignis init &
fi
