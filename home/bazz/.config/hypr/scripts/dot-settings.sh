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
BASH) exec $TERMCMD -e nvim $HOME/.bashrc ;;
FNOTT) exec $TERMCMD -e nvim $HOME/.config/fnott/fnott.ini ;;
FOOT) exec $TERMCMD -e nvim $HOME/.config/foot/foot.ini ;;
FUZZEL) exec $TERMCMD -e nvim $HOME/.config/fuzzel/fuzzel.ini ;;
HYPRLAND) exec $TERMCMD -e nvim $HOME/.config/hypr/hyprland.conf $HOME/.config/hypr/hyprlock.conf $HOME/.config/hypr/hypridle.conf ;;
NEOVIM) exec $TERMCMD -e nvim $HOME/.config/nvim/init.lua ;;
WAYBAR) exec $TERMCMD -e nvim $HOME/.config/hypr/waybar/config.jsonc $HOME/.config/hypr/waybar/style.css ;;
esac
