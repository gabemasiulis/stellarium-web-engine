#!/usr/bin/env bash
# Build the engine (ES6 module, release) with the pinned toolchain.
# Output: build/stellarium-web-engine.{js,wasm}
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
cd "$here/.."
nix develop "$here" --command make js-es6
sha256sum build/stellarium-web-engine.js build/stellarium-web-engine.wasm
