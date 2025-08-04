#!/usr/bin/env bash

# Menu options
ARCHIVE="BASH
FNOTT
FOOT
FUZZEL
NEOVIM
SWAY
SWAYIDLE
WAYBAR
"
CHOICE=$(printf "$ARCHIVE" | fuzzel -d -a top --y 4 -w 30 -l 8 -p "Edit settings: ")

TERMCMD=("foot")

case $CHOICE in
BASH) $TERMCMD -e nvim $HOME/.bashrc ;;
FNOTT) $TERMCMD -e nvim $HOME/.config/fnott/fnott.ini ;;
FOOT) $TERMCMD -e nvim $HOME/.config/foot/foot.ini ;;
FUZZEL) $TERMCMD -e nvim $HOME/.config/fuzzel/fuzzel.ini ;;
NEOVIM) $TERMCMD -e nvim $HOME/.config/nvim/init.lua ;;
SWAY) $TERMCMD -e nvim $HOME/.config/sway/config ;;
SWAYIDLE) $TERMCMD -e nvim $HOME/.config/swayidle/config ;;
WAYBAR) $TERMCMD -e nvim $HOME/.config/sway/waybar/config-sway.jsonc ;;
esac
