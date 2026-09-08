# Colosseum Overhaul 1.0 — release sweep and validation

## Baseline and scope

This complete combined release is built directly from the delivered
`Colosseum_Overhaul_v1.0.10.zip`, SHA-256:

`3772afc7931bbdf1ebc546b3ff0aea7d9cb8504af1d160ac3aed4959f422bdb5`

The user-requested release label is **1.0**. The mod ID remains
`COLOSSEUM_OVERHAUL`; this is not a rollback to the older 1.0.0 source tree.

The only gameplay-loaded implementation changed in the final sweep is
`lib/BattleCache.lua`: semantic/localized title-action selection, duplicate-guard
protection, and idempotent native state-exit cleanup. `main.lua` changes only its
release-version literal. Release metadata and current documentation are updated.
The test runner gains the new native-fixture suite. No baseline file is removed;
the previous root validation report is also retained verbatim in `docs/history/`.

## Preservation checks

All **548 existing packaged assets** are byte-identical to v1.0.10. All extractor
files, recipes, UIMain.lua, PokemonActors.lua, QuickCachePlanner.lua, CacheScreen.lua,
RuntimeMeshCache.lua, GeneratedAssets.lua, cache revision/identity modules, source
shaders, audio rendering, battle settings, and doubles implementations are unchanged.

Manifest fields other than version/description are unchanged: game targets,
engine range, API, priority, permissions, required import/digests, optional provider
ordering, conflicts, link flag and non-experimental status. Native engine Manifest,
Semver and ModTargets accept the release and give the same game/engine-range
answers as the baseline. This is declared-compatibility preservation, not a live
test of every third-party mod version or each cartridge.

The main-menu model quota remains **30 new source-model assets**, the full catalog
remains 270 assets / 502 normal-shiny appearances, and completed disk artifacts
remain the authority across sessions. Team/starter startup warming, optional Full
Catalog, strict battle-model readiness, atlas portraits and the full-color
post-palette cache screen are retained. No lower-detail models, reduced animation
sampling, smaller source workload or disabled features are introduced.

## Automated and native-state checks

The unchanged v1.0.10 baseline first passes its existing **99 top-level suites**
under Lua 5.3/texlua. The cleaned release passes **100 top-level suites under both
Lua 5.3/texlua and real LuaJIT**, with no failures or timeouts. Those release runs
are repeated against the freshly extracted final ZIP, not only the working tree.

The historical `DoublesDisplayCompatTests.lua` remains explicitly **not run**:
its original cbe1/cbe2/cbe3 producer fixtures are unavailable. It is not counted
as a pass. Existing replacement display/targeting tests still run normally.

The new `ReleaseLifecycleCompatibilityTests.lua` passes **78 checks** using the
real engine Hooks, Runtime and StateStack with controlled model preparation. It
covers external pop/clear during a suspended worker, exactly-once cleanup,
retention of completed units, cancellation of deferred Continue/New Game callbacks,
reopening after reset, reordered and translated Gen I title labels, explicit
semantic values, preservation of foreign callbacks/closing flags, unchanged input
rows and duplicate hook passes. Its external-pop case fails on the unchanged
baseline, reproducing the stale cache-screen ownership bug before the correction.

Separate native Gen I/II doubles integration passes **1,953 assertions under each
interpreter**, with abilities installed, including rewards/replacements/evolution
and battle completion. Graphics are controlled fixtures; placeholder-glyph warnings
in the ROM-free fixture font are retained in the logs, not suppressed.

All **221 packaged Lua files** pass `texluac -p`. JSON/manifest parsing, ZIP CRC,
root-entry structure, path/case-collision checks, baseline preservation and fresh
extraction byte comparisons also pass.

## Cross-release persistence: actual source files, separate processes

Using the supplied GC6E01 CISO in a private diagnostic directory, the unmodified
**v1.0.10** source/cache implementation builds Voltorb normal, Pikachu shiny
(shared model/colour recipe) and Typhlosion shiny (separate source asset).

A **new operating-system process** then loads the **1.0 release** against those
same files with source-disc access and every cache write treated as errors.
All three exact appearances and the shared normal/shiny counterparts succeed:

**0 source-disc opens; 0 generated-cache writes; 0 bytes written.**

The release warm pass reads 17,910,836 bytes across 496 cache reads to validate/load
existing data. Disk reads and graphics uploads are not extraction/regeneration.
Graphics objects in this source test are mocked. The source-derived files and disc
are private diagnostics and are not included in the release or evidence ZIPs.

This verifies cross-release reuse for three actual units, not a full-catalog phone
benchmark. The existing persistence suite additionally covers all 270 model assets
and 502 appearances with synthetic source/graphics, fresh runtime instances,
partial completion, cross-save reuse, and individually missing/damaged sidecars.

## Real LÖVE graphics checks

Linux LÖVE 11.5 is run under Xvfb/software OpenGL using the supplied engine checkout.
The actual Gen I `Game.draw` and Gen II `Game2.draw` compositor paths render the
cache selector through the shipped post-palette HUD hook. The captured menu is
inspected for readable, correctly coloured controls and the 30-new-model option.
These tests use synthetic game state, not a ROM-backed save playthrough.

The unchanged compact portrait functions handle **1,004 requests** (251 species ×
normal/shiny × two generation contexts), using **502 actual packaged portrait
images with zero 3D-model requests**. The resulting sample headshot gallery is
inspected. This verifies atlas routing/availability, not a retail colour comparison
of every shiny. Existing layout tests retain six viewport sizes and error/progress/
completion states. Screenshots and logs are included in the separate evidence ZIP.

## What this release does not claim

No live Windows, Android or iOS save playtest was performed. No phone/PC startup
minute count, FPS uplift, universal third-party compatibility or exhaustive retail
visual/audio fidelity is certified. Previously uncached model extraction remains
expensive; the decoder and sampling are intentionally unchanged. The final fixes
are lifecycle/title-menu cleanup, not a new renderer or extraction optimization.

## Installation and reproduction

Manually replace the old combined package with `Colosseum_Overhaul_v1.0.zip` while
the game is closed. Keep the same source import and hard cache, and leave duplicate
combined/standalone packages disabled. The deliberate `1.0` rename sorts below
`1.0.10`, so automatic newer-version comparison is not the update route. No cache
purge or audio rerender is required for this rename/cleanup.

From the extracted package:

```sh
python tests/run_headless.py --engine-root /path/to/gen1recomp --output results.json
python tests/run_headless.py --engine-root /path/to/gen1recomp --luajit /path/to/luajit --output results-luajit.json
```

From the supplied engine checkout, with the same wrapper choice as the interpreter:

```sh
POKEPORT_DATA_DIR=tests/fixture_data \
CBE_DOUBLES_MOD_DIR=/path/to/mod CBE_DOUBLES_UI_DIR=/path/to/mod \
CBE_TEST_ABILITIES_INSTALLED=1 \
texlua /path/to/mod/tests/texlua_wrapper.lua /path/to/mod/tests/doubles/RegressionTests.lua
```

Optional source/graphics reproduction commands remain documented in
`VALIDATION_1.0.10.md`; use the extracted 1.0 package as the warm-phase/mod root,
and a private diagnostic cache, never the live user cache.

`RELEASE_AUDIT_1.0.json` records baseline and changed/added-file hashes. Packaged
`validation/release_1_0/` contains working-tree/source/graphics logs; the separate
release evidence ZIP also contains the fresh-extraction rerun logs and final
archive identity. Older reports are history, not additional release test counts.
