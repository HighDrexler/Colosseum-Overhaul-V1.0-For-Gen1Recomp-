# Colosseum Overhaul 1.0 — cache options hotfix validation

## Baseline and delivery identity

Complete combined package based directly on the delivered Colosseum_Overhaul_v1.0.zip.
Baseline SHA-256: `0be5e426ef12e7008590e24d4acb49942d9143b3d04d89364a6cdf6659dc8db8`.
The manifest/display release remains **1.0**, and the installation ID remains
`COLOSSEUM_OVERHAUL`. The new ZIP name includes `Cache_Options_Hotfix`; manually
replace the prior package rather than relying on an automatic version increase.

## Correction

The initial title prompt was calling the startup worker, not the selector.
The generic exported prepare route also called the preparation executor. These
user-facing paths now open the options. Continue/New Game requests requiring
current-session model preparation also ask first, with a contextual team-only or
starter-only option. Already ready startup models pass through without new work.

The selector creates no build worker and starts no model-inventory scan. It requires
neutral confirmation input before accepting a new selection. Opening the screen
with A held, repeated accelerated ticks or a pointer press cannot simultaneously
select Quick Start. Cancelling the selector does not enqueue new startup prewarm
work, load a save, or execute a retained New Game/Continue callback.

The ordinary selector contains QUICK START / 30 NEW, FULL CATALOG and MAIN MENU.
The contextual selector adds CURRENT TEAM ONLY or STARTER MODELS ONLY. Explicit
team/starter preparation resumes the native action once; optional Quick/Full batch
operations return to the menu instead. Battle-readiness guards remain unchanged.

## Background-work clarification

Quick Start itself stops after its selected batch and waits for acknowledgement.
It does **not** automatically continue through the remaining Pokemon catalog.
`QuickCachePlanner.lua` and the persisted completion checks are unchanged.

There is separate pre-existing work: `ResidentPrewarm.queueStartup` queues likely
arena/trainer/shader dependencies, cached current-party bodies and team move-effect
resources. `BattleRuntime.runWorkFrame` pumps ordinary work on stable overworld
frames, restricts viewer work to requested information models, and retains the
separate explicitly requested Hard Cache path. Information viewers can request
source preparation for an uncached specific model. Battle readiness also prepares
uncached required models. This is not an automatic next-30 / full-roster queue.
ResidentPrewarm, BattleRuntime and PokemonActors are byte-identical to the baseline;
this hotfix neither enables catalog background baking nor claims no background work
occurs during gameplay.

## Executed checks

101 top-level suites pass under Lua 5.3 / texlua and real LuaJIT, with zero failures
or timeouts. `DoublesDisplayCompatTests.lua` remains explicitly unrun because its
historical producer fixtures are unavailable. It is not counted as a pass.

- CacheChoiceConsentTests: 302 checks, with real native Input/Hooks/StateStack,
  Gen I/II and Windows/Android platform profiles, controlled source/GPU fixtures.
  The new test fails against unmodified 1.0 on the initial automatic-start path.
- CacheScreenLayoutTests: 4,771 checks, including three/four-choice layouts across
  six viewport sizes, pointer areas, progress/errors and completion layouts.
- NativeModelCacheTests: 1,649 checks with real title-menu/stack/hooks fixtures.
- ReleaseLifecycleCompatibilityTests: 86 checks, including cancellation and
  reordered/localized title actions.
- Existing QuickCachePersistenceTests: 1,719 checks; 30-unit cap, persisted skip,
  restart/cross-save reuse and 270 source assets covering 502 appearances.
- Existing QuickCacheBatchControllerTests: 80 checks, including the explicit
  manual-batch boundary, completion acknowledgement and cancellation.

Separate native Gen I/II doubles integration passes 1,953 assertions under each
interpreter with abilities installed and graphics stubbed. All 222 Lua files pass
`texluac -p`. Fresh-delivery extraction is retested and checked for byte equality;
the separate evidence archive contains those final regression logs and ZIP hashes.

Linux LÖVE 11.5 / Xvfb software OpenGL renders manual, Continue and New Game
selectors through both native generation drawing/compositing pipelines. Additional
400x800 and 320x240 probes exercise portrait and small-window contexts. These use
synthetic menu/game state, not a ROM-backed live save. Screenshots are included
with the evidence. No font files or new platform runtime binaries are added; the
existing unchanged third-party Amuse reference executable is retained.

## Preservation and limitations

All 548 baseline packaged assets remain byte-identical; no baseline file is removed.
Only BattleCache, CacheScreen and exported cache entry routing change in runtime
code. Source extraction, cache formats/epochs, PokemonActors, QuickCachePlanner,
ResidentPrewarm, full UIMain, audio, ball facing, battle rules, arenas and all manifest
compatibility fields except descriptive text are unchanged. Existing test expectation
updates distinguish asking for consent from executing an already selected mode.

No actual-source cold bake or fresh-process source-data benchmark was repeated for
this hotfix; the source/cache backend is unchanged. Earlier reports are historical,
not additional hotfix measurements. The release does not claim a cold-extraction
speedup, phone loading duration, FPS change or live Windows/Android/iOS save playtest.
The tests use synthetic source/graphics unless identified as real LÖVE drawing.

## Install / reproduce

Close the game and replace the combined package with
`Colosseum_Overhaul_v1.0_Cache_Options_Hotfix.zip`. Keep the existing source import
and hard cache, and keep duplicate combined / standalone CBE-UI copies disabled.
No cache wipe, source reassignment or audio rerender is required.

From the extracted archive, with the supplied engine checkout:

```sh
python tests/run_headless.py --engine-root /path/to/gen1recomp --output results.json
python tests/run_headless.py --engine-root /path/to/gen1recomp --luajit /path/to/luajit --output results-luajit.json
```

The optional native doubles command is retained in VALIDATION_1.0.md. Graphics
probes use tests/retail/cache_screen_love with CBE_MOD_ROOT, CBE_ENGINE_ROOT,
CBE_RENDER_OUT, CBE_VIEW_GEN=1 or 2, and CBE_CACHE_CONTEXT=manual, continue or new.
`CACHE_OPTIONS_AUDIT_1.0.json` records changed/added file hashes. Current packaged
successful-test logs are under validation/cache_options_1_0; screenshots and
fresh-extraction logs are in the separate evidence ZIP.
