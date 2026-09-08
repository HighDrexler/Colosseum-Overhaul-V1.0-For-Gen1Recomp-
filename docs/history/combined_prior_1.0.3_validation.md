# Colosseum Overhaul 1.0.3 / Colosseum Inspired UI Overhaul 2.5.3
## Validation — 7 September 2026

## Executed checks

The complete working combined tree passed **75 top-level headless test suites**,
with zero failures and zero timeouts. The complete standalone UI tree passed
**6 top-level headless suites**, with zero failures and zero timeouts. One
historical combined suite was not run, as described below.

All **191 Lua files** across the two complete trees parsed with texlua. Literal
`mod:read("path")` references resolve in each respective package. Both packages
retain their mod IDs and root entry points. The shared UI runtime, theme, portrait
cache, doubles UI and display-compatibility libraries are identical between builds;
the standalone package also contains the identical ShinySupport identity helper.

The newly added suites exercise shipped modules/functions using controlled
engine, graphics and source-reader fixtures:

| New suite | Passed checks | Coverage |
| --- | ---: | --- |
| ShinyIdentityAndMetadataTests | 1,827 | Explicit/nested shiny flags, classic DVs, bounded cyclic records, no state edits, synthetic PKX channel routing/ARGB brightness, alpha preservation, all 251 supported Dex source/cache identities. |
| ShinyActorCacheTests | 1,036 | Normal/shiny actor separation, shared geometry versus dedicated source variants, per-draw uniform reset, source metadata migration, offline reload, retries and pinned live actors. GPU objects are mocks. |
| ShinyExtractorContractTests | 547 | Normal/shiny archive and cache-path contracts across the supported Dex table, extraction stamps, real manifest writer, cooperative metadata reader on synthetic source bytes. |
| ShinyHardCacheTests | 17 | Synthetic geometry through the real binary-pack/cache path, mixed party/storage preparation, metadata upgrade, dedicated variants, reused normal bytes, retryable failed writes, v5 readiness marker. |
| ShinyUIPipelineTests | 53 | Shipped information-view functions for both generation labels and five surfaces; correct variant, non-mutating sprite context, ready/pending/error fallback, and old-CBE capability handling. Also run in standalone UI. |
| ShinyInformationSchedulerTests | 11 | Simulated Android scheduling, distinct variant keys, pruning only unstarted jobs, serialized active source decoding, cooldown/retry and cancellation. |
| ShinyDoublesPresentationTests | 21 | Four active same-species normal/shiny slots, mock per-actor draw state, original slot records retained, resolved-sprite fallback and recovery without gameplay messages. |
| FreeCameraLayerTests | 57 | Additive offsets on changing cinematic bases, bounds/reset/modal guard, mouse/touch input, engine wheel forwarding, and quadrant-safe angle fallback. Inputs and LuaJIT atan behavior are simulated. |
| ReleaseDefaultsAndBallOrientationTests | 66 | Default-ON/missing settings, explicit saved-OFF preservation, removed TEST/experimental flags, source-ball inward transforms for both teams and lanes on three stage axes. |

The existing suites also passed, including theme persistence, opponent panel and
target mapping, portrait crop reuse, Gen I Pokédex submenu suppression, cache
scheduling, abilities integration and camera/source contracts. The synthetic
hard-cache fixture confirmed that valid normal binary outputs were not rewritten
and no Pokémon GPU meshes/textures were created by disk-only preparation.

## Cache upgrade contract

The normal geometry extraction revision remains **37**. Normal model, action,
texture and source-audio caches are not globally invalidated. Native shiny
metadata is added where needed; dedicated shiny source models use their own cache
subfolders. The Hard Cache Save completion marker intentionally advances from
v4 to **v5**, which certifies the new shiny-aware preparation contract. An old v4
marker is not accepted as proof that the new shiny data was already prepared.

Keep existing caches and the imported Colosseum source. UPDATE SHINIES in the
CBE menu requests missing party/storage variant preparation, not an all-cache
wipe or full audio rebuild. First-use preparation can still incur work. A cache
key or native-color parameter check does not prove a real-world loading speedup.

## Reproduce the top-level tests

With Python 3.9+ and texlua available on PATH, run from either extracted package:

```text
python tests/run_headless.py --output validation-results.json
```

The test-only `tests/texlua_wrapper.lua` adapts several Lua 5.1-style APIs for
Lua 5.3 fixtures. Neither the wrapper nor the Python test runner is loaded by the
mod's main entry. The original root `run_all_tests.lua` is retained and clearly
marked as a historical Windows/LÖVE integration runner; it is not exhaustive and
was not the runner used for these results.

## Not run and limitations

**No live LÖVE/game session, retail Colosseum model extraction/rendering, GPU shader
compilation, or physical Windows/Android/device benchmark was available.** The
native shiny implementation follows source-model metadata and dedicated archive
routing, but actual in-game palettes and every species' appearance have not been
visually verified here. Camera framing, wall occlusion and Poké Ball orientation
have mathematical/fixture coverage, not a new gameplay recording.

Lua 5.1/LuaJIT execution was unavailable. Parsing and headless execution used
LuaTeX 1.18.0's Lua 5.3 environment with the packaged test-only wrapper. A test
simulates LuaJIT's one-argument atan behavior; that is not a native LuaJIT run.
Frame budgets are cooperative targets, not preemption: an indivisible source
parse, filesystem read or GPU upload can exceed the requested slice.

`DoublesDisplayCompatTests.lua` was not run because its original cbe1/cbe2/cbe3
producer fixture directories are absent. No replacement fixtures were fabricated
for that historical suite. The engine/ROM-dependent `tests/doubles` subtree was
also not executed. These exclusions are not counted among the passing suites.
Removing the experimental flag is the requested release-label change, not a
universal stability certification. No FPS or cache-speedup percentage is claimed.

## Native color-format references

The implementation reads source PKX metadata, rather than inventing a global shiny
palette. Format references inspected during this pass:

- StarsMmd, Blender-Addon-Gamecube-Models, `shared/helpers/pkx.py`: four big-endian
  routing selectors, Colosseum ARGB brightness order and piecewise brightness
  conversion. https://github.com/StarsMmd/Blender-Addon-Gamecube-Models/blob/main/shared/helpers/pkx.py
- PekanMmd, Pokemon-XD-Code, `Objects/file formats/PKXModel.swift`: Colosseum's
  final 20-byte filter region and ARGB decoding.
  https://github.com/PekanMmd/Pokemon-XD-Code/blob/master/Objects/file%20formats/PKXModel.swift

These public code references establish the implemented metadata contract; they
are not substitutes for testing actual imported assets on the target renderer.
