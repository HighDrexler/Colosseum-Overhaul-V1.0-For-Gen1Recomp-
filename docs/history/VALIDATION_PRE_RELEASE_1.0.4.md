# Colosseum Overhaul 1.0.4 / UI Overhaul 2.5.4
## Performance, merge and arena validation — 7 September 2026

## Delivery scope

The combined package merges the earlier 1.0.3 single-battle switch hotfix, the
newer same-version shiny/camera/release build supplied during this task, and the
current performance, cache controls, target-default and arena fixes. A file audit
found **zero missing files from either complete combined input**. Intentionally
modified runtime files are listed in MERGE_AUDIT.json. This is not a rollback to
an older performance-only branch. All six shared UI/runtime helper files are
byte-identical in the combined and standalone UI deliveries.

Retained functionality includes native shiny parameters/dedicated variant routes;
normal/shiny identity separation; additive free-camera height, pan and bounded
zoom; cinematic camera sequences; Poké Ball orientation; default-ON doubles and
abilities with saved-OFF preservation; single-battle switch prompt and optional
cancellation; doubles encounter isolation, per-KO progression, abilities and turn
flow; target-to-portrait identity; theme persistence; source-resolved artwork;
and previous portrait/caching/presentation changes. No save file is modified.

## Changes tested

**Gen 2/per-frame scheduling.** The loader recognizes Gen 2's directly owned
world even when the top of its state stack is nil. A dedicated Game.update wrapper
runs preparation after the real update and all fixed steps, once per update.
It preserves return tuples, propagates native errors, avoids nested duplicate
work and observes state changes across input/encounter transitions. The old
input.step seam remains a compatibility fallback, not the main work scheduler.

**Selected menu models.** Source-backed normal and shiny preparations can finish
while an information viewer remains open. The UI keeps its resolved-sprite
fallback while waiting. Preparation uses cooperative checkpoints in decompression,
HSD traversal, vertex processing and serialization/packing. Active source writers
are serialized, errors have retry cooldowns, and cancellation releases unpublished
resources/ownership. Static-first model presentation and delayed native idle
animation remain. Source/model ownership and battle rules are unchanged.

**Extraction work.** Automatic Pokémon pose extraction no longer decodes the full
scene-union result when the existing policy will discard it for a valid single
character root. Forced scene diagnostics and both fallback routes remain.
Immutable parse data is reused within an extraction; suspended requests own
separate options/session tables. Source geometry revision remains 37.

**Cache controls.** HARD CACHE SAVE now opens CACHE PREPARATION. PREPARE CURRENT
TEAM prepares the current party's native bodies/actions and current-move assets;
PREPARE TEAM + PC also prepares unique stored species. The smaller team scope
skips installation-wide registry enumeration. Pause/resume keeps the in-memory
job and repeated clicks do not restart it or change its scope. Completed files
remain reusable after restart, but an unfinished queue is not automatically
persisted across restarts: request preparation again to resume by reusing files.
The full shiny-readiness marker remains v5. Team readiness has a separate marker.
No 240/900 ms sleep is inserted after every small explicit preparation batch.

**Doubles default selection.** The top legal enemy HP card is selected first.
Only the initial UI index changes; legal target arrays and native slot IDs are
not reordered. Navigation, highlights, attack submission and damage recipients
are checked, including single legal enemies and ally-only target lists.

**Arena fixes.** Opaque source RGB and vertex-alpha visibility are separated in
both arena shaders. Opaque Orre walls no longer become invisible because their
vertex alpha is zero; texture alpha/cutouts and native XLU vertex alpha remain.
Packed/fresh material decisions agree via the native XLU flag. Water's exact
source crowd banks bypass the older recipe-specific raw-height outlier rule.
A targeted Water packed-sidecar revision repairs old crowd caches. Canonical
source arena data, other arena sidecars, Pokémon caches and source audio do not
receive a global epoch bump or wipe. Existing source imports remain usable.

## Executed regression results

- Combined: **82 top-level suites passed**, zero failures and zero timeouts.
  One historical suite was explicitly not run; details below.
- Standalone UI: **7 suites passed**, zero failures/timeouts/exclusions.
- Native Gen I/II doubles integration with abilities installed: **1,953
  assertions passed**, using the actual engine kernels and ROM-free fixtures.
- Syntax: **185 combined Lua files + 16 standalone Lua files parsed**, zero errors.
- Shared UI files and literal mod:read paths were checked in both package trees.

Selected focused counts (included in the top-level totals, not additional suites):

| Suite | Passed checks |
| --- | ---: |
| PerformanceFrameBudgetTests | 46 |
| PerformanceInformationLoadingTests | 52 |
| CachePreparationScopeTests | 26 |
| ExtractorDecodeEconomyTests | 111 |
| ArenaVisibilityRegressionTests | 23 |
| DoublesOpponentHudOrderTests | 767 |
| SingleBattleSwitchUITests | 349 |
| ShinyActorCacheTests | 1,036 |
| ShinyUIPipelineTests | 53 |

The singles suite uses real engine queue/ChoiceBox/PartyMenu logic and instrumented
graphics. It checks prompt rendering, NO/B cancellation, optional party-picker
cancellation, actual send-out completion and mandatory faint replacement.
Graphics objects in other suites are controlled fixtures, not a live driver.

## Actual retail-source checks

The user's previously provided GC6E01 CISO was read locally. The original shipped
FSYS/HSD/GX extraction path decoded the Water and Orre scene models; the modified
packed builder was then run against that canonical source output. No retail
archive, texture, model cache or disc bytes are included in these deliveries.

- Water: 199 source groups; 57 authored crowd groups. The fixed packed builder
  retains **all 57**, with zero crowd outliers. The previous height filter would
  remove 35 upper-bank groups. Other existing scene filters remain unchanged.
- Orre: 48 source groups and 45 retained packed groups. **16 opaque source groups,
  containing 15,072 vertices, have zero vertex alpha throughout.** The new gate
  preserves their visibility while retaining source RGB. Orre's four crowd
  groups remain. Source-to-packed alpha decisions matched for all 48 groups.
- Source-to-packed alpha decisions also matched for all 199 Water groups.

### Controlled Pokémon extraction comparison

Growlithe (Dex 58) was extracted from the actual source archive using the newer
incoming 1.0.3 source and the modified source, in this server's texlua/Lua 5.3
process. Source/options were identical: auto decode, skin fix, render-pass filter,
height 16. Writes were captured in memory during the CPU measurement, then saved
for comparison. These are single-run CPU measurements, not device loading times.

| Path | Measured CPU time |
| --- | ---: |
| Incoming 1.0.3 | 29.008578 seconds |
| Modified 1.0.4, cooperative 3 ms target | 12.403086 seconds |

All **41 non-diagnostic output files were byte-identical**, including geometry,
native action payloads, textures and generated model/cache data. Only the
flight-recorder timestamp and extraction diagnostic text differed. The new run
resumed 3,067 times and yielded 3,066 times. Its largest measured slice was
**88.907 ms**: this explicitly demonstrates why a 3 ms target is not a guaranteed
frame-time cap. A separate Pikachu baseline attempt exceeded the command budget
and is excluded; no Pikachu speedup is claimed.

## Reproduce the packaged tests

Python 3.9+ and texlua on PATH, from an extracted package:

```sh
python tests/run_headless.py --engine-root /path/to/gen1recomp --output results.json
```

The engine checkout must contain the native tests.modkit fixtures. Without
--engine-root, the runner explicitly skips the native singles suite rather than
pretending it passed. The test-only texlua wrapper supplies Lua 5.1-style APIs;
it is not loaded by the mod. The historical root run_all_tests.lua is not the
runner used for these results.

For the additional native doubles integration, from the engine checkout:

```sh
POKEPORT_DATA_DIR=tests/fixture_data \
CBE_DOUBLES_MOD_DIR=/path/to/combined \
CBE_DOUBLES_UI_DIR=/path/to/combined \
CBE_TEST_ABILITIES_INSTALLED=1 \
texlua /path/to/combined/tests/doubles/RegressionTests.lua
```

The retail source checks require the user's private source assets and are not
part of the ROM-free top-level suite.

## Boundaries and remaining bottlenecks

No live LÖVE/game session, GPU shader compilation, in-game arena screenshot, or
physical Android/Windows FPS benchmark was performed. The real source inspections
establish the data and filter defects, but do not constitute visual confirmation
on the user's renderer. LuaJIT/Lua 5.1 execution was unavailable; execution used
texlua/Lua 5.3 with the test-only compatibility wrapper.

Cold source extraction still computes native action banks. Individual filesystem
reads/writes, Lua parsing/GC, GPU uploads, shader compilation, and existing arena/
trainer/action-bank loads can exceed cooperative targets. This build addresses
specific demonstrated scheduling and redundant-work defects; it is not a claim
that every battle is instant, mobile caching cannot take a long time, or all
freezing is eliminated. Team-first preparation reduces scope; it does not make
uncached models computationally free. Restoration of source crowd/architecture is
not disguised as a performance improvement.

DoublesDisplayCompatTests.lua remains excluded because its historical
cbe1/cbe2/cbe3 producer fixture directories are absent. No replacement fixtures
were fabricated. All other listed top-level suites and the native doubles run
were executed. No whole-cache purge, save edits, model-source switching or battle
logic simplification is required for this update.
