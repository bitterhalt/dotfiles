#!/usr/bin/env bash

id=$(hyprctl -j activeworkspace | jq ".id")

rid="r[$id-$id]"

gaps_in_current=$(hyprctl workspacerules -j | jq --arg rid "$rid" '[.[] | select(.workspaceString | startswith($rid)) | .gapsIn[0]] | .[0]')
gaps_out_current=$(hyprctl workspacerules -j | jq --arg rid "$rid" '[.[] | select(.workspaceString | startswith($rid)) | .gapsOut[0]] | .[0]')
rounding_current=$(hyprctl workspacerules -j | jq --arg rid "$rid" '[.[] | select(.workspaceString | startswith($rid)) | .rounding[0]] | .[0]')
border_size_current=$(hyprctl workspacerules -j | jq --arg rid "$rid" '[.[] | select(.workspaceString | startswith($rid)) | .borderSize[0]] | .[0]')

if [ "$gaps_in_current" = "null" ] && [ "$gaps_out_current" = "null" ] && [ "$rounding_current" = "null" ] && [ "$border_size_current" = "null" ]; then
  hyprctl keyword workspace "$rid" f[1], gapsin:0, gapsout:0, rounding:0, bordersize:1
  hyprctl keyword workspace "$rid" w[tv1], gapsin:0, gapsout:0, rounding:0, bordersize:1
  notify-send -t 1500 "Smart-gaps" "on"
  exit
fi

hyprctl reload
notify-send -t 1500 "Smart-gaps" "off"
