#!/bin/sh
# A dwm_bar function that shows the current artist, track, position, duration, and shuffle status
# from any MPRIS-compatible player using playerctl.
# GNU GPLv3

dwm_spotify () {
    # Get the list of available players
    players=$(playerctl -l 2>/dev/null)

    # Choose a player that is playing, if any; otherwise, use the first available player.
    chosen=""
    for player in $players; do
        status=$(playerctl -p "$player" status 2>/dev/null)
        if [ "$status" = "Playing" ]; then
            chosen="$player"
            break
        fi
    done
    if [ -z "$chosen" ] && [ -n "$players" ]; then
        chosen=$(echo "$players" | head -n1)
    fi

    # If no MPRIS-compatible player is found, exit
    if [ -z "$chosen" ]; then
        return
    fi

    # Retrieve metadata
    ARTIST=$(playerctl -p "$chosen" metadata artist 2>/dev/null)
    TRACK=$(playerctl -p "$chosen" metadata title 2>/dev/null)

    # Print "Artist - Song"
    echo "$ARTIST - $TRACK"
}

dwm_spotify

