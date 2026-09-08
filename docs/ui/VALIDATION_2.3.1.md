# Validation — Colosseum Inspired UI Overhaul 2.3.1

## Static/package checks
- PASS: `main.lua` parses successfully through LuaTeX/Lua `loadfile`.
- PASS: `manifest.json` parses and reports version `2.3.1`.
- PASS: package root still contains `main.lua` and `manifest.json`.
- PASS: no runtime asset files were changed from the supplied 2.3.0 baseline.
- PASS: the only 2.3.0 runtime code changes are the focused Gen I save/dialogue/Pokédex-location parity paths.

## Gen I regression targets
1. START -> SAVE: no cartridge PLAYER/BADGES/POKéDEX/TIME panel leaks through; Colosseum save terminal appears immediately and remains through YES/NO, saving, and saved phases.
2. SAVE input/timing: YES/NO, B cancel, writeSave, save SFX, auto delays, and return-to-START behavior remain engine-owned.
3. Ordinary overworld TextBox: uses the compact Gen II-style Colosseum dialogue card, including active user font/size settings.
4. Battle TextBox: retains the existing battle-width message rail and PROMPT/DONE stripping.
5. Pokédex -> LOCATION: opens habitat list, not TownMap; Up/Down scroll and A/B return to data.
6. Save Screen UI / Pokédex / Dialogue toggles OFF: native Gen I rendering paths remain available.
7. Gen II Save, dialogue, and Pokédex LOCATION behavior remain unchanged.
8. Strict Native UI Block and all 2.3.0 caught-indicator/performance fixes remain present.

## Runtime note
Static validation cannot replace an in-engine smoke test. Recommended smoke pass: Gen I SAVE confirm/cancel/complete, one ordinary overworld dialogue, one battle dialogue, and Pokédex LOCATION on a species with multiple encounter areas; then repeat the three corresponding Gen II screens for parity.
