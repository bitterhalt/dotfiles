#!/usr/bin/env bash

echo "Cloning dotfiles"
git clone https://github.com/bitterhalt/dotfiles.git "${HOME}/dotfiles"
sh ~/dotfiles/install.sh
