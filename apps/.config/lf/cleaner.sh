#!/usr/bin/env bash
if [ -n "$KITTY_WINDOW_ID" ]; then
  kitten icat --clear --stdin=no --transfer-mode=memory </dev/null >/dev/tty
fi
