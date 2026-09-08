# Validation — CBE 1.9.3-information-ui-cache.1

## Baseline
- Rebases the information-UI resident-cache seam directly onto `1.9.2-pokemon-motion-handoff.1`.
- Existing 1.9.2 PKX motion handoff, 1.9.1 Bite source layout, and 1.9.0 MoveFX source-chain files are preserved unless listed below.

## Information-model bridge
- PASS: `informationModels.version = 4`.
- PASS: `resolveSelected` is present for UI v4 provider selection.
- PASS: existing `resolve`, `resolveColosseum`, and `resolveShowroom` routes remain present.
- PASS: `PokemonActors.service.peek` reports resident-scene state from memory only.
- PASS: `PokemonActors.service.acquireCached` refuses cold scenes and reuses the normal actor-binding path only when `scenes[dex]` is already resident.

## Regression/static checks
- PASS: all 58 packaged Lua files parse with `texluac -p`.
- PASS: packaged `tests/MoveFXSourceChainTests.lua` completes successfully.
- PASS: manifest parses and reports `1.9.3-information-ui-cache.1`.
- PASS: compared with 1.9.2, the only modified existing files are: mod.card, main.lua, README.md, manifest.json, lib/PokemonActors.lua.
- PASS: all other 141 existing files are byte-identical to 1.9.2.
- PASS: no extractor, MoveFX, Waza, audio, arena, trainer, capture, or Pokémon source-cache revision file was modified by this rebase.

## Live-runtime boundary
The static/package checks prove the cache API was rebased without replacing the 1.9.2 feature work. Final performance/animation confirmation still belongs in a live Gen1Recomp run with UI 2.2.8: rapidly cycle PC Pokémon, revisit warmed entries, confirm idle animation continues, and verify mouse/touch orbit/zoom behavior.
