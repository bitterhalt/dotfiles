#!/bin/bash
workspace=$(hyprctl activeworkspace -j | jq -r '.name // .id')
notify-send -t 1500 -h string:x-canonical-private-synchronous:notification "󰍹 Workspace: $workspace"
