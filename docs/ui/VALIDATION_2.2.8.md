# Colosseum Inspired UI Overhaul 2.2.8 validation

## Baseline
- Built directly from packaged UI 2.2.7.
- Scope: PC ACCESS focus geometry plus PC CBE information-model cache/animation/orbit behavior.

## Static validation
- PASS: `main.lua` parses successfully under texlua `loadfile()`.
- PASS: `manifest.json` parses and reports version 2.2.8.
- PASS: all 536 runtime assets are byte-identical to 2.2.7.
- PASS: hook/event/`src.*` require marker counts are unchanged from 2.2.7 (15 / 8 / 69 by the same static probe).
- PASS: only `main.lua`, `manifest.json`, and this release's note/validation metadata are changed/added.

## PC focus correction
- PASS: PC ACCESS selected rows use measured active-font height through `drawPCTextSelectionRail()` instead of fixed `yy-3, h=10` geometry.
- PASS: the focus rail remains inside the existing row width and does not change menu input/index behavior.

## CBE PC showroom correction
- PASS: PC remains CBE-specific 3D when Colosseum Pokémon Models are enabled, with exact 2D fallback otherwise.
- PASS: dedicated `drawPcInformationPortrait()` uses the same `drawStadiumUiModel()` actor renderer and mouse/touch orbit path as Summary/Pokédex.
- PASS: PC actor LRU is bounded at 12 entries.
- PASS: resident-provider `peek` + `acquireCached` fast path is consumed when exposed by CBE.
- PASS: cold PC species use a 55 ms cursor-settle guard only when the provider explicitly reports the scene nonresident.
- PASS: cached actors explicitly resume idle animation when they regain focus.
- PASS: desktop PC viewer renders at 60 Hz; Android uses 30 Hz idle / 36 Hz while interacting on the existing private downsampled canvas.

## Runtime boundary
- Live Gen1Recomp/CBE rendering is still required to verify perceived model-swap latency and pointer feel on the user's hardware.
