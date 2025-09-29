#!/usr/bin/env bash

# Menu options
ARCHIVE="BASH
FNOTT
FOOT
FUZZEL
NEOVIM
SWAY
WAYBAR
"
CHOICE=$(printf "$ARCHIVE" | fuzzel -d -a top --y 4 -w 30 --minimal-lines -p "Edit settings: ")

TERMCMD=("foot")

case $CHOICE in
BASH) exec $TERMCMD -e nvim $HOME/.bashrc ;;
FNOTT) exec $TERMCMD -e nvim $HOME/.config/fnott/fnott.ini ;;
FOOT) exec $TERMCMD -e nvim $HOME/.config/foot/foot.ini ;;
FUZZEL) exec $TERMCMD -e nvim $HOME/.config/fuzzel/fuzzel.ini ;;
NEOVIM) exec $TERMCMD -e nvim $HOME/.config/nvim/init.lua ;;
SWAY) exec $TERMCMD -e nvim $HOME/.config/sway/config ;;
WAYBAR) exec $TERMCMD -e nvim $HOME/.config/sway/waybar/config.jsonc $HOME/.config/sway/waybar/style.css ;;
esac
