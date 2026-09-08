# Validation — CBE 1.9.4-information-ui-motion-cache.1

## Baseline
- Built directly from CBE 1.9.3-information-ui-cache.1, which was rebased onto the user's 1.9.2 Pokémon Motion Handoff baseline.

## Information-UI latency/motion changes
- PASS (static): information-surface actors read an existing tiny metadata sidecar if present but do not open/inspect the GameCube source when that sidecar is absent.
- PASS (static): non-information/battle actors retain the authoritative `metadataReader.inspectSpecies` path.
- PASS (static): source metadata is not negatively cached merely because an information viewer skipped the disc read; a later battle actor can still resolve it.
- PASS (static): information actors draw the compact base scene immediately. If that base has no morph samples and a cached idle action exists, the actor upgrades to that idle bank after 80 ms of visible lifetime. Attack/damage/faint banks remain lazy.
- PASS (static): `peek` / `acquireCached` from 1.9.3 remain published.

## Regression/package checks
- PASS: all 58 packaged Lua files parse with `texluac -p`.
- PASS: packaged `tests/MoveFXSourceChainTests.lua` exits successfully.
- PASS: `manifest.json` parses and reports 1.9.4-information-ui-motion-cache.1.
- Changed existing files vs 1.9.3: mod.card, main.lua, README.md, manifest.json, lib/PokemonActors.lua, lib/CurrentSpriteModels.lua.
- Added files: CBE_1.9.4-information-ui-motion-cache.1.md.
- Removed files: none.
- No extractor, MoveFX/Waza, audio, arena, trainer, capture, or battle-camera file is changed by this pass.

## Live-runtime boundary
The static checks prove the intended code paths and package integrity, not real-device frame time. Highest-value live checks: rapidly browse uncached/resident Pokédex entries; switch repeatedly among 4–6 PC species; confirm models appear promptly, idle continuously, and respond to the existing drag/zoom viewer controls.
