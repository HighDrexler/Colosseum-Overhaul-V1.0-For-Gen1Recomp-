# Validation — Colosseum Inspired UI Overhaul 2.2.2

## Scope
Cross-generation Pokemon presentation-source parity for Pokemon information UI.

## Contract checks
- Manifest version is 2.2.2 and declares current `BATTLE_ART_VOXEL_GEN2` as an optional dependency.
- Battle Art discovery recognizes current `BATTLE_ART_VOXEL_GEN2` plus legacy `BATTLE_ART_VOXEL_FORK` / `DRAMATIC_SHAPE` IDs.
- Current Battle Art `exports.battleArt` is preferred, with legacy `exports.lib.require("BattleArt")` fallback.
- Battle Art `ownsSpeciesArt()` / `prefersModded()` ownership is respected before any Battle Art image is selected.
- STATIC uses Battle Art's exported image resolver when available, preserving species aliases, shiny state, matte removal and display preparation.
- ANIMATED information portraits use the selected generation and atlas metadata instead of drawing an entire sprite sheet.
- MODDED yields to Gen1Recomp's live `pokemon.sprite` seam, allowing Crystal/personal/custom sprite providers to remain authoritative.
- CBE information-model resolution remains first in `drawInformationPortrait`; 2D resolution is only the fallback when no selected 3D actor provider owns the surface.
- Pokemon Menu/Summary and Pokédex both route through the same `drawInformationPortrait` contract in Gen I and Gen II.
- The 2.2.1 Gen II Pokédex visibility routing remains intact.

## Expected precedence
1. CBE Colosseum models when the CBE Pokemon-model toggle is enabled and a model is available.
2. Battle Art/current custom sprite provider selected by the user.
3. Other live `pokemon.sprite` provider after an explicit MODDED/yield decision.
4. Native Gen I/Gen II sprite only when no custom provider owns the species.

## Package checks
- `main.lua` compiles successfully through a Lua parser (`loadfile`).
- Manifest JSON parses successfully.
- ZIP central-directory/integrity test passes.

No CBE files are bundled or modified by this package.
