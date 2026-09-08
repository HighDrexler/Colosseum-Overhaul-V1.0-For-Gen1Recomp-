# Colosseum Battle Environments 1.9.3-information-ui-cache.1

This build applies the information-surface resident-cache API to the current 1.9.2 Pokémon-motion baseline.

## Changes
- `PokemonActors.service.peek(source, dex, variant)` reports whether a supported Pokémon scene is already resident in memory without touching the filesystem.
- `PokemonActors.service.acquireCached(...)` only succeeds for resident scenes and then uses the normal actor binding path.
- `informationModels.version` is now 4 and exposes `resolveSelected` in addition to the existing `resolve`, `resolveColosseum`, and `resolveShowroom` routes.
- The intended consumer is Colosseum Inspired UI PC/Summary/Pokédex rendering, allowing fast reuse of prewarmed 3D models while keeping normal animation/orbit actor behavior.

## Preservation
- Built directly from 1.9.2-pokemon-motion-handoff.1.
- The 1.9.2 PKX motion handoff and its extractor revision remain unchanged.
- No MoveFX, Waza, audio, arena, trainer, capture, or Pokémon extractor cache revision was intentionally changed by this rebase.
