#!/usr/bin/env bash

# Menu options
ARCHIVE="BASH
FNOTT
FOOT
FUZZEL
HYPRLAND
IGNIS
NEOVIM
"
CHOICE=$(printf "$ARCHIVE" | fuzzel -d --minimal-lines -a top --y 4 -w 30 -p "" --placeholder "Edit settings: ")
TERMCMD=("foot")
OPENER=("vopen")

case $CHOICE in
BASH) exec $TERMCMD -e nvim "$HOME"/.bashrc ;;
FNOTT) exec $TERMCMD -e nvim "$HOME"/.config/fnott/fnott.ini ;;
FOOT) exec $TERMCMD -e nvim "$HOME"/.config/foot/foot.ini ;;
FUZZEL) exec $TERMCMD -e nvim "$HOME"/.config/fuzzel/fuzzel.ini ;;
HYPRLAND) exec $TERMCMD -e $OPENER "$HOME"/.config/hypr/ ;;
NEOVIM) exec $TERMCMD -e $OPENER "$HOME"/.config/nvim/ ;;
IGNIS) exec $TERMCMD -e $OPENER "$HOME"/.config/ignis/ ;;
esac
