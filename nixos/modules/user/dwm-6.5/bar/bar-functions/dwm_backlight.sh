#!/bin/sh

# A dwm_bar module to display the current backlight brightness with xbacklight
# GNU GPLv3

# Dependencies: xbacklight

dwm_backlight () {
    brightness=$(xbacklight 2>/dev/null)
    if [ -n "$brightness" ]; then
        printf "%s☀ %.0f%s\n" "$SEP1" "$brightness" "$SEP2"
    fi
}

dwm_backlight

