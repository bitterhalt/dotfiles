#!/usr/bin/env bash
# Run pending upgrades in a terminal. The Updates popup launches this through
# `$TERMINAL --app-id pop-upgrade -e`; it is also safe to run by hand.
#
# Every supported manager found on the system is upgraded. Prompts stay
# interactive, so builds and confirmations remain visible in the terminal.

set -u

failures=0

has() {
    command -v "$1" >/dev/null 2>&1
}

run_step() {
    if ! "$@"; then
        failures=$((failures + 1))
        echo "[x] $1 encountered an error." >&2
    fi
}

echo "[*] Beginning system upgrade..."

if has yay; then
    echo "[*] Updating via yay..."
    run_step yay -Syu
elif has paru; then
    echo "[*] Updating via paru..."
    run_step paru -Syu
elif has pacman; then
    echo "[*] Updating via pacman..."
    run_step sudo pacman -Syu
elif has apt-get; then
    echo "[*] Updating via apt..."
    run_step sudo apt-get update
    run_step sudo apt-get upgrade
elif has dnf; then
    echo "[*] Updating via dnf..."
    run_step sudo dnf upgrade
fi

if has snap; then
    echo "[*] Updating snap packages..."
    run_step sudo snap refresh
fi

if has flatpak; then
    echo "[*] Updating flatpak packages..."
    run_step flatpak update
fi

if has pipx; then
    echo "[*] Updating pipx packages..."
    run_step pipx upgrade-all
fi

echo
if ((failures > 0)); then
    echo "[x] $failures upgrade step(s) failed. Check the errors above."
else
    echo "[✓] Upgrade complete."
fi

if [[ -t 0 ]]; then
    read -r -p "Press Enter to close..." _
fi

exit $((failures > 0))
