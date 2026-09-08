# Colosseum Overhaul 1.0: runtime cache and camera release build

Based on the supplied `Colosseum_Overhaul_v1.0_Cache_Reuse_Hotfix.zip`.
The mod ID and release version remain `COLOSSEUM_OVERHAUL` / `1.0`.

## Runtime loading behavior

The reported popup came from `BattleCache.holdBattle`: whenever the current
battlers lacked completed session preparation, it pushed the same opaque cache
state used at startup. This included a body already resident from a preview but
still missing completed battle action sidecars. Renderer errors used that screen
too. Full-catalog preparation avoided most of these misses by preparing the
entire catalog in advance.

Runtime readiness now prepares the exact required models before allowing the
native battle update to run. It never pushes a cache-screen state. During a cold
load, the last presented game frame remains visible; model decoding, disk work
and GPU upload can still cause a pause. This is synchronous buffering, not a
claim of background loading or uninterrupted frame rate. Long preparation
checkpoints pump OS messages without dispatching battle input or drawing a
loading panel. The worker's existing cancellation/error cleanup is retained.

This applies to singles and four-slot doubles, including replacement/Transform
identities, exact shiny variants, and reloading an evicted model. Preparation
does not advance turns, HP, rewards or battle events. The startup options retain
their existing scope and behavior: Reuse/Team/Starter, Quick Start / 30 New, and
Full Catalog. No extra catalog batch starts just because an encounter needs a
model.

A genuine model/source/GPU failure holds battle updates and shows a compact
error notice over the battle. It does not open a cache/loading screen. Failed
preparation automatically retries with a bounded backoff; A retries immediately,
and START exits the game. Distinct error details go to the existing generated
`build/model-cache-error.txt` log. Successful normal loading shows no notice.
Errors do not authorize sprite substitution or incorrect shiny appearances.

## Cache and performance changes

- A memory-only readiness API reuses the actor service's completed-session
  certification. Warm native updates do not recheck disk manifests or rerun
  preparation merely because another caller prepared the same model. Explicit
  readiness revocation takes precedence over the controller's older memo.
- Cold texture validation checks the actual file size without reading an extra
  complete RGBA payload immediately before GPU upload. The same missing/short
  payload conditions still fail validation. This retains the previous size
  check; it does not introduce or claim content hashing of textures.
- Duplicate active identities are prepared once. Normal/shared shiny bodies
  retain their existing sharing; separate shiny source models remain separate.
- Completed disk cache formats, source revision checks, native action sidecars,
  shiny metadata, desktop session pins and bounded mobile residency are retained.
  No generated-cache version bump or blanket rebuild is introduced.

The texture-bearing regression fixture measures one raw texture read instead of
the input path's two. A separate fixture makes 2,000 warm readiness calls with
zero cache reads, writes or extractions. These are operation-count results, not
hardware FPS, RAM or extraction-time benchmarks. Cold source decoding and GPU
upload remain potentially expensive, especially on mobile.

## Camera audit and adjustments

- Opposing idle viewpoints now hold and cut. They no longer interpolate through
  the centre of the combat field on the way to the opposite camera.
- Trainer-visible command scenes use three restrained same-side compositions
  with held shots and small dollies, instead of one permanent broad shot.
- Doubles camera smoothing belongs to the combat core's lifetime. Recreating a
  render-context table no longer resets the interpolation on every draw.
- A missing/finished source-camera chapter clears its old interpolation origin.
- Existing venue safety volumes, mobile HUD framing, source-camera ownership,
  manual controls, event holds, sendout/capture/faint sequencing and speed-
  independent presentation clocks remain in place.

These are refinements to the existing Colosseum-style director. Exact retail
camera parity was not established with new reference footage or source captures.

## Validation performed

The unmodified input passes 98 runnable top-level suites. The revised package
passes **101 suites, with zero failures or timeouts** using the real LuaJIT DLL
from the installed Windows LOVE runtime. Graphics/source objects inside the
headless suites are controlled fixtures; this is not a live game execution.

The three new suites cover runtime no-screen behavior and failure recovery,
camera continuity, and readiness/texture I/O. The runtime and idle-camera tests
both reproduce the old behavior as failures against the unmodified input and
pass against the revised code. Existing tests cover persistent-cache restart,
all 502 appearance identities, damaged metadata repair, mobile residency,
abilities, battle lifecycle helpers, audio contracts, menu boundaries, source
animations, move effects, and camera/venue safety.

LuaJIT syntax compilation passes for **226 Lua files**. The intentionally
Lua-5.3-only `tests/texlua_wrapper.lua` is excluded from that LuaJIT syntax pass;
it is test tooling, not mod runtime code.

Six suites were not run because their external fixtures were not supplied:

- BattleAudioNativeTests
- CacheChoiceConsentTests
- NativeModelCacheTests
- ReleaseLifecycleCompatibilityTests
- SingleBattleSwitchUITests
- DoublesDisplayCompatTests (historical producer fixtures)

The native cache test has been updated to assert the new runtime contract, but
is still marked not run. No ROM/source extraction, actual engine integration,
live Windows/Android/iOS playtest, or real GPU performance benchmark was performed.

Current evidence is under `validation/release_cache_camera/`. Older validation
documents and logs in the package are historical, not new results for this build.
Reproduce the current headless run on Windows with an installed compatible LOVE:

```powershell
python tests/run_headless.py --lua-dll "C:\Program Files\LOVE\lua51.dll" --output results.json
```

Alternatively use the existing `--luajit` runner. Add `--engine-root` with the
appropriate Gen1Recomp fixtures to run the five native-engine suites. The
historical doubles-display fixtures remain separately required.

## Install and final in-game checks

Close the game and replace the previous combined package through the launcher.
Keep the current source import and generated cache. Enable only one combined
Colosseum Overhaul installation. `main.lua` and `manifest.json` remain at the
archive root. Because the version label remains 1.0, use manual replacement.

Before public release, check on the actual supported game/device combinations:

1. Continue with Reuse/Current Team, enter an uncached encounter, and repeat it.
   Expect possible first-use buffering, no cache popup, then warm reuse.
2. Repeat with Quick Start and Full Catalog; restart and verify persisted reuse.
3. Exercise singles and doubles switches, Transform, normal/shared shiny and
   separate shiny models, plus return from Party/Summary and battle exit.
4. Watch command, attack, impact, faint, capture and sendout shots at 1x and
   accelerated speed; check compact venues and portrait/mobile controls.
5. On a disposable test installation, verify a missing-source or GPU/model
   failure gives the compact notice and that retry/exit behaves correctly.

The archive is prepared and regression-tested. Public-release playtest sign-off
still depends on those actual engine/device checks.
