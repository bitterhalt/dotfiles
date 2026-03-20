#!/bin/bash

STEP=5
STATE_FILE_PREFIX=~/.cache/brightness

# Get monitor name - either from argument, env var, or focused monitor
get_monitor_name() {
  if [ -n "$1" ]; then
    echo "$1"
  elif [ -n "$WAYBAR_OUTPUT_NAME" ]; then
    echo "$WAYBAR_OUTPUT_NAME"
  else
    hyprctl monitors -j | jq -r '.[] | select(.focused == true) | .name'
  fi
}

# Get ddcutil display number for a monitor
get_ddcutil_display() {
  local monitor_name="$1"
  case "$monitor_name" in
  "DP-1")
    echo "1" # LG ULTRAWIDE - ADJUST THIS FOR YOUR SETUP
    ;;
  # Add more monitors here as needed:
  # "DP-4")
  #     echo "2"
  #     ;;
  *)
    echo "" # No DDC/CI support
    ;;
  esac
}

# Get state file for this monitor
get_state_file() {
  local monitor="$1"
  echo "${STATE_FILE_PREFIX}_${monitor}.tmp"
}

# Function to send DDC/CI command in background
set_brightness_ddcutil() {
  local display_num="$1"
  local brightness="$2"
  pkill -f "ddcutil.*setvcp 10"
  (ddcutil --display "$display_num" setvcp 10 "$brightness") &
}

# Function to set laptop brightness
set_brightness_laptop() {
  local brightness="$1"
  brightnessctl set "${brightness}%" >/dev/null 2>&1
}

# Get current brightness for a specific monitor
get_current_brightness() {
  local monitor="$1"
  local state_file=$(get_state_file "$monitor")
  local display_num=$(get_ddcutil_display "$monitor")

  if [ "$monitor" = "eDP-1" ]; then
    # Laptop display
    if [ ! -f "$state_file" ]; then
      local current=$(brightnessctl get 2>/dev/null || echo "0")
      local max=$(brightnessctl max 2>/dev/null || echo "1")
      local percent=$((current * 100 / max))
      echo "$percent" >"$state_file"
    fi
    cat "$state_file"
  elif [ -n "$display_num" ]; then
    # External monitor with DDC/CI
    if [ ! -f "$state_file" ]; then
      local brightness=$(ddcutil --display "$display_num" getvcp 10 -t 2>/dev/null | awk '{print $4}' || echo "100")
      echo "$brightness" >"$state_file"
    fi
    cat "$state_file"
  else
    echo "?"
  fi
}

# Set brightness for a specific monitor
set_brightness() {
  local monitor="$1"
  local new_brightness="$2"
  local state_file=$(get_state_file "$monitor")
  local display_num=$(get_ddcutil_display "$monitor")

  if [ "$monitor" = "eDP-1" ]; then
    # Laptop display
    echo "$new_brightness" >"$state_file"
    set_brightness_laptop "$new_brightness"
  elif [ -n "$display_num" ]; then
    # External monitor with DDC/CI
    echo "$new_brightness" >"$state_file"
    set_brightness_ddcutil "$display_num" "$new_brightness"
  else
    # Unsupported monitor
    return
  fi

}

COMMAND="$1"
MONITOR=$(get_monitor_name "$2")
current=$(get_current_brightness "$MONITOR")

case "$COMMAND" in
"get")
  echo " $current"
  ;;
"up")
  if [ "$current" = "?" ]; then
    echo " N/A"
  else
    new_brightness=$((current + STEP > 100 ? 100 : current + STEP))
    if [ "$current" -ne "$new_brightness" ]; then
      set_brightness "$MONITOR" "$new_brightness"
    fi
  fi
  ;;
"down")
  if [ "$current" = "?" ]; then
    echo " N/A"
  else
    new_brightness=$((current - STEP < 0 ? 0 : current - STEP))
    if [ "$current" -ne "$new_brightness" ]; then
      set_brightness "$MONITOR" "$new_brightness"
    fi
  fi
  ;;
"right_click")
  if [ "$current" != "?" ]; then
    new_brightness=0
    set_brightness "$MONITOR" "$new_brightness"
  fi
  ;;
"left_click")
  if [ "$current" != "?" ]; then
    new_brightness=100
    set_brightness "$MONITOR" "$new_brightness"
  fi
  ;;
esac
