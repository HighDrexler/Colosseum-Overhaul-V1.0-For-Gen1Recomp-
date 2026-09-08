# Validation — CBE 1.9.28-relic-forest-360.1

## Result

- Lua syntax: **82 / 82 files parse** with `texlua loadfile` validation.
- Regression suites: **23 / 23 pass**.
- New suite: `tests/RelicForest360Fidelity1928Tests.lua` passes.
- Manifest JSON parses successfully.

## Relic 360 fidelity coverage

Validated by source/runtime contract tests:

- canonical source remains `M3_shrine_1F_bf.fsys / M3_shrine_1F_bf.dat`;
- retail HSD pass/shadow filtering and 1.9.27 central-overhang rejection remain intact;
- source trunk/root motifs are selected from Relic's real opaque HSD material groups;
- source foliage motifs are selected from Relic's real cutout HSD material groups;
- small source understory groups are reused for extra perimeter detail;
- broad flat carrier sheets are excluded from the source-forest motif set;
- 360 closure uses two deterministic 3D source-mesh rings (`14 @ ~86`, `18 @ ~145`) outside the legal camera radius;
- the source forest closure renders before the canonical arena scene, preserving real near geometry and depth occlusion;
- the old screen-space painted treeline is absent;
- the backdrop contains actual daylight sky/cloud treatment plus only low-opacity atmospheric seam haze;
- Relic's projected foreground foliage guard and max camera radius `36` remain active;
- daylight forest lighting/fog values are present.

## Regression coverage retained

All existing suites continue to pass, including:

- Relic camera safety and projected foreground-occlusion cleanup;
- 1.9.27 Relic/Outskirts source contracts;
- Outskirts floor/sky/sand-drift presentation;
- Pyrite camera safety;
- Deep/arena source parity;
- Pokemon presentation integrity;
- MoveFX source/retail particle/attack handoff;
- trainer source cache;
- audio parity;
- information-menu performance and hard-cache scheduling;
- battle-exit boundaries.

## Cache isolation

- canonical arena family remains **v9**;
- packed arena runtime sidecars remain **format 6** / `runtime_mesh_v6`;
- global extractor remains **revision 15**;
- no new Relic extraction is required for an otherwise current 1.9.27 install;
- unrelated audio, trainer, Pokemon, MoveFX, capture and hard-cache identities remain valid.

## Live-render boundary

The runtime here cannot reproduce the user's exact generated GC6E01 arena cache and Gen1Recomp GPU session. The package verifies the new 360 source-mesh closure and known artifact guards, but the user's next Relic battle is the final authority for exact tree density and spacing.
