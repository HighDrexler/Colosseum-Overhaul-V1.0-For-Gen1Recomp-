# Colosseum Overhaul 1.0.9 — validation

## Identity and scope

Complete combined package based on the last delivered v1.0.8, not the earlier
same-version package with a different cache implementation. Baseline SHA-256:
`dc1dfaa989cf2f95e2ced7d86d2937a24f417085b2e9d406f65180503f37cc8f`.

Production changes are restricted to the BattleCache controller, additive exported
cache helpers, and release metadata. Source decoding, animation sampling, shiny
colour routing, PokemonActors, UIMain, battle rules and audio remain unchanged.
This is a preparation-scope/scheduler improvement, not a faster HSD decoder.

## Executed tests

**96 top-level regression suites pass under texlua / Lua 5.3**, with zero failures
or timeouts. The historical DoublesDisplayCompatTests suite remains explicitly
unrun because its original producer fixtures are unavailable; it is not a pass.
The suite runner uses the supplied `gen1recomp-dev (7).zip` engine fixtures.

- **NativeModelCacheTests: 1,625 checks.** Actual native Gen I/II title menus,
  Hooks, StateStack and Continue confirmation. Automatic startup uses only the
  current team. Warm Continue does no repeated preparation; a changed party is
  checked again. Full Catalog requires explicit menu selection and still visits
  all 502 appearances. Models OFF, New Game, pointer input, cancellation, retry,
  source-task cleanup, doubles/replacement identity and render-error barriers
  are exercised. GPU/source readiness in this suite is controlled.
- **QuickCacheSchedulingTests: 803 checks.** Party/dex/shiny identity, deduplication,
  egg exclusion, no PC traversal, new-game starter scope, full-catalog coverage,
  current-team-first ordering, wall-time budgets, partial failure and cancellation.
  A deterministic all-ready 502-row run finishes in **16 update slices** instead
  of the old one-row policy's **503 updates**. This measures scheduling overhead
  under a fixture, not cold extraction speed or a device startup-time ratio.
- **SessionModelCacheTests: 2,299 checks.** The unchanged real cache/actor backend
  still covers all 502 identities sharing 270 source units, source-filter shinies,
  separate shiny assets, warm reuse without source, metadata repair and mobile
  residency limits. Its source/graphics are synthetic.
- **Native doubles integration: 1,953 assertions.** Real Gen I/II kernels and
  reward/replacement/end-of-battle handoffs with abilities installed; graphics
  are stubbed. Existing single-switch checks and audio/arena/UI/shiny regressions
  are included in the top-level run.

All **210 Lua files** pass `texluac -p`; the manifest matches main.lua at
1.0.9. The ZIP is CRC-checked, extracted afresh and compared byte-for-byte with the
tested tree before its final regression run. Logs are in validation/quick_start_v1.

## Preservation

All **548 packaged assets** are byte-identical to v1.0.8. No baseline file is
removed. No source model, animation, audio, or shiny cache identity is bumped.
Existing completed units from a cancelled/partial full bake remain reusable.
An interrupted in-progress source unit can require preparation again. No imported
source media or newly generated ROM-derived assets are distributed.
`MERGE_AUDIT_1.0.9.json` records changed/added file hashes and baseline identity.

## Limits

No live LÖVE/GPU, Windows, Android, or iOS playtest was completed in this release
check. No user-device startup duration or memory benchmark is claimed. A cold
party/encounter can still require substantial source work; full-catalog preparation
is not made cheap by this change. Quick mode does not preload the whole roster.
Cooperative CPU deadlines cannot interrupt an individual I/O, GC, or GPU call.

The original shader/asset fidelity and full-roster visual-validation limitations
continue to apply. Source checks documented in older validation files are historical,
not additional source/GPU runs performed for 1.0.9.

## Reproduce

From the extracted package:

```sh
python tests/run_headless.py --engine-root /path/to/gen1recomp --output results.json
```

From the supplied engine directory:

```sh
POKEPORT_DATA_DIR=tests/fixture_data \
CBE_DOUBLES_MOD_DIR=/path/to/combined \
CBE_DOUBLES_UI_DIR=/path/to/combined \
CBE_TEST_ABILITIES_INSTALLED=1 \
texlua /path/to/combined/tests/texlua_wrapper.lua /path/to/combined/tests/doubles/RegressionTests.lua
```

Highest-value device checks: partial old cache -> Quick Start; warm restart;
select a save with different party/shiny identities; open Full Catalog then cancel;
reproduce the Gold Voltorb/Quilava/Larvitar doubles scene; visit an uncached PC entry.
The expected policy is explicit loading/error handling, never sprite substitution.
