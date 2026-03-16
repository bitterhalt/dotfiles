#!/usr/bin/env bash

# Find all common image formats in current and subdirectories
find . -type f -iregex '.*\.\(jpg\|jpeg\|png\|gif\|bmp\|webp\)' |
  fzf --preview 'chafa -f sixel -s ${FZF_PREVIEW_COLUMNS}x${FZF_PREVIEW_LINES} {}' \
    --preview-window='right:60%:noborder' \
    --header 'Crtl-C to exit | Enter to select'
