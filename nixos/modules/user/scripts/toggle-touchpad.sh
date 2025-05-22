#!/usr/bin/env bash

DEV="synps/2-synaptics-touchpad"

STATE_FILE="$HOME/.cache/touchpad_state"

[ ! -f "$STATE_FILE" ] && echo "true" > "$STATE_FILE"

CURRENT=$(cat "$STATE_FILE")

if [ "$CURRENT" = "true" ]; then
  hyprctl keyword "device[$DEV]:enabled" "false"
  echo "false" > "$STATE_FILE"
  notify-send "Touchpad disabled" \
              "Your touchpad has been turned off." \
              --icon=input-touchpad
else
  hyprctl keyword "device[$DEV]:enabled" "true"
  echo "true" > "$STATE_FILE"
  notify-send "Touchpad enabled" \
              "Your touchpad is now active." \
              --icon=input-touchpad
fi
