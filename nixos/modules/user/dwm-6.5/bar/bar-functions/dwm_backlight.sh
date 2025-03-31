#!/bin/sh

# A dwm_bar module to display the current backlight brightness with brightnessctl
# GNU GPLv3

# Dependencies: brightnessctl

dwm_backlight () {
    brightness=$(brightnessctl -m | awk -F, '{print substr($4, 1, length($4)-1)}')
    if [ -n "$brightness" ]; then
        printf "%s☀ %s%%%s\n" "$SEP1" "$brightness" "$SEP2"
    fi
}

dwm_backlight
