#!/usr/bin/env bash

# ==============================================================================
# Arch Linux Post-Install Script
# This script automates my dotfiles installation
# ==============================================================================

set -e

# ==============================================================================
# 1. INITIAL CHECKS
# ==============================================================================

# Check if the script is run as root. Exit if it is.
if [[ $EUID -eq 0 ]]; then
  echo -e "This script MUST NOT be run as root.\nPlease run it as a regular user. Exiting..." >&2
  exit 1
fi

# Refresh sudo timestamp at the beginning. This prevents repeated password prompts.
echo "Authenticating user for package installation..."
sudo -v
if [[ $? -ne 0 ]]; then
  echo "Failed to authenticate with sudo. Exiting." >&2
  exit 1
fi

# ==============================================================================
# 2. INSTALL REQUIRED SYSTEM TOOLS
# ==============================================================================

echo "Updating system and installing required tools: git, base-devel, rsync, xdg-user-dirs"
sudo pacman -Syu --noconfirm --needed git base-devel rsync xdg-user-dirs || exit 1

# ==============================================================================
# 3. INSTALL YAY (AUR HELPER)
# ==============================================================================

helper="$(head -n 1 pkg.list)"
tmpdir="$(mktemp -d --tmpdir ${helper%%:*}-build-XXXXXX)"
trap 'rm -rf -- "$tmpdir"' EXIT # rm the tempdir if the script exits unexpectedly
echo "Installing ${helper%%:*}..."
git clone https://aur.archlinux.org/${helper##*:}.git "$tmpdir"
cd "$tmpdir" && makepkg -si --noconfirm
rm -rf -- "$tmpdir"

# ==============================================================================
# 4. SYNC DOTFILES
# ==============================================================================

cd ~/dotfiles
rsync -avhu home/bazz/ ~/
sleep 1 && clear

# ==============================================================================
# 5. INSTALL PACKAGES FROM THE DOTFILES LIST
# ==============================================================================

# Install packages
if [[ -f pkg.list ]]; then
  echo "Installing programs..."
  yay -S --needed $(tail pkg.list -n +2)
else
  echo "Error: './pkg.list' file not found!" >&2
  exit 1
fi
sleep 1 && clear

# ==============================================================================
# 6. PREPARE XDG USER FOLDERS
# ==============================================================================

echo "Updating XDG user directories..."
xdg-user-dirs-update

# ==============================================================================
# 7. FINAL INSTRUCTIONS
# ==============================================================================

echo "--------------------------------------------------------"
echo "Installation complete!"
echo "Please take the following steps to finalize your setup:"
echo "1. Log out and log back in for changes to take effect."
echo "2. Copy your greetd config to the system directory:"
echo "   sudo cp ${HOME}/dotfiles/etc/greetd/config.toml /etc/greetd/config.toml"
echo "3. Enable and start the greetd service:"
echo "   sudo systemctl enable --now greetd"
echo "--------------------------------------------------------"
