# Colosseum Inspired UI Overhaul 2.2.2

Cross-generation Pokemon presentation-source parity pass.

- Adds current Battle Art 2.0.9 (`BATTLE_ART_VOXEL_GEN2`) discovery while preserving legacy Battle Art IDs.
- Pokemon Menu/Summary and Pokédex now share the same provider order in Gen I and Gen II.
- CBE Colosseum models remain absolute priority whenever CBE says Colosseum Models are enabled.
- With Colosseum Models disabled, Battle Art STATIC/ANIMATED art is resolved from Battle Art's exported runtime contract.
- Battle Art MODDED mode deliberately yields to the engine `pokemon.sprite` seam so Crystal/custom sprite packages remain authoritative.
- Native Gen I/Gen II sprites are used only after no active custom provider owns the species.
- Keeps the 2.2.1 Gen II Pokédex visibility hotfix and 2.2.0 information-model performance/cache work intact.
- No CBE changes are bundled in this release.
