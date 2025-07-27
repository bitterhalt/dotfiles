#!/usr/bin/env bash

# Menu options
ARCHIVE="BASH
FNOTT
FOOT
FUZZEL
HYPRIDLE
HYPRLAND
HYPRLOCK
NEOVIM
WAYBAR
"
CHOICE=$(printf "$ARCHIVE" | fuzzel -d -a top --y 4 -w 30 -l 9 -p "" --placeholder "Edit settings: ")

TERMCMD=("foot")

case $CHOICE in
BASH) $TERMCMD -e nvim $HOME/.bashrc ;;
FNOTT) $TERMCMD -e nvim $HOME/.config/fnott/fnott.ini ;;
FOOT) $TERMCMD -e nvim $HOME/.config/foot/foot.ini ;;
FUZZEL) $TERMCMD -e nvim $HOME/.config/fuzzel/fuzzel.ini ;;
HYPRIDLE) $TERMCMD -e nvim $HOME/.config/hypr/hypridle.conf ;;
HYPRLAND) $TERMCMD -e nvim $HOME/.config/hypr/hyprland.conf ;;
HYPRLOCK) $TERMCMD -e nvim $HOME/.config/hypr/hyprlock.conf ;;
NEOVIM) $TERMCMD -e nvim $HOME/.config/nvim/init.lua ;;
WAYBAR) $TERMCMD -e nvim -p $HOME/.config/waybar/config.jsonc $HOME/.config/waybar/style.css ;;
esac
