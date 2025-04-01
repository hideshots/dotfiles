#!/usr/bin/env bash
# Disable picom temporarily
pkill picom
sleep 0.2
# Take the screenshot using maim (selection mode) and pipe the output
maim -s | tee ~/Pictures/Screenshots/$(date +"%Y-%m-%d_%H-%M-%S").png | xclip -selection clipboard -t image/png
# Restart picom in the background
picom --config ~/.config/picom.conf -b
