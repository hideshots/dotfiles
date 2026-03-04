#!/usr/bin/env bash
set -euo pipefail

# Normalize Apple CoreSVG rgba() color attributes into Qt-friendly forms.
# Rewrites:
#   stop-color="rgba(r,g,b,a)"  -> stop-color="#RRGGBB" stop-opacity="a"
#   fill="rgba(r,g,b,a)"        -> fill="#RRGGBB" fill-opacity="a"
#   stroke="rgba(r,g,b,a)"      -> stroke="#RRGGBB" stroke-opacity="a"
#
# Usage:
#   ./assets/svg/normalize-coresvg.sh
#   ./assets/svg/normalize-coresvg.sh /path/to/svg/dir

target_dir="${1:-assets/svg}"

if [[ ! -d "$target_dir" ]]; then
    echo "Directory not found: $target_dir" >&2
    exit 1
fi

export TARGET_DIR="$target_dir"

python3 - <<'PY'
import os
import re
from pathlib import Path

target_dir = Path(os.environ["TARGET_DIR"])
svg_files = sorted(target_dir.glob("*.svg"))

rgba_re = re.compile(
    r'(?P<attr>stop-color|fill|stroke)="rgba\(\s*'
    r'(?P<r>\d{1,3})\s*,\s*'
    r'(?P<g>\d{1,3})\s*,\s*'
    r'(?P<b>\d{1,3})\s*,\s*'
    r'(?P<a>(?:\d+(?:\.\d+)?)|(?:\.\d+))\s*\)"'
    r'(?:\s+(?P<opacity_attr>stop-opacity|fill-opacity|stroke-opacity)="(?P<opacity>(?:\d+(?:\.\d+)?)|(?:\.\d+))")?'
)

opacity_attr_by_color_attr = {
    "stop-color": "stop-opacity",
    "fill": "fill-opacity",
    "stroke": "stroke-opacity",
}

changed = 0
for path in svg_files:
    src = path.read_text(encoding="utf-8")

    def repl(match: re.Match[str]) -> str:
        attr = match.group("attr")
        r = max(0, min(255, int(match.group("r"))))
        g = max(0, min(255, int(match.group("g"))))
        b = max(0, min(255, int(match.group("b"))))
        a = float(match.group("a"))
        a = max(0.0, min(1.0, a))
        existing_opacity = match.group("opacity")
        if existing_opacity is not None:
            try:
                existing = float(existing_opacity)
                existing = max(0.0, min(1.0, existing))
                a *= existing
            except ValueError:
                pass
        hex_color = f"#{r:02X}{g:02X}{b:02X}"
        opacity_attr = opacity_attr_by_color_attr[attr]
        return f'{attr}="{hex_color}" {opacity_attr}="{a:.4g}"'

    dst = rgba_re.sub(repl, src)

    # Cleanup duplicate opacity attributes, preserving the first (already-normalized) value.
    dst = re.sub(
        r'(stop-opacity="[^"]*")\s+stop-opacity="[^"]*"',
        r'\1',
        dst,
    )
    dst = re.sub(
        r'(fill-opacity="[^"]*")\s+fill-opacity="[^"]*"',
        r'\1',
        dst,
    )
    dst = re.sub(
        r'(stroke-opacity="[^"]*")\s+stroke-opacity="[^"]*"',
        r'\1',
        dst,
    )
    if dst != src:
        path.write_text(dst, encoding="utf-8")
        changed += 1

print(f"Normalized {changed} file(s) in {target_dir}")
PY
