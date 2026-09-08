# CBE 1.9.17-hard-cache-performance.1 validation

## Baseline

- Source package: `ColosseumBattleEnvironments-1.9.16-trainer-source-cache.1.zip`.
- Version/manifest advanced to `1.9.17-hard-cache-performance.1`.
- This pass is cache/performance-focused; no packaged texture, audio, model, recipe, third-party binary, or other non-code runtime asset was modified.

## Hard Cache Save contract

The new Battle-menu **HARD CACHE SAVE** path is a paced stable-overworld job, not a synchronous menu/battle operation. Its orchestration was checked with a dedicated headless scheduler harness. The harness verifies that:

- current-party Pokemon hard-cache work is queued separately from MoveFX/Waza work;
- generated-path registration advances in bounded batches;
- MoveFX is promoted before Waza sidecars are discovered;
- Waza sidecar work drains before finalization;
- the persisted file-info registry is saved;
- `build/hard_cache_v1.complete` is written only after all pending hard-cache stages have drained.

Result: `CBE ResidentPrewarm hard-cache harness: OK`.

## Generated metadata registry / runtime Lua memo

A second headless harness uses a fake `mod.cache` backend and verifies:

- a positive `GeneratedAssets.info()` result hits the host only once in-session;
- explicit revalidation still crosses the host boundary and updates the registry;
- CBE writes immediately register their path/size;
- `build/hard_cache_registry_v1.lua` restores positive metadata in a fresh module session without another host `info()` call;
- missing paths are never negatively persisted, preserving lazy extractor compatibility;
- `RuntimeMeshCache.readLua()` reads/parses a runtime metadata file once and serves subsequent reads from its memo.

Result: `CBE hard-cache metadata harness: OK`.

## Cache-manager hot path

A third headless harness verifies that repeated `CacheManager.inspect()` calls inside the 0.40-second diagnostic window reuse one inspection result and that status inspection no longer reads the complete `assets/audio/colosseum_battle_transition.wav` body. Audio readiness continues to use the v9 transactional ledger, markers, and generated-file existence/size contract.

Result: `CBE CacheManager status hot-path harness: OK`.

## Packaged regression suites

All nine existing tests in `tests/` pass under `texlua`:

1. `AudioParityContractTests.lua`
2. `BattleExitBoundaryTests.lua`
3. `HSDScaleTests.lua`
4. `MoveFXAttackHandoffTests.lua`
5. `MoveFXRetailParticleRuntimeTests.lua`
6. `MoveFXSourceChainTests.lua`
7. `PokemonReactionQueueTests.lua`
8. `TrainerSourceCacheTests.lua`
9. `WazaSfxMappingTests.lua`

This preserves the existing audio, battle-exit, PKX/Waza handoff, retail particle, reaction queue, trainer cache and source-chain contracts while adding the new cache layer.

## Static package gates

- All 67 packaged Lua files parse successfully with `texluac -p`.
- `manifest.json` parses as valid JSON.
- `main.lua` and `manifest.json` both report `1.9.17-hard-cache-performance.1`.
- Battle settings contain the direct `HARD CACHE SAVE` row.
- Android post-battle Pokemon residency is `keepParty=6, keepRecent=4, softLimit=10`.
- Waza runtime-sidecar creation/validation no longer requires a host-provided `info.size` field; exact size/stride validation is still applied whenever size metadata exists, and the actual binary payload is validated again by `RuntimeMeshCache.meshFromBytes()`.

## Baseline integrity comparison

A byte-level comparison against the unpacked 1.9.16 baseline reports no removed files and no changed non-code/runtime assets. Changes are limited to the cache/performance Lua modules, version/manifest/card/README metadata, and the new 1.9.17 release/validation notes.

## Live-device boundary

These gates prove source/package correctness and scheduler behavior, but they do not fabricate Windows/Android frame-time numbers. The most important live acceptance test is to run Hard Cache Save once on a populated save, allow it to reach `READY / REFRESH`, then compare repeated battle entry, party/PC model screens, switches and MoveFX-heavy battles before/after the bake with the user's normal multi-mod stack.
