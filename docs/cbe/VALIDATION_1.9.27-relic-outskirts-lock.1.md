# Validation — CBE 1.9.27-relic-outskirts-lock.1

## Result

- Lua syntax: **81 / 81 files parse** with `texluac -p`.
- Regression suites: **22 / 22 pass**.
- New lock suite: `tests/RelicOutskirtsLock1927Tests.lua` passes.
- Manifest JSON parses successfully.

## Relic Chamber coverage

Validated by contract and functional tests:

- canonical source remains `M3_shrine_1F_bf.fsys / M3_shrine_1F_bf.dat`;
- retail render-pass filtering and shadow-material exclusion are active;
- extraction-time central overhang rejection is enabled;
- expanded `7200 / 18000 / 6800` source shell is shared by catalog and packed-runtime settings;
- camera scale/height/radius/focus/pitch limits are consumed by the camera runtime;
- source-Waza camera poses are clamped into the same safe volume;
- projected-frustum guard culls foreground foliage while retaining rear foliage and ordinary vertical architecture;
- 360 forest-floor continuation, daylight sky, high clouds and distant treeline closure are present;
- hard runtime central-carrier guard is present as a final safety net.

## Outskirts coverage

Validated by contract tests:

- canonical source remains `S1_out_bf.fsys / S1_out_bf.dat`;
- retail render-pass filtering and shadow-material exclusion are active;
- source shell is `16000 / 42000 / 15000` in catalog and packed-runtime settings;
- low opening-battle camera contract is retained;
- desktop and mobile shaders contain the shared low-floor sand reconciliation path;
- desert continuation uses five depth rings through radius `12800`;
- cobalt/clouded sky and distant mesa treatment are retained;
- deterministic line/grain/dust-veil sand drift is active.

## Migration / regression coverage

- packed arena sidecars: **format 6**, `runtime_mesh_v6`;
- complete-install canonical rebuild mode: **`relic-outskirts-only`**;
- global build extractor remains **revision 15**;
- canonical arena family remains **v9**;
- existing Pyrite camera safety regression passes;
- audio, MoveFX, trainer, Pokémon, battle-exit, information-menu, hard-cache and prewarm regression suites all pass.

## Important live-render boundary

This environment does not contain the user's already-generated live GC6E01 arena cache or the Gen1Recomp renderer session used for the screenshots. The tests prove the new source/extraction/runtime contracts and prevent known regression classes, but final 1:1 visual certification still requires the user's live battle render after the two targeted arena caches refresh.
