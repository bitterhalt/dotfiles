#!/usr/bin/env bash

echo "Cloning dotfiles"
git clone https://codeberg.org/bt-halt/dotfiles.git "${HOME}/dotfiles"
sh ~/dotfiles/install.sh
