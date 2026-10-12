# Nocturne engine build

The Stellarium Web Engine as served by Nocturne
(`nocturne.heimdall.masiul.is`) as the background sky of the
`*.heimdall.masiul.is` sites. Design record: `/srv/web/_system/DESIGN.md`
("The Sky") and ADRs 0001-0003 in `/srv/web/_system/docs/adr/`.

This repository is the upstream engine
(<https://github.com/Stellarium/stellarium-web-engine>, AGPL-3.0) with the
Heimdall patches on branch `heimdall`. It is the "corresponding source"
for the engine that Nocturne serves (AGPL-3.0 §13). Publish this
repository, including the patches and this recipe, before you link it
from the sites.

## Branches

- `master`: upstream, as cloned (upstream commit `15cd08a`).
- `heimdall`: upstream plus the patches below. Build from this branch.

## Patches

Run `git log master..heimdall` for the full list. In summary:

1. **Emscripten 4 build flags** (`SConstruct`): `EXPORTED_RUNTIME_METHODS`,
   `_malloc`/`_free` exported as functions, link-only flags removed from
   `CCFLAGS`.
2. **Tools run with `python3` from PATH** (`tools/*.py`).
3. **Adaptive render gate and DPR cap** (`src/js/canvas.js`, ADR 0002):
   ~12 fps when idle, full rate during a burst that the page requests
   through `canvas.__nocturne.burst`, no rendering on hidden tabs,
   devicePixelRatio capped at 2.
4. **Diagnostic pages** (`apps/simple-html/diag.html`, `gltest.html`).
5. **Sorted link order** (`SConstruct`): makes the `.wasm` file
   independent of the filesystem that holds the tree.

## Build the engine

Requirements: Nix with flakes. The toolchain is pinned in
`heimdall/flake.nix`: emscripten 4.0.12, scons 4.10.0, python 3.13.

```sh
heimdall/build.sh
```

The script runs `make js-es6` (`emscons scons mode=release es6=1`) in the
pinned dev shell, writes `build/stellarium-web-engine.{js,wasm}` and prints
their SHA-256 sums. The first build fills the emscripten cache in
`~/.cache/nocturne-emscripten` and takes longer.

## Make the sky data

```sh
heimdall/make-skydata.sh dist/skydata
```

The script copies the two data sets that the sky uses from the stock
`apps/test-skydata`:

- `stars/`: Hipparcos-derived star tiles (ESA)
- `surveys/milkyway/`: the Milky Way survey

Nocturne serves no other data.

## Deploy to Nocturne

The live files are in `/srv/web/nocturne/`:

| Built file | Live path |
|---|---|
| `build/stellarium-web-engine.js` | `/srv/web/nocturne/engine/stellarium-web-engine.js` |
| `build/stellarium-web-engine.wasm` | `/srv/web/nocturne/engine/stellarium-web-engine.wasm` |
| `dist/skydata/` | `/srv/web/nocturne/skydata/` |

The nginx vhost (`~/dotfiles/nginx/vhosts/nocturne.heimdall.masiul.is.conf`)
serves `/engine/` and `/skydata/` with
`Cache-Control: public, max-age=31536000, immutable`. Browsers do not
fetch a file again while its URL stays the same. If you replace a file
at the same URL, visitors keep the old copy for up to a year. Put each
new build at a new URL, or change the cache policy, before you deploy.

## Known issue: use-after-free on downloads (not fixed yet)

`src/utils/request_js.c` calls `emscripten_async_wget2_data(..., free=false, ...)`
and its `onload` keeps the downloaded buffer (`req->data = data`). The
Emscripten 4 glue ignores `free` and frees the buffer when `onload`
returns. The engine then reads freed memory, so tiles arrive corrupted
(`eph_load` errors at `eph-file.c` lines 112 and 122, "Cannot uncompress
data") and most stars do not render. The fix is to copy the data in
`onload`.
