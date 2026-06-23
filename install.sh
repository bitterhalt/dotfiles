#!/usr/bin/env bash

set -e

# ==============================================================================
# 1. INITIAL CHECKS
# ==============================================================================

if [[ $EUID -eq 0 ]]; then
  echo -e "This script MUST NOT be run as root.\nPlease run it as a regular user. Exiting..." >&2
  exit 1
fi

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
# 3. SET UP CHAOTIC-AUR & INSTALL YAY
# ==============================================================================

echo "Setting up Chaotic-AUR repository..."

sudo pacman-key --recv-key 3056513887B78AEB --keyserver keyserver.ubuntu.com
sudo pacman-key --lsign-key 3056513887B78AEB

sudo pacman -U --noconfirm 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst'
sudo pacman -U --noconfirm 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst'

if ! grep -q "\[chaotic-aur\]" /etc/pacman.conf; then
  echo "Appending Chaotic-AUR to /etc/pacman.conf..."
  sudo bash -c 'cat << EOF >> /etc/pacman.conf

[chaotic-aur]
Include = /etc/pacman.d/chaotic-mirrorlist
EOF'
fi

echo "Syncing databases and installing yay directly from Chaotic-AUR..."
sudo pacman -Sy --noconfirm
sudo pacman -S --noconfirm --needed yay

# ==============================================================================
# 4. SYNC DOTFILES
# ==============================================================================

cd ~/dotfiles
rsync -avhu home/ ~/
sleep 1 && clear
cd $OLDPWD

# ==============================================================================
# 5. INSTALL PACKAGES FROM THE DOTFILES LIST
# ==============================================================================

if [[ -f pkg.list ]]; then
  echo "Installing programs..."
  # Skip line 1 if it only listed the 'yay:yay-bin' placeholder, otherwise processes the rest
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

echo "Generating color scheme..."
wal -i "$HOME"/share/wall/wallpaper.png -n

# ==============================================================================
# 7. FINAL INSTRUCTIONS
# ==============================================================================

echo "--------------------------------------------------------"
echo "Installation complete!"
echo "Please take the following steps to finalize your setup:"
echo "1. Copy contents of dotfiles/etc/greetd inside your /etc/greetd/"
echo "2. Enable greetd $(sudo systemctl enable greetd.service)"
echo "3. Reboot and log in"
echo "4. If your don't want greetd, just type $(niri-session) in tty"
echo "--------------------------------------------------------"
