#!/usr/bin/env sh

ANIMS_ENABLED=$(hyprctl getoption animations:enabled | awk 'NR==1{print $2}')

if [ "$ANIMS_ENABLED" = "1" ]; then
    hyprctl --batch "keyword general:gaps_in 2; keyword general:gaps_out 0; keyword general:border_size 1; keyword decoration:rounding 3; keyword decoration:blur:enabled 1; keyword decoration:blur:size 0; keyword decoration:blur:passes 1; keyword decoration:blur:contrast 1.5; keyword decoration:blur:brightness 0; keyword decoration:fullscreen_opacity 1; keyword decoration:active_opacity 1; keyword decoration:inactive_opacity 1; keyword animations:enabled 0"
else
    hyprctl reload
fi
