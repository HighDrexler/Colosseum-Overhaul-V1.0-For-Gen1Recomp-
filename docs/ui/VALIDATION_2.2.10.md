# Validation — Colosseum Inspired UI Overhaul 2.2.10

## Baseline
- Built directly from packaged UI 2.2.9.
- Scope: PC model interaction, PC portrait-side selection locator, and duplicate native location-banner suppression.

## Reported regressions addressed
- PASS (static): selected PC party/storage rows no longer draw the orange footer beneath the portrait/name strip; the orange locator now occupies a dedicated gutter immediately left of the portrait.
- PASS (static): 3D information viewers publish their exact window-space model pod each frame and register an `input.pointer` wrapper for mouse/touch orbit and right-drag zoom. Hidden/stale pods age out and cannot steal pointer input.
- PASS (static): the old LOVE polling interaction path remains only as a compatibility fallback when the engine pointer hook is unavailable.
- PASS (static): the current Gen II/Crystal native `src.world.gen2.MapNameSign.draw` seam is wrapped so it renders normally unless the custom AREA BANNER UI is active; with the custom banner active, the native location sign is suppressed.
- PASS (static): custom location-banner timing and area tracking remain unchanged.

## Regression/package checks
- PASS: `main.lua` parses successfully under LuaTeX `loadfile()`.
- PASS: `manifest.json` parses and reports 2.2.10.
- Changed existing files vs 2.2.9: main.lua, manifest.json.
- Added files: RELEASE_NOTES_2.2.10.md, VALIDATION_2.2.10.md.
- Removed files: none.
- Runtime UI assets byte-identical to 2.2.9: 536/536.
- Hook registrations: 12 -> 13; the single added hook is the intended `input.pointer` information-model interaction seam.

## Live-runtime boundary
Live Gen1Recomp is still required to verify pointer capture on the user's exact launcher/runtime and visual placement at every scale. Highest-value checks: drag the PC large model with LMB/touch, right-drag to zoom, move between several party/storage entries, and cross a Crystal/Gen II route boundary with AREA BANNER UI enabled to confirm only the custom banner appears.
