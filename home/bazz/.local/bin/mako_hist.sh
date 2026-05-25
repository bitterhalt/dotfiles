makoctl history -j |
  jq -r '
      .[] | (
        if .urgency == "critical"
        then " ❗ "
        else " 🔔 "
        end
      ) + "[\(.app_name)] \(.summary)\(
        if (.body // "") != ""
        then " ➜ \(.body)"
        else ""
        end
      )"
    ' |
  fzf \
    --no-info \
    --layout reverse \
    --border-label "Mako-history" \
    --delimiter " ➜ " \
    --preview "echo {2} | fmt -s" \
    --preview-window bottom:wrap
