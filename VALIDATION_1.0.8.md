# Colosseum Overhaul 1.0.8 — validation and delivery scope

7 September 2026. Complete combined release based on the user's uploaded
`Colosseum_Overhaul_v1.0.7(1).zip`.

Baseline SHA-256:
`784fbf3405a27bbb43e30b7de6464973aa5bdea5914c60cc1fd600d8e7aa4868`

## Executed automated checks

**95 top-level suites pass under texlua / Lua 5.3**, with zero failures/timeouts.
The historical `DoublesDisplayCompatTests.lua` remains explicitly unrun because
its original cbe1/cbe2/cbe3 producer fixtures are unavailable. It is not counted
as a pass. Prior package logs for LuaJIT remain historical; this release has not
been rerun under LuaJIT or a live LÖVE GPU session.

The three added top-level suites execute shipped implementation code:

| Suite | Checks | Scope |
| --- | ---: | --- |
| SessionModelCacheTests | 2,299 | All 502 identities; exactly 270 shared source units; source colour parameters; desktop pinning; bounded mobile preparation; disk-only reuse; metadata-write failure/retry; transient GPU-fixture failure; reset identity; action mesh cleanup without releasing shared texture handles. |
| NativeModelCacheTests | 1,088 | Actual native Gen I/II title menus, Hooks and StateStack; automatic/manual preparation; Continue/New Game handoff; OFF settings; cancellation; error/retry; cooperative work cleanup; pointer ownership; speed-independent scheduling; four-slot/replacement readiness. Model preparation and native battle update are controlled fixtures. |
| StrictUIRoutingTests | 57 | Actual compact-cell functions; fractional viewport coordinates; party/PC icon bypass removal; separate simultaneous cell identities; exact mon/shiny handoff; configured-art routing when OFF; egg exemption. Graphics/provider calls are fixtures. |

Existing shiny UI/doubles fixtures now assert the requested exclusive-ownership
contract instead of expecting the old sprite fallback. Doubles additionally tests
renderer rejection and actor-draw failure reaching the correct native game's
readiness guard. Existing audio, Poké Ball facing, arena, shiny, performance,
abilities, targeting and switch suites run against the final combined tree.

The separate native Gen I/II doubles runner passes **1,953 assertions** with
abilities installed, including rewards, KO/replacement timing and end-of-battle
handoffs. Graphics are stubbed. The native single-switch UI suite's **349 checks**
are already included in the top-level run, not another independent suite total.

All **209 Lua files** parse under `texluac -p`. The manifest parses and matches
`main.lua` at version 1.0.8. The archive is CRC-checked, freshly extracted and
compared byte-for-byte with the delivered tree; the top-level runner is repeated
against that fresh extraction. Current logs are under `validation/model_cache_v1/`.

## Actual supplied-source checks

Using the user's GC6E01 CISO through bounded source reads, the optional source
runner finds and parses native metadata for **all 270 required archives**. It
validates **232 source colour recipes**, covering the shared-body shiny route.
Together with the 19 separate shiny archives, these support the 502 requested
normal/shiny identities. Archive/recipe availability is not a visual comparison.

Four source units were fully prepared through the new final cache API:
Voltorb normal, Quilava normal, Larvitar shiny (shared-body colour recipe), and
Charizard shiny (separate rare archive). Each completed its model/metadata/native
action sidecar and texture-validation stages, acquired the exact colour actor,
and reused the prepared unit without reopening the source. Cooperative work
slices were exercised. GPU objects for this check were mocked.

Observed preparation CPU time on this server using texlua:
Voltorb 18.196 s, Quilava 35.884 s, Larvitar shiny 18.828 s, Charizard shiny 62.475 s.
These are four cold diagnostic observations, not expected LÖVE/LuaJIT, Windows,
Android or iOS loading times, and not a prediction for the full roster.
Only these four units had complete source geometry/action preparation exercised
in this run. Every source archive's metadata was checked; every species' rendered
appearance and animation was **not** visually verified.

The private generated output is not part of the ZIP. Source checks use the
unchanged source extractor and shader; final UI/error-handling refinements do not
change the tested extraction pipeline. No ISO/CISO/7z, source textures, newly
extracted geometry or new soundtrack WAVs are distributed.

## Preservation and cache compatibility

No v1.0.7 baseline file is removed. All **548 packaged assets** are unchanged.
The existing source extractor, native shiny recipe decoder, audio renderer,
release audio gains, ball-facing transforms, arena/source recipes, battle rules,
abilities and reward logic are retained. The doubles Presenter changes only
model acquisition/render-failure handling; its v1.0.7 facing-vector handoff is
retained. Source-geometry and audio cache identities are not bumped. Existing
valid cache files/imports remain usable under the same `COLOSSEUM_OVERHAUL` ID.

`MERGE_AUDIT_1.0.8.json` records the baseline and all changed/added file hashes.
Historical validation files are retained as history, not evidence that all old
platform tests were rerun for this release.

## Limits and priority live checks

These are source/code/native-state tests, **not a live full-game rendering test,
phone test, listen-through or user-device cache migration**. No exact FPS,
startup duration, GPU memory use or universal visual correctness is certified.
Pinning desktop base scenes and precomputing all species/actions trades a longer
first preparation and more persistent data/RAM for reuse. Individual host I/O or
GPU calls are not preemptible even though CPU preparation is cooperatively sliced.
A damaged cache with still-valid revision metadata may report an error rather
than automatically regenerate every damaged file. Cache errors never authorize
an alternate Pokémon source.

The priority live checks are the reported Gold doubles encounter (Voltorb,
Quilava, Larvitar), rapid party/PC/Pokédex navigation, source-filter and separate-
archive shinies, then a cold launch followed by a warm launch. Verify the title
progress/error controls and retention of v1.0.7 audio/send-out behaviour.

## Reproduce

From the extracted combined package:

```sh
python tests/run_headless.py --engine-root /path/to/gen1recomp --output results.json
```

From the supplied engine checkout:

```sh
POKEPORT_DATA_DIR=tests/fixture_data \
CBE_DOUBLES_MOD_DIR=/path/to/combined \
CBE_DOUBLES_UI_DIR=/path/to/combined \
CBE_TEST_ABILITIES_INSTALLED=1 \
texlua /path/to/combined/tests/texlua_wrapper.lua /path/to/combined/tests/doubles/RegressionTests.lua
```

Optional POSIX source check, from the mod directory, using a separate private
output directory (not the live cache):

```sh
CBE_SOURCE_CISO=/path/to/GC6E01.ciso \
CBE_SOURCE_CACHE=/path/to/PRIVATE-diagnostic-cache \
texlua tests/texlua_wrapper.lua tests/retail/ModelCacheSourceChecks.lua
```

Source-derived diagnostic output is for the user's own verification; do not
redistribute it. The source checker intentionally uses graphics fixtures and
cannot certify in-game colours, geometry or material fidelity.
