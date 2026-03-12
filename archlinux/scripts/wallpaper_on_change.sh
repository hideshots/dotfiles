#!/usr/bin/env bash
img="$1"
[ -n "$img" ] || exit 1

img="$(realpath -e -- "$img")" || exit 1

wallpaper_state_dir="${XDG_CACHE_HOME:-$HOME/.cache}/quickshell"
wallpaper_state_file="$wallpaper_state_dir/wallpaper"
sddm_wallpaper_file="/var/tmp/sddm-wallpaper.png"

mkdir -p "$wallpaper_state_dir"

tmp_state_file="$(mktemp "$wallpaper_state_file.tmp.XXXXXX")" || exit 1
printf '%s\n' "$img" > "$tmp_state_file" || {
  rm -f "$tmp_state_file"
  exit 1
}
mv -f "$tmp_state_file" "$wallpaper_state_file" || {
  rm -f "$tmp_state_file"
  exit 1
}

tmp_sddm_file="$(mktemp "${sddm_wallpaper_file}.tmp.XXXXXX")" || exit 1
cp -f -- "$img" "$tmp_sddm_file" || {
  rm -f "$tmp_sddm_file"
  exit 1
}
chmod 0644 "$tmp_sddm_file" || {
  rm -f "$tmp_sddm_file"
  exit 1
}
mv -f "$tmp_sddm_file" "$sddm_wallpaper_file" || {
  rm -f "$tmp_sddm_file"
  exit 1
}

wal -n -s -i "$img" -q

pkill -USR1 -f kitty

if tmux has-session 2>/dev/null; then
  tmux source-file "${TMUX_CONF:-$HOME/.tmux.conf}"
  tmux refresh-client -S 2>/dev/null || true
fi
