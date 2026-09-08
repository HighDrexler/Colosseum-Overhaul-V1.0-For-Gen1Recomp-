# Validation — Colosseum Inspired UI Overhaul 2.2.9

## Baseline
- Built directly from packaged UI 2.2.8.
- Scope: PC ACCESS row alignment and information-model acquisition latency.

## Reported regressions addressed
- PASS (static): Pokédex no longer uses the 160 ms selection dwell. Only genuinely cold PC rows retain a 35 ms repeat-key guard.
- PASS (static): resident provider models still test `peek` and use `acquireCached` before normal `acquire`.
- PASS (static): PC ACCESS computes one row box, fits the active font to it, then centers both focus rail and glyph top inside that same measured row.
- PASS (static): PC still routes through `drawPcInformationPortrait` -> the shared animated/orbitable `drawStadiumUiModel` viewer.

## Regression/package checks
- PASS: `main.lua` parses with `texluac -p`.
- PASS: `manifest.json` parses and reports 2.2.9.
- Changed existing files vs 2.2.8: main.lua, manifest.json.
- Added files: RELEASE_NOTES_2.2.9.md.
- Removed files: none.
- Runtime UI assets byte-identical to 2.2.8: 536/536.

## Live-runtime boundary
Live Gen1Recomp is still required to visually confirm the user-selected text profile centers BILL's PC/CARL's PC/OAK's PC exactly and to time first-pixel model appearance on the user's cache/device.
