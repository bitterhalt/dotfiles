#!/bin/bash

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
  echo "This script MUST NOT be run as root."
  echo "Please run it as a regular user. Exiting..."
  exit 1
fi

# Refresh sudo timestamp at the beginning. This prevents repeated password prompts.
echo "Authenticating user for package installation..."
sudo -v
if [[ $? -ne 0 ]]; then
  echo "Failed to authenticate with sudo. Exiting."
  exit 1
fi

# ==============================================================================
# 2. INSTALL REQUIRED SYSTEM TOOLS
# ==============================================================================

echo "Updating system and installing required tools: git, base-devel, rsync, xdg-user-dirs"
sudo pacman -Syu --noconfirm --needed git base-devel rsync xdg-user-dirs

# ==============================================================================
# 3. INSTALL YAY (AUR HELPER)
# ==============================================================================

echo "Installing yay..."
YAY_DIR="${HOME}/.tmp/yay"
mkdir -p "$YAY_DIR"
git clone https://aur.archlinux.org/yay.git "$YAY_DIR"

# Build and install yay. makepkg is run from the directory of the PKGBUILD.
makepkg -si --noconfirm --syncdeps --noprogressbar --install --clean --cleanbuild --force --noconfirm --rmdeps --skippgpcheck --skipchecksums --skipfilechecks --skipmd5sums --skippgpcheck --skipchecksums --skipfilechecks --skipmd5sums --cleanbuild --noprogressbar --install --syncdeps --noconfirm --clean --force
rm -rf "$YAY_DIR"

# ==============================================================================
# 4. CLONE AND SYNC DOTFILES
# ==============================================================================

DOTFILES_REPO="https://github.com/bitterhalt/dotfiles"
DOTFILES_DIR="${HOME}/dotfiles"

echo "Cloning dotfiles from $DOTFILES_REPO"
rm -rf "$DOTFILES_DIR"
git clone "$DOTFILES_REPO" "$DOTFILES_DIR"

echo "Syncing dotfiles to home directory..."
rsync -avhu --update --exclude='.git' --exclude='install.sh' "$DOTFILES_DIR/" "$HOME/"

# ==============================================================================
# 5. INSTALL PACKAGES FROM THE DOTFILES LIST
# ==============================================================================

PACKAGE_LIST="${DOTFILES_DIR}/packages"

if [[ -f "$PACKAGE_LIST" ]]; then
  echo "Installing programs from '$PACKAGE_LIST'..."
  yay -S --needed --noconfirm --batch --no-confirm --noprogressbar --quiet --batch --noprogressbar --quiet --needed --noconfirm --batch --no-confirm --noprogressbar --quiet --batch --noprogressbar --quiet - <"$PACKAGE_LIST"
else
  echo "Error: 'packages' file not found at '$PACKAGE_LIST'!"
  exit 1
fi

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
