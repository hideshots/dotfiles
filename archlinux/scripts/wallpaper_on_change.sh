#!/usr/bin/env bash
img="$1"
[ -f "$img" ] || exit 1

wal -n -s -i "$img" -q

pkill -USR1 -f kitty

if tmux has-session 2>/dev/null; then
  tmux source-file "${TMUX_CONF:-$HOME/.tmux.conf}"
  tmux refresh-client -S 2>/dev/null || true
fi
