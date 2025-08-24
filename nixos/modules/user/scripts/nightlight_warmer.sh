#!/bin/sh

STATE="$HOME/.cache/current_temp"
DEFAULT_TEMP=5500
STEP=200

# Load current temperature or use default
[ -f "$STATE" ] && TEMP=$(cat "$STATE") || TEMP=$DEFAULT_TEMP

# Decrease temperature (warmer)
TEMP=$((TEMP - STEP))
[ "$TEMP" -lt 1000 ] && TEMP=1000  # Don't go too low

# Save and apply
echo "$TEMP" > "$STATE"
redshift -P -O "$TEMP"
