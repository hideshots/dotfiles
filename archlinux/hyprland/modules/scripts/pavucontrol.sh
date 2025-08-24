#r!/bin/bash

special_workspace=$(hyprctl monitors -j | jq -r '.[] | select(.focused == true) | .specialWorkspace.name')

if [[ "$special_workspace" == "special:pavucontrol" ]]; then
    hyprctl dispatch togglespecialworkspace pavucontrol
    sleep 0.3
    pkill -x pavucontrol 2>/dev/null
else
    hyprctl dispatch togglespecialworkspace pavucontrol
fi
