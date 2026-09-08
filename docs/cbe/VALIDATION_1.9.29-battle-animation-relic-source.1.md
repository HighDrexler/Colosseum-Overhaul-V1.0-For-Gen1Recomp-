# Validation — CBE 1.9.29-battle-animation-relic-source.1

## Root-cause correction

- Pokemon extractor revision is **36**.
- `extract/PokemonExtractor.lua` is byte-for-byte the 1.9.25 source-animation extractor except for the revision number. The 1.9.26 `repairIdleIsolatedGroups()` heuristic and every call site are removed.
- The targeted Diglett/Dugtrio floor-depth exception remains in `PokemonActors.lua`; it changes actor placement only and does not rewrite source animation vertices.
- Hard Cache Save completion advances to **v3** and records `pokemon-extractor=36`, so a v2 READY marker cannot hide stale revision-35 Pokemon animation caches.

## Relic Chamber

- 1.9.28's isolated trunk/leaf motif rings are removed.
- The runtime scores safe source perimeter groups from `M3_shrine_1F_bf`, selects the densest contiguous 120-degree source sector, and draws two rotated copies at +120/+240 degrees.
- Complete eligible groups are copied together, preserving source trunk/root/foliage relationships and authored spacing.
- Groups whose bounds could enter the active Relic camera clearing, broad floor carriers, and giant overhead sheets are excluded from the copied sector.
- Existing Relic clean-camera and projected-occluder guards remain active.

## Executable/static validation

- Lua parse: **83/83** packaged Lua files parse with LuaTeX `loadfile()`.
- Regression suites: **24/24** pass.
- New `BattleAnimationRegression1929Tests.lua` asserts extractor revision 36, removal of the global idle-pose repair, source continuous-pose runtime retention, Diglett/Dugtrio placement retention, and Hard Cache v3 migration.
- Updated Relic 360 test rejects the old motif-ring implementation and requires complete source-sector replication.

## Runtime limitation

This environment does not contain the user's generated GC6E01 Pokemon/arena caches, so static validation cannot prove the exact live appearance of every species or the final Relic sector selected from that user's extracted scene. The build intentionally forces revision-35 Pokemon caches stale so live testing uses newly extracted unmodified source animation samples.
