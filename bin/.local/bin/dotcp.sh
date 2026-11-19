#!/usr/bin/env bash

# Paths
dotfiles_repo="/home/bazz/Documents/projects/dotfiles"
dotlist_path="/home/bazz/.local/share/dotlist"

if [[ ! -f "$dotlist_path" ]]; then
  echo "Error: Dotlist not found at $dotlist_path"
  exit 1
fi

cd "$dotfiles_repo" || {
  echo "Error: Failed to change directory to $dotfiles_repo"
  exit 1
}

echo "[*] Starting migration from dotlist..."

while IFS= read -r dotfile || [[ -n "$dotfile" ]]; do
  # Skip empty lines and comments
  [[ -z "$dotfile" || "$dotfile" =~ ^[[:space:]]*# ]] && continue

  # Ignore /etc/* and /usr paths as requested
  if [[ "$dotfile" =~ ^/etc/ ]] || [[ "$dotfile" =~ ^/usr/ ]]; then
    echo "[skip] Ignoring system path: $dotfile"
    continue
  fi

  if [[ -e "$dotfile" ]]; then
    # Use rsync with --relative to preserve the full directory tree inside the repo
    if rsync -a --relative "$dotfile" "$dotfiles_repo"/; then
      echo "[✓] Copied: $dotfile"
    else
      echo "[x] Failed to copy: $dotfile"
    fi
  else
    echo "[!] Warning: Path does not exist locally: $dotfile"
  fi
done <"$dotlist_path"

echo "[✓] Migration sync complete."
