#!/usr/bin/env bash
set -euo pipefail
LOCKFILE="${XDG_RUNTIME_DIR:-/tmp}/rotation.lock"

if [[ -e "$LOCKFILE" ]]; then
  rm -f "$LOCKFILE"
else
  : > "$LOCKFILE"
fi
