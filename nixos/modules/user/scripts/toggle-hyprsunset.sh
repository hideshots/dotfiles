#!/usr/bin/env bash
temps=(5500 3500 2500 2000 1000)

state_file="$HOME/.cache/hyprsunset_cycle"

if [[ -r $state_file ]]; then
  prev_index=$(<"$state_file")
else
  prev_index=-1
fi

next_index=$(( (prev_index + 1) % ${#temps[@]} ))

mkdir -p "$(dirname "$state_file")"
echo "$next_index" > "$state_file"

hyprctl hyprsunset temperature "${temps[next_index]}"

