# Colosseum Overhaul 1.0.6 — audio fidelity validation

7 September 2026. Complete combined CBE + UI package based directly on v1.0.5.

## Outcome and exact scope

The core handoff proposal is implemented with attack-safe/modulo-wrapped loop
taps, normalized 8-tap Lanczos-4 coefficients and 256 precomputed phases. FAST
retains the original linear arithmetic. This is an optional, source-generated
WAV-cache upgrade, not a runtime synthesizer or a verified full fidelity cure.
All existing v1.0.5 files are retained. `MERGE_AUDIT_1.0.6.json` lists exact changed
and added files. Doubles, singles-switch logic, battle reward playback,
UIMain/DoublesUI, models, shiny support, arenas, camera and performance-loader
implementations are unchanged. Only the battle settings menu gains cache controls.

**Do not purge caches.** Installing this build does not replace a valid v1.0.5
soundtrack. To hear HIGH on existing caches, open START > BATTLE > AUDIO FIDELITY,
set NEW RENDERS to HIGH, select APPLY / RESUME ON NEXT LAUNCH, confirm and restart.
The same procedure with FAST restores original interpolation. AUTO uses FAST for
new renders on Android/iOS and HIGH elsewhere. Use the same explicit quality on
both devices when comparing them; AUTO intentionally trades mobile preparation
time against interpolation quality. Physical cross-device parity was not tested.

## Executed regression suites

- **89 top-level suites pass with texlua / Lua 5.3.** Zero failures or timeouts.
- **The same 89 suites pass with real LuaJIT 2.1.1700008891.** Zero failures or
  timeouts. The runtime is from the user's supplied LÖVE 11.5 AppImage.
- **1,953 native Gen I/II doubles assertions pass separately under both
  interpreters**, with abilities installed and real engine kernels/fixtures.
- The existing native single-battle switch suite passes **349 assertions**.
  Previous battle-audio native routing/queue tests also pass unchanged.
- **199 Lua files parsed under Lua 5.3; 198 parsed under LuaJIT.** The deliberately
  Lua-5.3-only `tests/texlua_wrapper.lua` is excluded from LuaJIT parsing and
  replaced by its LuaJIT-specific test wrapper. Every runtime Lua file parses
  under both interpreters. Total syntax checks: 397; failures: zero.

The historical `DoublesDisplayCompatTests.lua` remains explicitly unrun under
both interpreters: its original cbe1/cbe2/cbe3 producer fixtures are not present.
No substitute historical fixtures were fabricated. It is not counted among the
89 passes. Graphics/audio-device objects in headless integration remain controlled
fixtures, not a live GPU/sound driver.

The LuaJIT test wrapper supplies the engine-style string-loading contract and
only the float32 packing formats required by two existing geometry fixtures,
using actual FFI float storage. It does not fake the resampler's FFI backend.
The wrapper is test-only and is never loaded by the mod.

### New focused assertions, per interpreter

| Suite | Passed assertions | Coverage |
| --- | ---: | --- |
| AudioFidelityResamplerTests | 7,074 | Dense phase/tap indexing, unity DC, exact integer samples, attack preservation, first versus repeated loop history, short loops, FFI bounds, string/FFI parity, analytical sinusoid interpolation error, FAST arithmetic and option forwarding |
| AudioFidelityCacheTests | 78 | Device policy, exact quality/checksum stamps, same-size corruption, rollback, restart cuts, absent originals, unreadable/truncated backups, damaged journal/backup refusal, unit resume and unchanged unrelated caches |
| AudioFidelitySettingsTests | 58 | Gen 1/2 menu entry, HIGH/FAST/AUTO cycle, explicit confirmation, queued-quality persistence/cancel, read-only menu opening, storage errors and saved-choice preservation |
| AudioFidelityRoutingTests | 19 | Warm v9 reuse without synthesis, partial theme repair as a full pair, native ledger acceptance, Android FAST/HIGH propagation, boss source route, startup recovery ordering and attack-bank FAST isolation |
| **Total** | **7,229** | The same checks are executed under both interpreters. |

The resampler suite instantiates both actual FFI storage and the packed-string
fallback. Synthetic one-sample and other very short loops test bounds safety;
they are not described as observed retail instruments.

## Checks against the user's actual GC6E01 source

The previously supplied CISO was read locally through the actual FST/FSYS/MusyX
parsers. No new retail disc bytes, source banks, or generated WAVs are included
in this delivery.

The source music bank has 210 samples, 148 looped; 146 looped samples have a
nonzero attack prefix. Its smallest loop is 82 samples. This confirms why the
handoff's unconditional left-tap wrapping would affect real attack data.

### Production upgrade and reuse

The actual new AudioFidelityBuilder generated **all 16 source units / 27 WAVs**:
11 theme intro/loop pairs, capture, boss introduction, EXP, level-up/learned-move
success, and victory. The disc index opened once. Every output's quality stamp
and checksum was checked. The original soundtrack size ledger and native boss
and reward markers agree with their new WAVs. EXP keeps its source-authored
48 ms cycle at 32 kHz; other upgraded outputs remain 48 kHz stereo PCM.

This source-backed HIGH run took **79.846806 CPU seconds in this server's
LuaJIT process**. Its next explicitly requested identical pass reused all 16
units, built none, and made no source-open call; checksum/reuse work took
0.206286 CPU seconds. These are one-run CPU observations including build/cache
work, **not phone loading times, startup guarantees or game FPS measurements**.
An existing installation additionally backs up its old unit files during commit.

### Original FAST equivalence and scheduling

Under real LuaJIT/FFI, every one of the **15 music/fanfare source units plus EXP**
was rendered with the original v1.0.5 renderer and with the new FAST path.
All emitted FAST WAV bytes matched the original exactly. This includes both
halves of every theme, not just metadata or similar-looking waveforms.

The new HIGH path preserved the same total frame counts, voice counts and
source-derived loop split points across that full set. Under the deliberately
non-FFI packed-string path, both representative full themes (normal battle and
Miror B.), all four music one-shots and EXP passed the same FAST byte-equivalence
and HIGH scheduling checks. This does not claim new HIGH bytes equal old FAST;
changing those samples is the purpose of the interpolation option.

### Isolated-process CPU samples

Each cell below was measured in a fresh LuaJIT process, using real source data
at 48 kHz. Times are CPU seconds; source preparation precedes the timed render.
These are single runs, not statistical device benchmarks. The full interleaved
correctness-run timing tables are retained separately; mixing kernels in one
JIT process produced more variable timings, so they are not hidden or used as a
universal cost multiplier.

| Track / PCM backend | Original v1.0.5 | New FAST | New HIGH |
| --- | ---: | ---: | ---: |
| Miror B. / FFI | 1.396753 | 1.878009 | 2.630638 |
| Normal battle / FFI | 3.443972 | 3.253399 | 5.016861 |
| Miror B. / packed string | 2.156326 | 2.213196 | 3.670905 |
| Normal battle / packed string | 4.150601 | 4.101372 | 12.562270 |

HIGH is slower; the cost varies by material and runtime. The handoff's 8–9x
estimate is not adopted as a promise or contradicted by pretending one server
represents every phone. No live-battle resampling is added.

### Clipping is not concealed

The unchanged mixer already clips some channel-samples. HIGH slightly increases
that count for some tracks; no extra limiter, track normalization or arbitrary
EQ was added to hide the difference. Representative full-render counts:

| Source | Original / new FAST | New HIGH |
| --- | ---: | ---: |
| Miror B. | 7 | 10 |
| Normal battle | 298 | 333 |
| Final battle (battle6) | 4,922 | 5,018 |
| Boss introduction | 5 | 6 |
| Level-up / move learned | 0 | 0 |
| Victory | 0 | 0 |

These are clipped **channel-samples**, not whole frames or seconds. The count
is taken before splitting theme intro/loop files. Full peaks/counts and exact
frame lengths appear in the included TSVs. No universal no-clipping claim is made.

## What has not been verified

No Amuse reference executable was run here, and no original-console recording
was used for an audible/spectral A/B. The handoff's 26–46% improvement in its
normalized 4–8 kHz metric is **not independently reproduced**. This build's
analytic and source tests establish applicability, safe sample access, working
integration and backward equivalence; they do not certify audible reference
fidelity. No live LÖVE game/listen-through, physical Windows/Android/iOS test,
mobile cache-time test, or real-device FPS benchmark was performed.

The handoff's separate envelope/long-piece timing discrepancy is not fixed.
Unchanged source event/frame/loop metadata does not rule it out. This fixed
interpolation kernel does not implement rate-scaled downsampling filters or
promise a cure for every upper-frequency difference.

## Reproduce the packaged checks

From an extracted complete package:

```sh
python tests/run_headless.py --engine-root /path/to/gen1recomp --output results-texlua.json
python tests/run_headless.py --engine-root /path/to/gen1recomp --luajit /path/to/luajit --output results-luajit.json
```

The default interpreter is texlua. The optional --luajit path uses the dedicated
Lua 5.1 wrapper. Native engine tests require the supplied engine's tests.modkit
fixtures; without --engine-root they are explicitly skipped, never counted as
passes. Run the additional doubles suite from the engine checkout:

```sh
POKEPORT_DATA_DIR=tests/fixture_data \
CBE_DOUBLES_MOD_DIR=/path/to/combined \
CBE_DOUBLES_UI_DIR=/path/to/combined \
CBE_TEST_ABILITIES_INSTALLED=1 \
texlua /path/to/combined/tests/doubles/RegressionTests.lua
```

On a POSIX desktop with LuaJIT, the optional actual-source builder check is:

```sh
luajit tests/retail/AudioFidelitySourceChecks.lua /path/to/combined /path/to/verified-GC6E01.ciso /path/to/PRIVATE-output-cache
```

That optional command generates copyrighted source-derived WAVs in the specified
private directory. They are for the user's own source validation and are not
part of this package. Do not run it against a live game cache or redistribute
that output. It verifies source units and warm reuse, not Amuse spectral parity.

## Evidence files and delivery audit

`validation/audio_fidelity_v1/` contains both headless result logs, native doubles
logs, syntax results, original/FAST/HIGH source comparison tables, isolated CPU
measurements, and the real builder's generation/reuse output. The archive is
CRC-checked, extracted into a fresh directory and compared byte-for-byte with
the working package before the final headless runs. `MERGE_AUDIT_1.0.6.json`
records the v1.0.5 baseline SHA-256 and every changed/added file; no baseline
file is missing. No standalone UI update is necessary.
