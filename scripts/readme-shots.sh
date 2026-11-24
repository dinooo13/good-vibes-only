#!/bin/bash
# Renders the README's screenshots from the demo pages in assets/src, in light
# and dark, at 2x. Needs a Chromium: set CHROME, or install Playwright's
# (npx playwright install chromium-headless-shell).
#
# Usage: scripts/readme-shots.sh
set -euo pipefail

ROOT=$(cd "$(dirname "$0")/.." && pwd)
CHROME=${CHROME:-$(find "$HOME/Library/Caches/ms-playwright" "$HOME/.cache/ms-playwright" \
  -type f -name chrome-headless-shell 2>/dev/null | sort | tail -1 || true)}
[ -x "$CHROME" ] || { echo "No Chromium found; set CHROME" >&2; exit 1; }

# name  width  height (CSS pixels; the height fits the page)
while read -r name width height; do
  for mode in light dark; do
    "$CHROME" --headless --hide-scrollbars --force-device-scale-factor=2 \
      --window-size="$width,$height" --screenshot="$ROOT/assets/$name-$mode.png" \
      "file://$ROOT/assets/src/$name-demo.html#$mode" 2>/dev/null
    echo "assets/$name-$mode.png"
  done
done <<'SHOTS'
project-digest 820 1092
SHOTS
