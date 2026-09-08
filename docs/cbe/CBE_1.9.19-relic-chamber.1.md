# CBE 1.9.19-relic-chamber.1

## Scope

Adds **RELIC CHAMBER** as a sixth Colosseum Battle Environments arena, based on the Agate Village shrine battlefield shown immediately before the purification/Relic Stone chamber.

## Source fidelity path

Relic Chamber is source-backed, not procedurally reconstructed. `extract/ArenaBuilder.lua` opens the user's validated GC6E01 `M3_shrine_1F_bf.fsys`, prefers `M3_shrine_1F_bf.dat`, and otherwise retains the existing safe first-HSD-model fallback used by other source arenas. The complete decoded HSD scene is serialized with source positions, UVs, normals, diffuse/ambient/specular/shininess, and exact GX WrapS/WrapT texture state. Decoded RGBA textures live under `cache/stages/relic_chamber/source/`.

The runtime profile uses an enclosed neutral background only behind holes in the actual scene shell. It does not invent an outdoor sky. The catalog uses compact shrine-specific Pokemon/trainer anchors and a tighter camera-safe volume so the battle stays on the central packed-earth circle rather than inheriting the scale of Orre/Realgam.

## Cache migration

The arena marker advances from v7 to v8 and includes the new M3 source contract. The global extractor remains revision 15 intentionally. A healthy 1.9.18 install therefore enters `arenasOnly()`: source arenas and all six arena runtime-mesh sidecars are refreshed while trainer, MoveFX, capture and canonical audio caches remain reusable.

## Compatibility

No battle logic, sprite/model provider priority, audio contract, capture runtime, MoveFX runtime, trainer event routing, Gen 1/Gen 2 compatibility, HARD CACHE SAVE v2, or Colosseum UI information-model performance behavior is removed or changed by this patch.
