# Validation — CBE 1.9.5-information-ui-idle.1

## Baseline
- Built directly from CBE 1.9.4-information-ui-motion-cache.1, itself rebased onto the user's 1.9.2 Pokémon Motion Handoff line.

## Information-model motion correction
- PASS (static): information actors still display the compact generated base immediately.
- PASS (static): after 60 ms, an information actor with an available source idle action materializes/selects that idle bank even when the compact base reports morph frames.
- PASS (static): the incorrect 1.9.4 `baseFrames <= 0` gate is removed; base morph presence is no longer treated as proof of an authored looping idle.
- PASS (static): only the idle bank is requested by this information-surface path; attack/damage/faint prewarm remains excluded from information surfaces.
- PASS (static): 1.9.4 no-source-disc-read information acquisition and 1.9.3 resident `peek` / `acquireCached` behavior remain present.

## Regression/package checks
- PASS: all 58 packaged Lua files parse successfully under LuaTeX `loadfile()`.
- PASS: packaged `tests/MoveFXSourceChainTests.lua` exits successfully.
- PASS: `manifest.json` parses and reports 1.9.5-information-ui-idle.1.
- Changed existing files vs 1.9.4: lib/PokemonActors.lua plus version/release metadata (main.lua, manifest.json, README.md, mod.card).
- Added files: CBE_1.9.5-information-ui-idle.1.md, VALIDATION_1.9.5-information-ui-idle.1.md.
- Removed files: none.
- All 7 packaged runtime assets are byte-identical to 1.9.4.
- No arena, MoveFX/Waza, capture, trainer, audio, or battle-camera source file is changed by this pass.

## Live-runtime boundary
Static validation cannot prove the visual idle loop on every extracted species. Pair with UI 2.2.10 and verify the PC large model begins idling shortly after first display, continues animating while selected, rotates via pointer drag, and remains fast when revisiting resident species.
