# Colosseum Overhaul 1.0.10 — validation and installation

Complete combined build based on `Colosseum_Overhaul_v1.0.9.zip`, preserving the same mod ID and existing compatible generated caches.

## Delivered behavior

Manual **BATTLE CACHE > QUICK START / 30 NEW** selects up to 30 incomplete/new source-model assets based on the selected save's party, ownership, caught/seen records, area and level relevance. Each successful model persists independently. Subsequent selections, including after a fresh process starts, exclude valid complete disk units. The counter is 270 unique source assets / 502 normal-shiny appearances; shared-body colour pairs do not use two batch slots. FULL CATALOG remains optional, while CONTINUE/NEW GAME use their required-team/starter preparation rather than triggering another batch.

Compact Pokémon/PC artwork again prioritizes the established Colosseum portrait atlas. Larger 3D viewers and strict battle-model selection remain. The Gen I cache screen bypasses the cartridge palette pass by rendering through the full-colour HUD stage; both generations use the revised layout.

## Automated regression and syntax

- **99 top-level suites pass under Lua 5.3/texlua and under real LuaJIT**, with zero failures and zero timeouts on the final tested source tree. The same 99-suite checks are repeated against the freshly extracted delivery archive.
- One historical suite, `DoublesDisplayCompatTests.lua`, is explicitly unrun because its original cbe1/cbe2/cbe3 producer fixtures are unavailable. It is not counted as a pass.
- Separate native Gen I/II doubles integration passes **1,953 assertions under each interpreter**, with abilities installed. This exercises real engine battle rules and callbacks with graphics stubbed.
- **220 Lua files** pass `texluac -p`. The manifest parses and agrees with `main.lua` at 1.0.10. ZIP CRC checks, root entry checks and extracted-tree hash comparison pass.

The three new top-level suites are:

| Suite | Checks | What it exercises |
| --- | ---: | --- |
| QuickCachePersistenceTests | 1,719 | Actual actor/cache/planner code with synthetic source/graphics. Both-generation save relevance; 30-unit cap; partial completion; newly instantiated runtime reading the same disk; exhaustion of 270 units / 502 appearances without repeat work; cross-save reuse; individual damaged/missing sidecars; no save mutation. |
| QuickCacheBatchControllerTests | 80 | Actual controller/planner/scheduler with controlled expensive preparation. Inventory worker, retries, successful versus failed units, completion acknowledgement, next batch, cancellation, fresh controller, team-only Continue and already-complete catalog. |
| CacheScreenLayoutTests | 3,391 | Actual layout at six sizes and multiple states; text and button bounds/non-overlap; pointer hit areas; no RGB cache text in the native small-canvas draw methods. |

The updated compact-portrait routing suite passes 65 checks. Existing scheduling/native title-menu tests were adapted to distinguish explicit new batches from required startup warming, and to exercise the HUD hook. Existing audio, arena, facing, abilities, rewards, switch, shiny and model tests remain in the regression run.

## Actual-source cold / fresh-process reuse

An optional source check used the supplied GC6E01 CISO through bounded reads and a private on-disk diagnostic cache. The three completed source units were:

- Voltorb normal: ordinary source geometry/action cache; shared shiny counterpart also checked.
- Pikachu shiny: shared model with source-authored shiny colour recipe; normal counterpart also checked.
- Typhlosion shiny: separate rare-source model asset.

The units' geometry, metadata, textures and supported authored animation sidecars were generated through the actual preparation API. Graphics objects in this test are mocked. Then the warm test was launched in a **new operating-system process** against the same files. The warm process treats any source opener call or cache write as an error.

**Fresh-process result: 0 source-disc opens, 0 generated-cache writes, 0 bytes written.** The exact requested appearances and shared counterparts were acquired using the existing files. The log records 496 cache reads / 17,910,836 bytes read for validation and scene loading. Reading/uploading existing data is not regeneration.

These are three actual source units, not a full-catalog mobile benchmark. An earlier diagnostic attempt involving Charizard's separate shiny asset was interrupted at the harness time limit and is not counted as a completed cold source check. Its partial private output is not included. The completed units' initial and repeat logs distinguish real builds from reuse.

The source extractor has not been optimized by this release. No model-count, animation-sampling or quality reduction is hidden in the persistence result. Cold-model generation remains expensive; no phone/Windows startup time or FPS is certified.

## Real LÖVE graphics checks

LÖVE 11.5 was run on Linux under Xvfb/software OpenGL, using the supplied engine checkout.

1. The native **Gen I `Game.draw`** and **Gen II `Game2.draw`** pipelines, Renderer compositing and the shipped cache HUD callback rendered the choice screen. The game/menu state was synthetic and no ROM-backed gameplay was run. Captures show the ordinary RGB UI after the palette pass instead of the damaged small-canvas Gen I colors.
2. Actual CacheScreen drawing produced desktop, small-window and portrait/mobile-sized previews. Layout tests cover 320×240, 640×360, 400×800, 800×400, 1168×980 and 1920×1080. These are resolution checks, not device tests.
3. The shipped compact portrait functions and actual packaged images handled **1,004 portrait requests** (251 species × normal/shiny × two generation contexts), loading **502 appearance images with zero 3D-model requests**. A sample headshot gallery was rendered. This verifies routing and file availability, not a visual accuracy inspection of every shiny against retail.

Screenshots and logs are in the separate evidence archive. The reproducible optional LÖVE probes are under `tests/retail/cache_screen_love/` and `tests/retail/portraits_love/`.

## Preservation and package audit

No baseline file is removed. All **548 packaged assets are byte-identical to v1.0.9**. No source ISO/CISO/7z, newly generated model cache, extracted source textures, generated soundtrack, font files or platform runtime binaries are added. The existing mod ID, required import and cache revisions are unchanged. The audio renderer, model extractor, sampling, source shader, Poké Ball facing and battle rules are unchanged.

`MERGE_AUDIT_1.0.10.json` records the baseline archive hash plus changed/added file hashes. Historical reports remain history, not evidence that every historical device test was repeated. Current machine-readable logs are under `validation/chunk_cache_v1/`.

## Installation

Close the game. Replace the existing combined Colosseum Overhaul ZIP; keep standalone CBE/UI and older combined duplicates disabled. **Do not clear the hard cache or source import.** No audio rerender is needed. Open BATTLE CACHE, select QUICK START / 30 NEW, then return to the main menu when it reports Batch saved. Each further selection builds the next relevant uncached chunk.

B / MAIN MENU cancels title preparation while retaining all completed units. An unfinished unit may still need work on its incomplete components. A missing, incompatible or detectably damaged cache requires repair; this is distinct from rebuilding a valid model on every launch. Cache files deleted through device storage cleanup or a different mod-ID installation are not magically recoverable. Persistent storage and graphics memory are separate: GPU data still loads each session and remains bounded on mobile.

## Reproduce

From the extracted mod:

```sh
python tests/run_headless.py --engine-root /path/to/gen1recomp --output results-texlua.json
python tests/run_headless.py --engine-root /path/to/gen1recomp --luajit /path/to/luajit --output results-luajit.json
```

From the supplied engine checkout:

```sh
POKEPORT_DATA_DIR=tests/fixture_data \
CBE_DOUBLES_MOD_DIR=/path/to/mod CBE_DOUBLES_UI_DIR=/path/to/mod \
CBE_TEST_ABILITIES_INSTALLED=1 \
texlua /path/to/mod/tests/texlua_wrapper.lua /path/to/mod/tests/doubles/RegressionTests.lua
```

For a private source test on a POSIX desktop, from the mod directory, run these as separate processes. Use a new diagnostic directory, never your live game cache; do not redistribute its source-derived output:

```sh
CBE_CACHE_CHECK_PHASE=cold CBE_SOURCE_CISO=/path/to/GC6E01.ciso \
CBE_SOURCE_CACHE=/path/to/private-check-cache \
luajit tests/retail/ChunkPersistenceSourceChecks.lua

CBE_CACHE_CHECK_PHASE=warm CBE_SOURCE_CACHE=/path/to/private-check-cache \
luajit tests/retail/ChunkPersistenceSourceChecks.lua
```

For the graphics probes, create an output directory and run the actual LÖVE 11.5 executable:

```sh
CBE_MOD_ROOT=/path/to/mod CBE_ENGINE_ROOT=/path/to/gen1recomp \
CBE_RENDER_OUT=/path/to/screenshots CBE_VIEW_GEN=1 \
love /path/to/mod/tests/retail/cache_screen_love
# Repeat with CBE_VIEW_GEN=2.

CBE_MOD_ROOT=/path/to/mod CBE_RENDER_OUT=/path/to/screenshots \
love /path/to/mod/tests/retail/portraits_love
```

The remaining live check is the user's actual Gen I/II launcher/save combination on desktop/mobile: batch duration, cancellation/relaunch with the same cache, party-card placement, and later first encounters. This release is not a claim that those device tests have already been performed.
