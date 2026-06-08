#!/usr/bin/env bash

portals=(
  "xdg-desktop-portal-gtk"
  "xdg-desktop-portal-gnome"
  "xdg-desktop-portal-hyprland"
  "xdg-desktop-portal-wlr"
)

for portal in "${portals[@]}"; do
  if systemctl --user is-active "$portal" >/dev/null 2>&1; then
    echo "Restarting $portal via systemd..."
    systemctl --user restart "$portal"
  else
    if pgrep -f "$portal" >/dev/null 2>&1; then
      echo "Killing active instance of $portal..."
      pkill -f "$portal"
      sleep 0.2
    fi

    for libdir in /usr/lib /usr/libexec /usr/lib/xdg-desktop-portal; do
      if [[ -x "$libdir/$portal" ]]; then
        echo "Manually starting $portal from $libdir..."
        "$libdir/$portal" &>/dev/null &
        break
      fi
    done
  fi
done

if systemctl --user is-active xdg-desktop-portal >/dev/null 2>&1; then
  systemctl --user restart xdg-desktop-portal
else
  pkill -f xdg-desktop-portal
  for libdir in /usr/lib /usr/libexec; do
    if [[ -x "$libdir/xdg-desktop-portal" ]]; then
      "$libdir/xdg-desktop-portal" &>/dev/null &
      break
    fi
  done
fi
