# Validation -- Colosseum Overhaul 1.0.0

All runs below are against this exact merged tree
(`work/colosseum-overhaul-1.0.0`), executed with the project's existing
ctypes/lua51.dll harness (LOVE 11.5, LuaJIT/Lua 5.1) and, where native
gameplay is exercised, the real engine checkout at
`C:/Users/User/Downloads/gen1recomp-dev (6)/gen1recomp-dev`. Graphics/audio
are stubbed throughout except where noted. Nothing here was run against a
live installed game or a real controller/save file; see "Not verified"
below.

## Full-tree Lua compile check

`158/158` files parse (`luaL_loadfile`, no execute) -- every `.lua` file
under the merged root, including the new `run_all_tests.lua` runner.

## Top-level suites (camera, trainer, arena, MoveFX, ability data)

Reconstructed `run_all_tests.lua` (the shipped `1.11.1-integrated-test.1`
zip had no top-level runner at all; the last surviving copy, in
`work/cbe-1.10.0`, only wired 31 of the 59 CBE test files that now exist --
neither gap is specific to this merge). Enumerates every current
`tests/*.lua` file except the four that need `UI_COMPAT_DIR`/`CBE_TEST_BASE`
(run separately, below) and everything under `tests/doubles/` (its own
chained runner, below).

**60/60 files pass**, including: `CameraFXTests` (mouse/touch handoff, 11
arenas / 88 directed doubles pairs), `AbilityDataTests` (251 species, 62
abilities, 79 contact moves), `MoveFXNativeIdentityTests` (251 cold-cache
native indices), `ArenaSourceIntegrationTests` (228 assertions),
`DoublesCameraDirectorTests` (134 checks), `DoublesCoherentPresentationTests`
(79 assertions), all eleven Relic/Pyrite/Deep-Colosseum arena-fidelity
suites, all Trainer suites (ball release, idle continuity, native track,
reaction events, sendout camera, source cache, streaming).

Two files initially failed on a source-inspecting consistency check
(`assert(main:find(currentVersion,...))`, comparing `main.lua`'s own
embedded `VERSION` local against `manifest.json`'s version field) after the
manifest version changed to `1.0.0` for this merge; fixed by updating
`main.lua`'s `VERSION` local to match. Both pass now.

## `tests/doubles/PresentationTests.lua`

Self-contained (real `HSD.lua` FOBJ decode, `Presenter` camera-framing math,
the item-UI bridge loaded from this same merged tree). **374 presentation
assertions + 382 item-UI assertions pass** -- exact match to the source
notes' claimed counts.

## `tests/doubles/RegressionTests.lua` chain (native Gen I/II + doubles)

Chains `StabilityTests` -> `IntegrationTests` -> `FieldVisibilityNativeTests`
-> `TurnFlowTests` (-> `ProgressionBoundaryTests`, and, with
`CBE_TEST_ABILITIES_INSTALLED=1`, -> `AbilityTurnFlowTests` ->
`NativeAbilitiesTests`/`NativeAbilityLifecycleTests`) against the real
native Gen I/II battle kernels.

- Without abilities installed: **1951 of 1953 assertions pass.**
- With `CBE_TEST_ABILITIES_INSTALLED=1`: **1951 of 1953 assertions pass**,
  plus ability-specific suites run cleanly (38 turn-flow, 124 catalogue
  fault-safety, 458 native ability, 25 lifecycle -- all PASS).
- The 2 failing assertions are the known pre-existing Psych Up issue
  described in `COLOSSEUM_OVERHAUL_1.0.0.md` (`IntegrationTests.lua`
  lines ~104/106) -- confirmed present, byte-for-byte identical failure, in
  the original unmodified `1.11.1-integrated-test.1` CBE zip run standalone,
  before any merge changes. **Left un-skipped in the shipped test file**;
  running the suite start-to-finish stops there rather than silently passing.
  Isolating past just those 2 (verified in a throwaway scratch copy, not
  shipped) confirms every one of the other 1951 assertions is healthy.
- Two test-fixture mocks in `RegressionTests.lua` modeled the old two-mod
  shape (a separate `uiHandle`/mock `mod` object reachable only via
  `.find()`) and were updated to also expose `.exports.doubles`/
  `.exports.doublesUI` directly, matching what the merged `Runtime.lua`/
  `DoublesUI.lua` now read. This is a fixture-shape update, not a weakened
  assertion -- the same behavior (three-mon trainer eligibility, real
  four-panel UI draw at four resolutions) is still checked.

One genuine bug was found and fixed via this suite (not a merge issue,
see `COLOSSEUM_OVERHAUL_1.0.0.md`): `NativeAdapter.lua`'s call to a
nonexistent `Status.bakeOnInflict`, which crashed every doubles battle where
a Pokemon leveled up post-battle. Root-caused by instrumenting a scratch
copy of the pump loop to log `core.phase`/`core.messageText`; reproduced
against the pristine, unmodified 1.11.1 zip before any edits were made, to
confirm it predated this merge.

## UI-only tests (`UI_COMPAT_DIR` + `CBE_DOUBLES_MOD_DIR`)

- `AbilityBridgeTests.lua`: **36/36 pass** (exact match to source notes).
- `DoublesItemUITests.lua`: **116/116 pass** (exact match).
- `DoublesPerformanceUITests.lua`: **14/14 pass** (exact match).
- `DoublesDisplayCompatTests.lua`: **not run.** Requires
  `CBE_TEST_BASE=/path/containing/cbe1,cbe2,cbe3` -- three separate
  historical CBE builds representing different doubles-snapshot schema
  versions, to check the UI's backward-compatibility enrichment against
  each. No such fixture directory was set up for this pass; fabricating one
  from guessed historical builds risked false confidence more than it was
  worth. Also worth noting for future work: this specific test's premise
  (paired UI running against an *older* CBE snapshot schema) is a scenario
  that can no longer occur now that CBE and UI are permanently the same
  version of the same mod -- its remaining value is testing the enrichment
  code's general robustness, not a live compatibility gap.

Each of these three passing files needed a matching fixture-shape update
(same reasoning as `RegressionTests.lua` above) plus a file-path fix: two of
them extract literal source text from `main.lua` looking for specific
function bodies (`cleanBattleText`, `cbeAbilitiesBridge`) that now live in
`UIMain.lua` instead, since `main.lua` is CBE's own file, unmodified, with a
short bootstrap appended.

## Not verified

No live game install, real controller, real save file, or GPU-backed render
was exercised for this merge -- everything above is the existing
ctypes/stub-graphics harness this project has used throughout. The
"informationModels -> Stadium fallback," the settings migration
(`GoldCompat.migrateLegacyModOptions`), and the manifest-level
`optional_dependencies`/`conflicts` interaction with other installed mods
(Stadium Battle FX, Battle Art, Dramatic Shape, potato_voxel,
`gen3_battle_ui`) are inferred correct from static analysis and the
call-site verification above, not exercised end-to-end. Follow the source
notes' own "First live acceptance route" checklist in a live game before
treating this as fully confirmed: Free Look camera during command
selection/attacks, Blizzard/Thunderbolt in both directions, one connected
impact/HP sequence, send-out ball orientation, one early KO with EXP/
learning, abilities ON/OFF, and one native prize/evolution/map return --
plus, specific to this merge, upgrading an existing installation of the two
separate mods and confirming saved UI settings (especially the BATTLE UI
toggle) carried forward correctly.
