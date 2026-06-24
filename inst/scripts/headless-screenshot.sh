#!/usr/bin/env bash
# Capture a headless-browser screenshot of a running Shiny app.
#
# Usage:
#   ./headless-screenshot.sh [url] [output.png] [width] [height]
#
# Example (app must already be running):
#   ./headless-screenshot.sh http://127.0.0.1:3847 screenshot.png 1400 1100

set -euo pipefail

URL="${1:-http://127.0.0.1:3847}"
OUT="${2:-screenshot.png}"
WIDTH="${3:-1400}"
HEIGHT="${4:-1100}"
WAIT_MS="${5:-8000}"

CHROME="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
if [[ ! -x "$CHROME" ]]; then
  CHROME="$(command -v google-chrome || command -v chromium || true)"
fi
if [[ -z "$CHROME" || ! -x "$CHROME" ]]; then
  echo "Error: Chrome/Chromium not found." >&2
  exit 1
fi

echo "Waiting for app at $URL ..."
for i in $(seq 1 30); do
  if curl -sf "$URL" >/dev/null 2>&1; then
    break
  fi
  sleep 1
  if [[ $i -eq 30 ]]; then
    echo "Error: app not reachable at $URL" >&2
    exit 1
  fi
done

echo "Capturing screenshot -> $OUT"
"$CHROME" \
  --headless=new \
  --disable-gpu \
  --no-sandbox \
  --hide-scrollbars \
  --window-size="${WIDTH},${HEIGHT}" \
  --virtual-time-budget="$WAIT_MS" \
  --run-all-compositor-stages-before-draw \
  --screenshot="$OUT" \
  "$URL" \
  >/dev/null 2>&1

echo "Done: $OUT ($(wc -c < "$OUT" | tr -d ' ') bytes)"