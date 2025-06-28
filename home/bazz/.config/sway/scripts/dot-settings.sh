#!/usr/bin/env bash

# Menu options
ARCHIVE="SWAY
FOOT
FNOTT
FUZZEL
WAYBAR
BASH
NEOVIM
"
CHOICE=$(printf "$ARCHIVE" | fuzzel -d -a top --y 4 -w 30 -l 7 -p "Edit settings: ")

TERMCMD=("foot")

case $CHOICE in
BASH) $TERMCMD -e nvim $HOME/.bashrc ;;
FNOTT) $TERMCMD -e nvim $HOME/.config/fnott/fnott.ini ;;
FOOT) $TERMCMD -e nvim $HOME/.config/foot/foot.ini ;;
FUZZEL) $TERMCMD -e nvim $HOME/.config/fuzzel/fuzzel.ini ;;
NEOVIM) $TERMCMD -e nvim $HOME/.config/nvim/init.lua ;;
SWAY) $TERMCMD -e nvim $HOME/.config/sway/config ;;
WAYBAR) $TERMCMD -e nvim -p $HOME/.config/waybar/config.jsonc $HOME/.config/waybar/style.css ;;
esac
