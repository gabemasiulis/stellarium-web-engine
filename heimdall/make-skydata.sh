#!/usr/bin/env bash
# Assemble the Nocturne sky data from the engine's stock test sky data:
# stars (Hipparcos-derived, ESA) and the Milky Way survey only.
# Usage: heimdall/make-skydata.sh <out-dir>    e.g. dist/skydata
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
src="$here/../apps/test-skydata"
out="${1:?usage: make-skydata.sh <out-dir>}"
mkdir -p "$out/surveys"
rsync -a --delete "$src/stars/" "$out/stars/"
rsync -a --delete "$src/surveys/milkyway/" "$out/surveys/milkyway/"
echo "sky data written to $out"
