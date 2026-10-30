#!/usr/bin/env bash

# Restart active XDG desktop portals

portals=(
  xdg-desktop-portal-gtk
  xdg-desktop-portal-gnome
  xdg-desktop-portal-hyprland
  xdg-desktop-portal-wlr
)

for portal in "${portals[@]}"; do
  if systemctl --user is-active --quiet "$portal.service"; then
    echo "Restarting $portal..."
    systemctl --user restart "$portal.service"
  fi
done

# Restart the main portal last
if systemctl --user is-active --quiet xdg-desktop-portal.service; then
  echo "Restarting xdg-desktop-portal..."
  systemctl --user restart xdg-desktop-portal.service
fi
