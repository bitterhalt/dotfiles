#!/usr/bin/env bash

makoctl history -j | jq -r ".[] | \"[\(.app_name)] \(.summary) ➜ \(.body)\"" | fzf --layout reverse --border-label="Mako-history" --delimiter " ➜ " --preview "echo {2} | fmt -s" --preview-window=bottom:wrap
