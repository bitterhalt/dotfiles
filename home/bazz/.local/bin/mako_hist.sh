#!/usr/bin/env bash
makoctl history -j | jq -r ".[] | \"\(if .urgency == \"critical\" then \" ❗ \" else \" 🔔 \" end)[\(.app_name)] \(.summary) ➜ \(.body)\"" | fzf --no-info --layout reverse --border-label="Mako-history" --delimiter " ➜ " --preview "echo {2} | fmt -s" --preview-window=bottom:wrap
