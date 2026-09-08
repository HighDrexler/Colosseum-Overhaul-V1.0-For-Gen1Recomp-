# Colosseum Overhaul 1.0 — fidelity release build

This build includes the cache/camera fixes and the final source-fidelity sweep.
See **RELEASE_FIDELITY_1.0.md** for current changes, validation, and remaining
live-game checks. Earlier release notes are retained as historical records.
Runtime encounters, switches and model errors no longer open the startup cache
screen. Missing models buffer on the battle update boundary while the current
game frame stays visible. A first-use pause is still possible. Model failures
retain the battle and show only a compact error notice with retry/exit controls.

Complete combined Colosseum Battle Environments (CBE) + UI release, based directly
on **v1.0.10**. This is the requested **1.0 release label**, not a rollback to the
older 1.0.0 build. The installation ID remains `COLOSSEUM_OVERHAUL`.

## Install or update

### Download from GitHub

1. Download this branch using **Code > Download ZIP**, or use the
   [main branch ZIP](https://github.com/HighDrexler/Colosseum-Overhaul-V1.0-For-Gen1Recomp-/archive/refs/heads/main.zip).
2. Close any running game. In the Gen1Recomp launcher, open **MODS > Import mod .zip**
   and select the downloaded ZIP. No compilation, separate asset download, or
   repacking is needed.
3. Enable **Colosseum Overhaul**. For a new installation, assign your supported
   Pokemon Colosseum USA disc through the mod's **IMPORT FILE** control and complete
   the initial preparation when prompted.

GitHub wraps the repository in one top-level folder. The
[Gen1Recomp ZIP installer](https://github.com/bryanthaboi/gen1recomp/blob/dev/src/mods/LauncherMods.lua)
supports this layout: `manifest.json` and `main.lua` are directly inside that folder.
The repository contains the complete supplied final fidelity build, including its
runtime modules, assets, extraction recipes, and bundled audio renderer. Tests and
historical validation records are included for reference; they are not installation
steps. The original standalone build ZIP instead has the mod files at ZIP root.

### Updating an existing installation

Close the game and replace the previous combined package using the launcher.
`main.lua` and `manifest.json` are at the mod folder root. Enable **only one** combined
Colosseum Overhaul installation; keep older combined duplicates and standalone
CBE/UI packages disabled. The manifest retains the existing conflicts explicitly.

**Keep your current Colosseum source import and generated hard cache.** This
update refreshes the ten retail arenas once during startup to correct source
joint transforms, texture coordinates, and material state. It retains valid
Pokémon, shiny, trainer, animation, MoveFX, audio, and authored Wildlands caches.
No audio rerender or full Pokémon catalog rebuild is required for this update.
An interrupted arena refresh remains retryable. Missing or detectably damaged
files may still require their existing repair path.

The release version is intentionally `1.0`, which sorts below development build
`1.0.10`. Use manual replacement for this rename; do not expect a version comparator
to offer it as a numerically newer update. Do not delete the cache to change a label.

New installations still require the supported user-supplied Pokémon Colosseum USA
source import. Keep the existing import assignment when updating the same mod ID.
The manifest's import validation and accepted digests are unchanged. Source images
and user-generated model/audio caches are not included in the release archive.

## What is retained

The complete v1.0.10 runtime remains: source-backed battle environments and
trainers, camera/free-look controls, Colosseum Pokémon models and shiny handling,
source move-effect/audio presentation, native-integrated doubles and abilities,
and the combined Gen I/II UI. Existing battle flow, rewards, targeting, switching,
settings, audio quality options, volume corrections, and Poké Ball-facing fixes
are retained. No source geometry, textures, animation sampling, or sound renderer
is replaced by a cheaper implementation in this release.

Doubles and abilities remain independently configurable, with existing saved OFF
choices respected. Arena/camera toggles remain independent from Pokémon model
selection. With Colosseum models OFF, configured external artwork/provider routes
remain available. With them ON, a missing battle model does not authorize native
sprites, Battle Arts, or a non-shiny substitute; the exact model must prepare or
report an error. Information viewers retain their loading/error notices.

Compact Pokémon-menu and PC cells keep the established normal/shiny Colosseum
headshot portraits when **Colosseum Icons** is enabled. Larger summary/inspection
and Pokédex viewers keep their 3D route. Battle HUD portraits remain unchanged.

## Main-menu cache controls

Entering BATTLE CACHE (including the initial title prompt) first opens the options.
A read-only check determines whether 30 valid model units qualify for REUSE CACHE;
model extraction begins only after a mode is selected. Choose REUSE CACHE when
available, QUICK START / 30 NEW, FULL CATALOG, or MAIN MENU. Opening/holding the
confirm button cannot also accept the first option: release it, then confirm again.
Mouse/touch mode activation is likewise gated until the opening input has cleared.

When CONTINUE or NEW GAME needs models that are not ready in this session, its
options also offer CURRENT TEAM ONLY or STARTER MODELS ONLY. Selecting that
option prepares the required models, then resumes the original native action once.
Selecting a Quick/Full batch is a separate operation and returns to the menu;
cancelling never loads a save or starts New Game. Already session-ready startup
models need no redundant prompt. The explicit Models OFF behavior is preserved.


**BATTLE CACHE > QUICK START / 30 NEW** selects up to **30 new/incomplete model
assets** using the selected save's team, owned/caught/seen Pokémon, current and
nearby encounters, team-level relevance, and near-term evolutions. It excludes
completed assets based on disk validation, not a session-only counter. Each new
selection advances through the remaining catalog; the last batch can be smaller.

There are **270 distinct source-model assets covering 502 normal/shiny
appearances**. Shared-body normal/shiny appearances, including their colour
metadata, use one batch slot. The 19 separate shiny source assets are also part
of the complete catalog and remain eligible for their own slots.

Every completed model is saved independently. Cancelling a batch, restarting the
game, changing save slots or evicting a GPU model does not discard valid completed
files. An unfinished unit can still need work on its incomplete components.
**CONTINUE does not select another 30-model batch**: any required team preparation
is offered explicitly first. NEW GAME offers its required starter preparation. FULL CATALOG
remains a separate optional operation for all supported appearances.

B / MAIN MENU cancels title preparation while keeping completed cache work.
A successful quick batch waits for acknowledgement before returning to the menu.
Errors show Retry and retain diagnostic text at `build/model-cache-error.txt`.
Battle readiness errors cannot be bypassed into an incorrect sprite battle.

Quick Start stops after its chosen batch. It does not schedule the next 30 or
continue building the remaining Pokemon catalog in the background. The separate
resident-prewarm system still loads likely battle dependencies (cached party bodies,
arenas, trainers, shaders, and team move effects) on eligible frames; information
viewers and battles may prepare an uncached requested model. Those demand-driven
jobs are not an automatic catalog-completion queue. A separately requested Hard
Cache operation is also distinct from the main-menu Quick Start batch.

Disk persistence and graphics residency are separate. Existing files still load
into graphics memory each session; mobile residency remains bounded. Previously
uncached encounters can still need first-use preparation. Generating a cold model
remains expensive, especially on mobile; this release does not claim a faster
source decoder or a particular completion time.

## Compatibility

Both `gen1` and `gen2` manifest targets, API 2, the existing engine range
(`0.0.0-dev || >=0.2.11 <2.0.0`), permissions, import checks, optional provider
ordering and conflict declarations are unchanged. Optional providers are not new
mandatory dependencies. This preserves the prior declared compatibility, not a
claim that every combination of third-party versions was played through.

The final cleanup makes the cache guard follow the actual Continue/New Game
labels or semantic values, including the engine's translated labels, instead of
assuming they occupy the first two menu positions. Other title-menu rows retain
their own callbacks and closing behavior. Repeated hook passes do not duplicate
the BATTLE CACHE row or wrap its startup actions twice.

External state-stack resets now cancel any active cache worker and release screen
ownership without triggering a deferred save-load callback or deleting cache
files. Ordinary cancel/retry/completion behavior is retained.

## Validation and historical notes

See **RELEASE_CACHE_CAMERA_1.0.md** and `validation/release_cache_camera/`
for this build. **CHANGELOG_CACHE_OPTIONS_1.0.md**, **VALIDATION_CACHE_OPTIONS_1.0.md**
and `validation/cache_options_1_0/` are retained historical evidence.
`CHANGELOG_1.0.md` / `VALIDATION_1.0.md` describe
the immediately preceding release sweep. The package retains older changelogs, merge audits and
test reports as historical records, not as extra tests performed for this release.
`run_all_tests.lua` is a historical Windows harness, not the exhaustive runner.

Current headless runner (native tests need the supplied engine fixture checkout):

```sh
python tests/run_headless.py --engine-root /path/to/gen1recomp --output results.json
python tests/run_headless.py --engine-root /path/to/gen1recomp --luajit /path/to/luajit --output results-luajit.json
```

Automated/native-state checks and Linux software-rendering probes are not a live
Windows/Android/iOS save playtest or a full-retail-fidelity certification.
