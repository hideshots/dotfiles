#!/usr/bin/env bash

STATE_FILE="/tmp/waybar_language_state"
THRESHOLD=1  # Time (in seconds) to show the flag after a language change

# Get active keymap names from hyprctl (for all keyboards)
# Using grep -qv ensures that if any keyboard is not "English (US)", we treat it as RU.
layouts=$(hyprctl devices | grep -A 5 "Keyboard" | grep "active keymap" | awk -F': ' '{print $2}')

if echo "$layouts" | grep -qv "English (US)"; then
    current="RU"
else
    current="US"
fi

current_time=$(date +%s)

# If the state file doesn't exist, initialize it with the current layout and timestamp.
if [ ! -f "$STATE_FILE" ]; then
    echo "$current $current_time" > "$STATE_FILE"
fi

# Read the stored language and timestamp from the state file.
read last_lang last_time < "$STATE_FILE"

# If the language has changed, update the state file with the new language and current time.
if [ "$current" != "$last_lang" ]; then
    echo "$current $current_time" > "$STATE_FILE"
    last_time=$current_time
fi

elapsed=$(( current_time - last_time ))

# For up to THRESHOLD seconds after a change, output the flag;
# after THRESHOLD seconds, output an empty string.
if [ $elapsed -le $THRESHOLD ]; then
    if [ "$current" = "RU" ]; then
        echo '{"text": "🇷🇺", "tooltip": "Russian layout"}'
    else
        echo '{"text": "🇺🇸", "tooltip": "English (US) layout"}'
    fi
else
    echo '{"text": ""}'
fi
