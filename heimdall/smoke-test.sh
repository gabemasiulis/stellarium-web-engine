#!/usr/bin/env bash
# Boot build/stellarium-web-engine.* in headless Chromium with the sky data,
# print the console output and save a screenshot. Pass: no "Error" lines
# and a visible star field in the screenshot.
# Usage: heimdall/smoke-test.sh [screenshot.png]
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
repo="$here/.."
shot="$(realpath -m "${1:-smoke.png}")"
work="$(mktemp -d)"
trap 'kill "${srv:-}" 2>/dev/null || true; rm -rf "$work"' EXIT

mkdir -p "$work/site/engine"
cp "$repo"/build/stellarium-web-engine.{js,wasm} "$work/site/engine/"
cp "$here/smoke/index.html" "$work/site/"
"$here/make-skydata.sh" "$work/site/skydata" >/dev/null

python3 -I "$here/smoke/serve.py" "$work/site" & srv=$!
sleep 1
nix shell nixpkgs#chromium --command chromium --headless=new --no-sandbox \
  --user-data-dir="$work/profile" --use-angle=swiftshader --enable-unsafe-swiftshader \
  --enable-logging=stderr --v=0 --window-size=1280,720 \
  --screenshot="$shot" "http://127.0.0.1:8765/index.html" 2>"$work/log" >/dev/null
grep -o 'CONSOLE.*' "$work/log" | sed -E 's/, source:.*//; s/^CONSOLE:[0-9]+\] //' | sort | uniq -c
echo "screenshot: $shot"
! grep 'CONSOLE' "$work/log" | grep -q 'Error'
