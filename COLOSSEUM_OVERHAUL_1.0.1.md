# Colosseum Overhaul 1.0.1 — cache/performance/device-compatibility sweep

Requested scope: audit the caching and Hard Cache Save systems across Gen I
and Gen II for the widest practical device compatibility, without trading
away fidelity, and fix anything found not pulling its weight. This was an
audit-first pass -- the existing caching stack is the product of a long,
real-device-informed Android hardening effort (CBE 1.7.2 through 1.9.18),
and constants tuned against that history were treated as load-bearing, not
guessed at.

## What was checked

Read in full: `lib/CacheManager.lua`, `lib/RuntimeMeshCache.lua`,
`lib/ResidentPrewarm.lua`, `lib/ArenaCacheIdentity.lua`,
`lib/GeneratedAssets.lua`, `lib/TrainerPerformance.lua`,
`lib/BattleSettings.lua`, and every historical Android/performance build doc
(`docs/cbe/ANDROID_AUDIT_1.7.2-android.1.md` through
`CBE_1.7.10-android-performance-polish.1.md`, `CBE_1.7.21-performance-pass.1.md`,
`CBE_1.9.16` through `CBE_1.9.18`), plus the caching-contract test files
(`HardCacheStorageQueueTests`, `TrainerSourceCacheTests`,
`MenuPrewarmBoundaryTests`, `InformationMenuPerformanceTests`,
`TrainerStreamingTests`, `DoublesPerformanceTests`,
`DoublesPerformanceUITests`).

## What was already in good shape (left alone)

- **Every genuinely GPU-resident cache is bounded and evicting**:
  `Trainer.sceneCache` (LRU, true lowest-use-serial eviction),
  `PokemonActors.scenes` (priority + soft-cap hybrid: party protected, then
  most-recent-use beyond the cap). Both have Android-specific (smaller)
  caps, tuned across nine dedicated Android builds -- not touched.
- **Hard Cache Save** (`CacheManager.hardCacheSave` → `ResidentPrewarm.queueHardCache`)
  is safe to interrupt, re-entrant, marker-gated against stale/incompatible
  extractor revisions, and paced through the same scheduler as everything
  else. Its exact scheduling gate (only pumps during real overworld, an
  active information-viewer lease, or while Hard Cache Save itself is
  running) is locked in by `MenuPrewarmBoundaryTests` and passes. Nothing
  here needed a change.
- **Gen I/Gen II symmetry**: confirmed no generation-specific branching
  anywhere in `CacheManager.lua` or `ResidentPrewarm.lua` -- caching keys on
  species/arena/trainer identity, which is shared 3D content across both
  generations. No asymmetry to fix.
- **Incremental GC pacing, transition-frame protection, viewer-lease
  scheduling** -- all present, all Android-tuned, all still passing their
  locked-in test contracts.

## What looked like gaps but weren't (investigated, not fixed)

- `GeneratedAssets.lua`'s `infoCache`/`infoRegistry` and
  `RuntimeMeshCache.lua`'s `luaMemo` have no explicit size cap on any
  platform. Read both implementations in full before deciding: both are
  keyed by generated-asset *path* (one small `{type,size}` row per arena/
  species-action/move manifest), so their real ceiling is the finite number
  of distinct assets the whole game can generate -- a few thousand small
  entries at most, not unbounded growth. `infoCache`/`infoRegistry` are
  additionally kept in permanent lockstep today (every write updates both),
  so `infoCache` isn't even doing separate work from the registry. Adding
  eviction here would add real code and real risk (miscounting evictions,
  breaking Hard Cache Save's full-registry iteration) for no measurable
  memory benefit. Left alone.
- Considered hooking `love.lowmemory` as a cross-platform (not just
  Android) low-memory signal to trigger an emergency cache trim. Checked the
  engine source first: `gen1recomp-dev/main.lua` already defines
  `love.lowmemory()` itself, and it's load-bearing for a *different*
  purpose -- Switch/mobile suspend-resume recovery (`Game:onResume()`:
  input reset, engine resync, chip-audio dedup). There's no mod-facing
  event/hook that forwards it. Defining our own `love.lowmemory` would
  either silently do nothing (if the engine's own definition wins) or break
  suspend-resume recovery (if ours did). Not implemented -- flagging this as
  a real, confirmed gap (no genuine OS memory-pressure response exists for
  any platform) that would need engine-level support to close safely, not
  something a mod can safely add on its own.

## What was fixed

**`GoldCompat.patchShapeHudCompat`** (`UIMain.lua`) ran on every single Gen I
battle-HUD-draw frame and did an uncached `modRef.find(modId)` +
`V.require("OverworldBattle")` every time, regardless of whether the
installed mod set had changed since the last frame -- pure per-frame
overhead with no caching at all, for a mod (Dramatic/Dramaless Shape) that
essentially never changes mid-session. The file already has an established,
working pattern for exactly this (`connectBattleArts`, a few hundred lines
above it): resolve once, cache the handle, and only re-resolve when
`GoldCompat.__presentationProviderEpoch` actually changes (a real
mod-list/options-change event, not a per-frame poll). Applied that same
pattern here, keyed per `patchFlag` since the function serves two distinct
shape mods. Every other call semantic (direct `modRef.find` call, `pcall`
only around `V.require`, the idempotent hook-wrapping logic below it) is
unchanged.

## Verification

Full 158-file parse check, all 60 top-level suites, the
`tests/doubles/PresentationTests.lua` (374 + 382 assertions) and
`RegressionTests.lua` chain (1951/1953, same known pre-existing Psych Up
issue as 1.0.0, untouched by this change) all re-run and pass identically to
1.0.0 after this change -- confirming it's purely a caching optimization
with no behavior change. See `VALIDATION_COLOSSEUM_OVERHAUL_1.0.0.md` for
the full contract list this build still satisfies; nothing in it needed
updating since no test's expected behavior changed, only call frequency for
one internal helper.

## Bottom line

The caching/device-compatibility system here is already unusually mature --
years of real Android-device-informed iteration produced a genuinely tiered,
bounded, resumable system, and blindly re-tuning its calibrated constants
without real-device telemetry would be more likely to regress it than
improve it. This pass found and fixed the one real, safe, zero-risk
mechanical inefficiency (an uncached per-frame lookup), confirmed Gen I/Gen
II parity, and confirmed the two "unbounded-looking" caches are actually
fine in practice. The one genuine open gap -- no real OS-level low-memory
response on any platform -- is an engine-level limitation, not something
this mod can close alone; worth raising with whoever maintains
`gen1recomp-dev` if it becomes a real-device problem.
