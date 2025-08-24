#!/bin/sh

STATE="$HOME/.cache/current_temp"
DEFAULT_TEMP=3500
STEP=200

[ -f "$STATE" ] && TEMP=$(cat "$STATE") || TEMP=$DEFAULT_TEMP

# Increase temperature (cooler)
TEMP=$((TEMP + STEP))
[ "$TEMP" -gt 6500 ] && TEMP=6500  # Max out at 6500K (neutral daylight)

echo "$TEMP" > "$STATE"
redshift -P -O "$TEMP"
