#!/usr/bin/env bash
# Toggles microphone mute and plays a sound on mute/unmute
# Requires: pactl, paplay

MUTE_SOUND="$HOME/dotfiles/archlinux/scripts/assets/disable.caf"
UNMUTE_SOUND="$HOME/dotfiles/archlinux/scripts/assets/enable.caf"

pactl set-source-mute @DEFAULT_SOURCE@ toggle
sleep 0.1

MUTE_STATE=$(pactl get-source-mute @DEFAULT_SOURCE@ | awk '{ print $2 }')

if [[ "$MUTE_STATE" == "yes" ]]; then
  # Muted
  if [[ -f "$MUTE_SOUND" ]]; then
    paplay "$MUTE_SOUND" &
    notify-send -i audio-input-microphone "Microphone" "Muted" -t 2000
  fi
else
  # Unmuted
  if [[ -f "$UNMUTE_SOUND" ]]; then
    paplay "$UNMUTE_SOUND" &
    notify-send -i audio-input-microphone "Microphone" "Unmuted" -t 2000
  fi
fi
