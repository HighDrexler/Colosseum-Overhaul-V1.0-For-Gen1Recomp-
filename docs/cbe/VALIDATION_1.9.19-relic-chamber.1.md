# CBE 1.9.19-relic-chamber.1 validation

## Baseline

- Built directly from `ColosseumBattleEnvironments-1.9.18-ui-model-performance.1.zip`.
- New arena id: `relic_chamber`.
- Display label: `RELIC CHAMBER`.
- Source archive: `M3_shrine_1F_bf.fsys`.
- Preferred source member: `M3_shrine_1F_bf.dat` (existing model-entry fallback remains active).
- Generated cache: `cache/M3_shrine_1F_bf_cache.lua`.
- Source texture root: `cache/stages/relic_chamber/source/`.

## Static/source contract

- Complete HSD scene extraction path is reused; no procedural geometry substitutes for the shrine room.
- Exact decoded GX RGBA textures, UVs and source WrapS/WrapT survive into the runtime cache.
- Source diffuse/ambient/specular/shininess material values remain on each group.
- Relic Chamber is present in `ArenaCatalog` order/options and accepted by `BattleSettings`.
- Native raw/CISO structural validation includes `M3_shrine_1F_bf.fsys`.
- Arena marker advanced to `cbe-arena=8` / `.cbe-arena-v8.complete`.
- Global extractor remains revision 15 so existing 1.9.18 caches take the targeted `arenasOnly()` migration rather than invalidating audio/MoveFX/trainers.
- Runtime-core/cache diagnostics require the Relic Chamber cache after migration.
- Six arena packed-mesh sidecars are generated/reused by the build-time fast path.

## Automated regression

- Lua syntax: 71 / 71 packaged `.lua` files PASS with `texluac -p`.
- `AudioParityContractTests.lua`: PASS.
- `BattleExitBoundaryTests.lua`: PASS.
- `HSDScaleTests.lua`: PASS.
- `HardCacheStorageQueueTests.lua`: PASS.
- `InformationMenuPerformanceTests.lua`: PASS.
- `MenuPrewarmBoundaryTests.lua`: PASS.
- `MoveFXAttackHandoffTests.lua`: PASS.
- `MoveFXRetailParticleRuntimeTests.lua`: PASS.
- `MoveFXSourceChainTests.lua`: PASS.
- `PokemonReactionQueueTests.lua`: PASS.
- `RelicChamberArenaTests.lua`: PASS.
- `TrainerSourceCacheTests.lua`: PASS, including six-arena first-build and metadata-less sidecar reuse.
- `WazaSfxMappingTests.lua`: PASS.

## Live-source boundary

This sandbox does not contain the user's full GC6E01 disc image, so the actual M3 archive cannot be decompressed/rendered here. The package is wired to extract the retail battlefield directly on the user's normal CBE source-build path. The first live test should verify the room's source shell completeness, floor origin/yaw, Pokemon/trainer spacing and camera framing against the supplied retail clip; those are the only remaining items that require the real source asset/runtime rather than static validation.
