# CBE 1.9.20-arena-source-parity.1 validation

## Baseline and scope
- Baseline: `ColosseumBattleEnvironments-1.9.19-relic-chamber.1`.
- Scope is arena extraction/rendering/catalog/cache migration only. Global extractor revision remains `15`; trainer identity, Pokemon extraction, MoveFX, capture and canonical audio identities are unchanged.
- Arena identity advances to `cbe-arena=9`; packed arena runtime schema advances to `runtime_mesh_v3` / sidecar format `3`.

## Arena roster / source contract
Ten selectable runtime arenas are registered. Nine are GC6E01 source-backed and one is CBE-authored Wildlands.

| Arena | Source |
| --- | --- |
| Water Colosseum | `M1_water_colo.fsys` / `M1_water_colo.dat` |
| Orre Colosseum | `T1_ancient_colo.fsys` / `T1_ancient_colo.dat` |
| Relic Chamber | `M3_shrine_1F_bf.fsys` / `M3_shrine_1F_bf.dat` |
| Relic Cave | `M3_cave_1F_1_bf.fsys` / `M3_cave_1F_1_bf.dat` |
| Outskirts | `S1_out_bf.fsys` / `S1_out_bf.dat` |
| Pyrite Colosseum | `M2_earth_colo.fsys` / `M2_earth_colo.dat` |
| Deep Colosseum | `M4_bottom_colo.fsys` / `M4_bottom_colo.dat` |
| Realgam Colosseum | `D4_casino_colo.fsys` / `D4_casino_colo.dat` |
| Orre Wildlands | CBE authored recipe |
| Mt. Battle Summit | `D2_crater_colo.fsys` / `D2_crater_colo.dat` |

The new FSYS archives are also included in native raw/CISO validation and source/camera probes.

## Fidelity / parity changes
- Arena source cache revision `33` carries source `renderFlags`, `effect`, `useConstant`, `useVertexColor`, `useDiffuseLighting`, `textureSlot`, alpha/no-z/translucency state, diffuse/ambient/specular/shininess, GX texture path and wrap state.
- Packed arena sidecars carry the same material state plus group `center`, `span` and `extent`, so the fast path does not silently flatten the source material contract.
- Original GC6E01 atlases no longer receive synthetic CBE texture sharpening. The detail path remains only for authored Wildlands ground/bark assets.
- Source traversal/runtime envelopes were widened across the existing source venues and all new venues. Runtime far-plane selection derives from the active venue source-shell radius, preserving more outer architecture/background depth.
- Newly added source venues use a neutral source-owned shader profile. Realgam grading is explicitly bounded to the Realgam profile; Wildlands treatment is explicitly bounded to Wildlands.
- Relic Cave and Deep Colosseum use enclosed fallback backdrops to prevent outdoor sky leakage through source-shell gaps.
- Relic Chamber retains the full source shell/backside. Its large foreground root/trunk is handled by a narrow camera-side elongated-object occluder test only while the object lies between the lens and battle focus.
- Source diffuse-light state defaults safely for legacy/authored caches while explicit HSD `false` remains authoritative.

## Cache migration contract
- `.cbe-arena-v9.complete` is the new arena marker.
- Existing current installs take `arenasOnly`: source arenas and arena packed sidecars are rebuilt, but healthy trainer, Pokemon, MoveFX, capture, HARD CACHE SAVE and canonical audio caches remain reusable.
- No arena change bumps `cacheVersion=2` or `extractorRevision=15`.

## Static and executable validation
- Lua syntax: **72 / 72 PASS** under `texluac -p`.
- Packaged regression suites: **14 / 14 PASS** under `texlua`:
  - ArenaExpansionParityTests
  - AudioParityContractTests
  - BattleExitBoundaryTests
  - HSDScaleTests
  - HardCacheStorageQueueTests
  - InformationMenuPerformanceTests
  - MenuPrewarmBoundaryTests
  - MoveFXAttackHandoffTests
  - MoveFXRetailParticleRuntimeTests
  - MoveFXSourceChainTests
  - PokemonReactionQueueTests
  - RelicChamberArenaTests
  - TrainerSourceCacheTests
  - WazaSfxMappingTests
- `manifest.json` parses and reports `1.9.20-arena-source-parity.1`.
- `main.lua` reports the same version.

## Runtime boundary
This environment does not contain the user's full GC6E01 disc image, so it cannot perform the final live HSD extraction/GPU camera A/B for the four new scenes here. The build deliberately uses the named retail source scenes rather than bundled approximations, and all extraction/serialization/cache/runtime contracts are validated statically/headlessly. Final live testing should verify venue origin/yaw, exact actor anchors and retail camera framing after the user's GC6E01 arena-only migration completes; those are the remaining device/source-dependent checks rather than missing arena content.
