#!/usr/bin/env bash
set -euo pipefail

OUTPUT="${1:-eDP-1}"
LOCKFILE="${XDG_RUNTIME_DIR:-/tmp}/rotation.lock"

monitor-sensor --accel | \
  awk '/Accelerometer orientation changed:/ {print $NF; fflush();}' | \
  while read -r o; do
    [[ -e "$LOCKFILE" ]] && continue
    case "$o" in
      normal)    t=0 ;;
      bottom-up) t=180 ;;
      right-up)  t=90 ;;
      left-up)   t=270 ;;
      *) continue ;;
    esac
    swaymsg output "$OUTPUT" transform "$t" >/dev/null
  done
