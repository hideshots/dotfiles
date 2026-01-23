#!/bin/bash
# File to store current state
STATE_FILE="$HOME/.cache/hyprland_performance_mode"

if [[ -f "$STATE_FILE" ]]; then
    hyprctl reload
    rm "$STATE_FILE"
else
    hyprctl --batch "
        keyword animations:enabled false;
        keyword decoration:rounding 11;
        keyword general:gaps_in 2;
        keyword general:gaps_out 5;
    "
    touch "$STATE_FILE"
fi
