# Validation — CBE 1.9.26-relic-source-pokemon.1

## Static/package validation

- `main.lua` version and `manifest.json` version agree on `1.9.26-relic-source-pokemon.1`.
- Manifest JSON parses successfully.
- All 80 packaged Lua files parse with a Lua 5.4 parser/runtime shim configured with the LuaJIT/Lua 5.1 global `unpack` contract used by Gen1Recomp.
- ZIP is created with `main.lua` and `manifest.json` at archive root.
- ZIP CRC/integrity is checked after packaging.

## Regression validation

21/21 project regression suites pass:

1. ArenaExpansionParityTests
2. ArenaFidelity1925Tests
3. AudioParityContractTests
4. BattleExitBoundaryTests
5. HSDScaleTests
6. HardCacheStorageQueueTests
7. InformationMenuPerformanceTests
8. MenuPrewarmBoundaryTests
9. MoveFXAttackHandoffTests
10. MoveFXRetailParticleRuntimeTests
11. MoveFXSourceChainTests
12. PokemonPresentationIntegrityTests
13. PokemonReactionQueueTests
14. PyriteCameraSafetyTests
15. RelicCameraSafetyTests
16. RelicChamberArenaTests
17. RelicOutskirtsPresentationTests
18. RelicPresentationCleanupTests
19. RelicRetailSource1926Tests
20. TrainerSourceCacheTests
21. WazaSfxMappingTests

New functional coverage verifies:

- isolated idle-part corruption is repaired against a complete reference while a small legitimate idle movement is preserved;
- Diglett/Dugtrio floor placement permits meaningful geometry below the battle plane while an ordinary species remains strictly clamped;
- Relic is bound to `M3_shrine_1F_bf` and enables retail HSD render-pass + shadow-pass filtering;
- the widened Relic source shell is retained in both canonical and packed-runtime contracts;
- synthetic Relic forest world-shell geometry is disabled;
- current complete installs target Relic-only canonical arena refresh rather than invalidating all expensive caches;
- Outskirts retains the widened source shell, pale far-field palette and low-opacity sand-drift pass;
- Pyrite camera, audio, MoveFX, trainer cache, menu-performance and battle-exit contracts remain passing.

## Validation boundary

This runtime does **not** contain the user's full GC6E01 disc image or their already-generated local arena/Pokémon caches. Therefore the following require the user's live test after the build performs its targeted source refresh:

- visual confirmation that retail render-pass filtering removes the specific Relic foliage/cliff helper surfaces shown in the captures;
- visual confirmation of recovered Relic rear/world-shell detail and exact camera composition;
- Articuno's exact idle head/crest presentation against its real extracted PKX;
- final Diglett/Dugtrio ground depth against their real extracted source models;
- final Outskirts sand/color match on the user's display/runtime.

The build is intentionally structured so those tests exercise source-derived content rather than another synthetic Relic reconstruction.
