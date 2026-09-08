# Colosseum Overhaul 1.0 — cache reuse + transient model-status hotfix

This hotfix is based directly on `Colosseum_Overhaul_v1.0_Cache_Options_Hotfix.zip`
(SHA-256 `0202d794a78cf40e7f1cd6cd32254a0a8f2dc5c785fa2b99dc6c621856bfbdc9`).
The manifest/display version and mod ID remain **1.0** / `COLOSSEUM_OVERHAUL` so this
is a manual replacement package, not a higher-version updater release.

## UI model handoff

- Colosseum information-model cells no longer flash **MODEL ERROR** during the brief
  acquire/render handoff seen before a valid model becomes drawable.
- A true pending state may still show **LOADING MODEL**. If the provider reports an
  error/failure state, the model cell stays visually empty rather than displaying an
  error label or falling back to another artwork provider.
- Persistent provider/battle readiness diagnostics remain available through the
  existing cache/error logging and strict battle readiness paths.

## Reuse existing model cache

- Every title/cache chooser now performs a **read-only existing-cache eligibility
  check** before allowing a cache mode to be selected. While that check is running,
  the UI shows **CHECKING SAVED CACHE** instead of briefly presenting Quick Start or
  Current Team as the apparent default.
- Once **30 or more valid persisted model units** are proven, **REUSE CACHE** becomes
  the **top option**. A completed Full Catalog naturally qualifies as well.
- The eligibility probe stops as soon as 30 valid model units are proven. It does not
  extract source models, build meshes, upload GPU resources, or write model cache data.
- Selecting **REUSE CACHE** never invokes the `QUICK START / 30 NEW` planner. It warms
  only the exact current-team models (or native starters for New Game) needed for the
  requested startup path. If one of those required models is genuinely absent, that
  individual required model can still be prepared so strict Colosseum-only rendering
  remains intact.
- Selecting reuse from the automatic/manual title chooser performs that narrow team
  warm immediately, so choosing Continue afterward does not trigger a second cache
  chooser just because the same team was not resident yet.
- Caches below 30 valid model units retain the existing Current Team / Starter Models,
  Quick Start, Full Catalog and Main Menu choices.

## Preservation

- Quick Start remains **30 new uncached model units per explicit selection**.
- Full Catalog remains optional and unchanged in scope.
- No cache epoch/format bump and no cache wipe are introduced. Existing generated
  files are reused.
- Source extraction, animation sampling, Pokémon actors/models, shiny handling,
  arenas, battle logic, doubles, abilities, rewards, audio and Poké Ball fixes are
  otherwise unchanged.
- All **548 packaged runtime assets are byte-identical** to the baseline hotfix.

## Installation

Close the game and replace the previous combined `COLOSSEUM_OVERHAUL` package with
this ZIP. Keep the existing Pokémon Colosseum source import and generated cache. Do
not enable an older combined package or standalone CBE/UI pair beside it.
