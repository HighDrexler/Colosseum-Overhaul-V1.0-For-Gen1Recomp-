# Colosseum Overhaul 1.0.7 — audio and send-out validation

7 September 2026. Complete combined CBE + UI release, based directly on the
v1.0.6 ZIP (SHA-256 `698896b4d23a6f019e0364e96efb07ba6c0cc8c471ec8f7822104ad86b0495d5`).

## Outcome and scope

This release fixes demonstrated note-identity and mixer-block cutoff bugs in
the portable music renderer, applies the two requested per-effect reductions,
and corrects the source Poké Ball axis and send-out direction. It is not another
interpolation-only change and is not a claim of exact original-game piano timbre.

No baseline files are removed. The shared UIMain/DoublesUI, arena/source geometry,
shiny/model caches, battle rules, reward amounts, saved settings, and prior
single-battle switch fixes are retained. Changed/added file hashes appear in
`MERGE_AUDIT_1.0.7.json`. The source-backed doubles Presenter is changed only to
pass its existing Pokémon-facing vector to the trainer's ball presentation.

## Confirmed audio defects and corrections

The old mixer treated same-channel, same-transposed-sample-pitch voices as
repeated MIDI notes. This did two incorrect things: sibling layers belonging
to one note could release each other immediately, and different drum keys
mapping to a common sample pitch could cut each other off. The corrected
renderer tracks the original channel/key/note-event owner before sample
transposition and shares that owner across the note's layers.

An upcoming retrigger could also overwrite an earlier authored note-off.
The earlier request now wins, with sustain-pedal handling retained. Separately,
keygroup hard kills were applied while loading all voices for a 512-frame block;
a voice beginning later in that block could erase older audio too early. Kills
are now scheduled at the actual sample frame. Changing block length in a
controlled waveform test no longer changes the keygroup output.

Private source-bank checks found the following co-start pair candidates that
would collide under the old sample-pitch identity rule. These are code/data
counts, not percentages of perceived fidelity improvement:

| Source sequence | Voices | Sibling-layer pairs | Different-event pairs |
| --- | ---: | ---: | ---: |
| Normal battle (`battle5_song`) | 2,475 | 328 | 50 |
| Miror B. (`mirrorbo_song`) | 1,951 | 140 | 28 |
| Link battle 1 (`tool_battle1_song`) | 3,419 | 464 | 231 |

The corresponding final-renderer source-identity audit passes 15,693 checks.
The supplied 14.1-second video shows an idle doubles menu, not a send-out or
EXP sequence. Audio correlation identifies its music as the normal battle
theme. It is not an original-console reference. The recording's slightly
stronger correlation with an old FAST render than an old HIGH render does
not establish its cache mode: it is a lossy mixed recording. No claim is made
that the user failed to enable HIGH. Reapplying HIGH is required regardless.

Restoring missing layers exposes additional peaks in the source mix. When a
song exceeds full scale, it is rendered again from the voice graph with one
constant gain of `0.98 / sourcePeak`, applied before PCM quantization. This
keeps intro and loop at the same gain and avoids trying to repair already
clipped samples. No EQ, compressor, limiter, tempo change, or live battle DSP
is added. This can change absolute track level. Existing playback music
volume settings are not changed. HIGH and FAST retain their prior resampling
kernels, but affected complete FAST WAVs are intentionally no longer promised
to be byte-identical to v1.0.6.

For architectural comparison, Amuse's primary `Voice.cpp` implementation
creates instrument layers as parent/child voices and propagates key-off to
the children. This informed the note-ownership review, not a reference render:
`https://raw.githubusercontent.com/AxioDL/amuse/master/lib/Voice.cpp`

## Requested gains and source-ball facing

EXP loop and end-of-bar pulse are multiplied by **0.75**, including preload,
playback and SFX-slider refresh. Level/move-learned/victory jingles retain their
previous playback gain. Source-backed release effects are multiplied by **0.85**.
Cries and ordinary attack effects are not reduced. Repeated clone-less source
reuse cannot compound the reduction; later non-release playback restores its
normal gain even when it uses the same cached sound ID.

Source mesh/UV/texture inspection of GC6E01 `monsterball_open` and the shared
`snatch_shake_monster` Poké Ball prop shows that the button faces **local +Z**,
not the -Z assumed by the previous fix. Both trainers' send-out transforms now
use the same field-facing vector as the Pokémon. The enemy no longer uses
arbitrary ball spin, and the stationary doubles open chapter uses the same
+Z convention. Throw direction is not used as a substitute for Pokémon facing.
Capture-specific ball rolls and shakes are unchanged.

The headless facing suite covers three arena-axis configurations, both trainers,
both doubles lanes, four throw phases, singles' default arena facing, the enemy's
shared source-prop route, and repeated release-gain reuse. Source inspection is
not a live GPU test of every trainer and ball type. No source textures, geometry,
disc content or generated soundtrack WAVs are included in this delivery.

## Executed checks

- **92 top-level suites pass under texlua/Lua 5.3**, and the same **92 pass under
  actual LuaJIT**. Zero failures and zero timeouts. The one historical
  `DoublesDisplayCompatTests.lua` suite remains explicitly unrun because its
  original cbe1/cbe2/cbe3 producer fixtures are unavailable. It is not counted.
- **1,953 separate native doubles assertions pass under each interpreter** with
  the supplied engine fixtures and abilities installed. Graphics are stubbed.
  The existing native single-switch suite passes **349 assertions** in each
  full run; this is included in, not added on top of, the top-level suite count.
- New focused suites: note ownership/timing **15 checks**, constant-headroom
  orchestration **110 checks**, and send-out facing/release gain **216 checks**.
  Existing battle-audio gain/routing tests pass **79 assertions**; cache tests
  pass **82 assertions**, including refusal to reuse old HIGH renderer stamps.
- Final HIGH generation from the user's source builds **all 16 units / 27 WAVs**.
  Every music/fanfare render and EXP source render has **zero clipped output
  channel-samples**. Source-derived intro/loop split points are unchanged.
  Some full-render tail lengths change because the previously cut-off notes
  are now allowed to finish; this is not a change to the loop boundaries.
  Three very short intro files are intentionally silent: normal battle, Miror B.
  and Mirakle B. Their source split points precede the first note (7,181/7,200
  and 9,575/9,600 frames respectively). All loops and one-shots are nonzero.
- Each output's checksum/renderer stamp, native cue markers, boss-intro marker
  and soundtrack size ledger are checked. A second explicit identical request
  reuses all 16 units, builds none, and performs no source-open call.

The complete source-generation run took 207.616101 CPU seconds on this server;
the warm request took 0.306601 CPU seconds. These are individual observations,
not Windows/mobile loading-time or game-FPS promises. Overloaded songs require
a second preparation pass. LuaJIT was built locally from the LuaJIT source
bundled in the user's supplied engine checkout; it was not the Windows binary.
Syntax and archive integrity results are recorded with the final audit logs.

## Installation and cache behavior

Replace the old combined package; do not run it alongside separate CBE/UI mods.
Open **START > BATTLE > AUDIO FIDELITY**, keep **NEW RENDERS: HIGH**, select
**APPLY / RESUME ON NEXT LAUNCH**, choose **CONFIRM UPDATE ON NEXT LAUNCH**, and
fully restart. **Reapply even when HIGH was already applied in v1.0.6.**

Only selecting HIGH or replacing the ZIP does not replace existing WAVs. The
new renderer identity contains the note/headroom revision, so an explicit
request will rebuild old HIGH output instead of treating it as current. The
existing unit-level journal and interrupted-job recovery are retained. No
whole-cache reset, model rebuild, source re-import or save modification is needed.
The two gain changes and facing fix work with existing visual/SFX caches.

## Remaining verification boundary

No original-console or executable-Amuse listening A/B was performed. No
perceptual piano-fidelity percentage, full MusyX equivalence, physical mobile
benchmark, or live Windows/Android/iOS gameplay validation is claimed. The
recording is evidence of the reported problem, not a clean instrument stem.
The code fixes establish specific errors corrected in a track heard in the
clip; exact piano timbre and other remaining macro/envelope discrepancies still
need an audible reference comparison.

## Reproduction

From the complete extracted ZIP:

```sh
python tests/run_headless.py --engine-root /path/to/gen1recomp --output texlua.json
python tests/run_headless.py --engine-root /path/to/gen1recomp --luajit /path/to/luajit --output luajit.json
luajit tests/retail/AudioFidelitySourceChecks.lua /path/to/mod /path/to/verified-GC6E01.ciso /path/to/PRIVATE-output-cache
```

The last command is optional and generates private source-derived WAV files.
Do not run it against a live game cache or redistribute its output. The
additional `tests/retail/AudioNoteSourceChecks.lua` documents its private bank
inputs and prints only note-identity statistics. The packaged audit directory
contains logs/statistics, not the copyrighted source inputs.
