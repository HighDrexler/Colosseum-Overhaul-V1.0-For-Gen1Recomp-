# Validation — CBE 1.9.18-ui-model-performance.1

## Parse / regression suite

- PASS: `main.lua`, `lib/PokemonActors.lua`, `lib/ResidentPrewarm.lua`, `lib/BattleRuntime.lua` and `lib/CacheManager.lua` parse with LuaTeX/texlua `loadfile()`.
- PASS: `AudioParityContractTests.lua`.
- PASS: `BattleExitBoundaryTests.lua`.
- PASS: `HSDScaleTests.lua`.
- PASS: `MoveFXAttackHandoffTests.lua`.
- PASS: `MoveFXRetailParticleRuntimeTests.lua`.
- PASS: `MoveFXSourceChainTests.lua`.
- PASS: `PokemonReactionQueueTests.lua`.
- PASS: `TrainerSourceCacheTests.lua`.
- PASS: `WazaSfxMappingTests.lua`.
- PASS: new `InformationMenuPerformanceTests.lua`.
- PASS: new `MenuPrewarmBoundaryTests.lua`.
- PASS: new `HardCacheStorageQueueTests.lua`.

## New invariants covered

- Cached selected information body can use the scheduler's viewer-safe path.
- Uncached source extraction cannot run during an active viewer lease.
- Authored information idle baking cannot run during the viewer lease.
- Unrelated arena prewarm cannot run during the viewer lease and resumes afterward.
- A superseded PC information request is pruned before warm/upload.
- Ordinary resident prewarm does not run when the top state is an unrelated menu.
- Normal prewarm still runs on the true overworld.
- Viewer-safe and explicit Hard Cache operations can still progress outside the overworld when intended.
- Hard Cache completion contract is v2; old v1 marker is stale by design.
- Pokémon cache-validity probes now prefer `GeneratedAssets` positive metadata from the persisted Hard Cache registry before falling back to direct host-cache probes, and successful species validation is memoized for the process.
- Hard Cache queue scans unique boxed species without adding battle-only banks for storage species.

## Scope preservation

No arena model, trainer model, Pokémon source asset, MoveFX payload, audio payload or other visual/audio asset was changed by this pass. Only runtime scheduling/cache/UI-integration code, manifests, tests and release documentation differ from 1.9.17.

Static tests cannot prove real device frame time or driver behavior. Runtime stress testing should rapidly traverse PC/Pokédex species, cycle Summary party members, leave/re-enter the menu, and repeat after a process relaunch with Hard Cache v2 READY on Windows and Android.
