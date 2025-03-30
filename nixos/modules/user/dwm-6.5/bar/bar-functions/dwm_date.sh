#!/bin/sh

# A dwm_bar function that shows the current date and time
# GNU GPLv3

# Date is formatted like this: "Mon Mar 1 12:54 AM"
dwm_date () {
    printf "%s" "$SEP1"
    if [ "$IDENTIFIER" = "unicode" ]; then
        printf "%s" "$(date "+%a %b %-d %I:%M %p")"
    else
        printf "DAT %s" "$(date "+%a %b %-d %I:%M %p")"
    fi
    printf "%s\n" "$SEP2"
}

dwm_date
