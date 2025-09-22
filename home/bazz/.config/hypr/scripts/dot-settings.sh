#!/usr/bin/env bash

# Menu options
ARCHIVE="BASH
FNOTT
FOOT
FUZZEL
HYPRLAND
NEOVIM
WAYBAR
"
CHOICE=$(printf "$ARCHIVE" | fuzzel -d --minimal-lines -a top --y 4 -w 30 -p "" --placeholder "Edit settings: ")

TERMCMD=("foot")

case $CHOICE in
BASH) $TERMCMD -e nvim $HOME/.bashrc ;;
FNOTT) $TERMCMD -e nvim $HOME/.config/fnott/fnott.ini ;;
FOOT) $TERMCMD -e nvim $HOME/.config/foot/foot.ini ;;
FUZZEL) $TERMCMD -e nvim $HOME/.config/fuzzel/fuzzel.ini ;;
HYPRLAND) $TERMCMD -e nvim $HOME/.config/hypr/hyprland.conf $HOME/.config/hypr/hyprlock.conf $HOME/.config/hypr/hypridle.conf ;;
NEOVIM) $TERMCMD -e nvim $HOME/.config/nvim/init.lua ;;
WAYBAR) $TERMCMD -e nvim $HOME/.config/hypr/waybar/config.jsonc $HOME/.config/hypr/waybar/style.css ;;
esac
