#!/bin/bash

# Replace 'spotify' with your actual player name from 'playerctl -l'
PLAYER="spotify"  # or firefox, vlc, etc.

# Clear the file initially
echo "" > /tmp/now_playing

# Use playerctl --follow with specific player
playerctl -p "$PLAYER" metadata --format "{{ artist }} - {{ title }}" --follow 2>/dev/null | while read -r line; do
    if [ -n "$line" ]; then
        echo "$line" > /tmp/now_playing
    else
        echo "" > /tmp/now_playing
    fi
done

