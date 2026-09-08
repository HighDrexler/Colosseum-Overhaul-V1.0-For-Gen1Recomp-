# Colosseum Overhaul 1.0 — cache reuse hotfix validation

## Baseline

- Baseline: `Colosseum_Overhaul_v1.0_Cache_Options_Hotfix.zip`
- SHA-256: `0202d794a78cf40e7f1cd6cd32254a0a8f2dc5c785fa2b99dc6c621856bfbdc9`
- Mod ID/version retained: `COLOSSEUM_OVERHAUL` / `1.0`

## Targeted contracts

The cache-reuse regression suite verifies:

- exactly 30 valid persisted model units enable reuse;
- 29 valid units do not enable reuse;
- a full persisted catalog enables reuse and the eligibility probe stops once the
  30-unit threshold is proven rather than exhaustively validating all 270 units;
- eligibility scanning performs no model preparation and starts no 30-new batch;
- contextual Continue reuse warms only the current team and resumes Continue once;
- generic/title reuse warms only the current team and prevents an immediate second
  startup cache prompt;
- reusable-cache UI places `REUSE CACHE` first;
- the pre-decision UI shows a non-action `CHECKING SAVED CACHE` row and does not flash
  `QUICK START / 30 NEW` or `CURRENT TEAM ONLY` while the read-only probe is in flight;
- transient information-model error states contain no `MODEL ERROR` UI label while
  the normal pending state can still display `LOADING MODEL`.

Targeted standalone results in this environment:

- `CacheReuseStartupTests.lua`: **27 checks PASS**
- `CacheScreenLayoutTests.lua`: **6,887 checks PASS**
- `ModelStatusPlaceholderTests.lua`: **4 checks PASS**
- `QuickCacheBatchControllerTests.lua`: **80 checks PASS**
- `QuickCachePersistenceTests.lua`: **1,719 checks PASS**

## Package-wide headless regression

`tests/run_headless.py` under texlua:

- **98 suites PASS**
- **0 FAIL**
- **0 TIMEOUT**
- **6 NOT RUN**

The six not-run suites are environment/fixture limited, not reported as passes:

- `BattleAudioNativeTests.lua` — native engine checkout not supplied
- `CacheChoiceConsentTests.lua` — native engine checkout not supplied
- `DoublesDisplayCompatTests.lua` — historical producer fixtures unavailable
- `NativeModelCacheTests.lua` — native engine checkout not supplied
- `ReleaseLifecycleCompatibilityTests.lua` — native engine checkout not supplied
- `SingleBattleSwitchUITests.lua` — native engine checkout not supplied

The exact headless JSON and console log are packaged under
`validation/cache_reuse_1_0/`.

## Structural checks

- Every packaged `.lua` file parses successfully with `texluac -p`.
- `manifest.json` parses successfully.
- Baseline assets: 548 files.
- Hotfix assets: 548 files.
- Runtime asset byte comparison: **548 / 548 identical**.

## Validation boundary

This environment does not execute the user's Windows/Android Gen1Recomp runtime,
ROM-backed save, Android storage backend, or OpenGL ES driver. Therefore this release
does not claim a live-device startup-time measurement or visual-device pass. The
implemented contracts are source-validated, headless-tested, and package-validated;
the final visual check should confirm that a cached Android launch shows REUSE first
and that the former brief MODEL ERROR frame is now blank until the 3D model appears.
