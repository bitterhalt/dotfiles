#!/usr/bin/env bash

# Menu options
ARCHIVE="BASH
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
FOOT) exec $TERMCMD -e nvim "$HOME"/.config/foot/foot.ini ;;
FUZZEL) exec $TERMCMD sh -c "cd $HOME/.config/fuzzel && $OPENER ." ;;
HYPRLAND) exec $TERMCMD sh -c "cd $HOME/.config/hypr && $OPENER ." ;;
NEOVIM) exec $TERMCMD sh -c "cd $HOME/.config/nvim && $OPENER ." ;;
IGNIS) exec $TERMCMD sh -c "cd $HOME/.config/ignis && $OPENER ." ;;
esac
