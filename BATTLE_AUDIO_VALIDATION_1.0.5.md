# Colosseum Overhaul 1.0.5 — battle reward audio validation

7 September 2026. Complete combined CBE + UI package based on the delivered
Colosseum_Overhaul_v1.0.4.zip, not a patch collection.

## Delivered behavior

Level-ups and successful in-battle move learning share the source-backed
Colosseum level_up_song fanfare (music setup 1). This build does not claim a
separately verified, distinct retail learned-move melody. The successful native
learning cue is remapped; a declined or already-known move does not celebrate.

EXP uses the original Colosseum EXP-gauge sound. Gold's native EXP animation owns
its looping start/stop. Gen I has no equivalent native bar clock, so its actual
gain-message queue row starts a bounded 0.65-second pulse train. Bench/EXP-share
messages without a bar use the same bounded feedback. Zero awards and already
capped recipients do not start that feedback; a bench recipient reaching level
100 still receives its final gain cue.

Victory uses me_win_song (music setup 10) as a non-looping fanfare. Repeated
victory selection in one encounter cannot restart it. Level/learn fanfares are
queued behind a currently playing reward fanfare rather than overlapping it.
The native Music service pauses and resumes the same selected battle source;
no master/music-volume rewrite or manual map restoration is used. Owned audio
is stopped when its battle leaves the stack or BATTLE SOUNDS is disabled.

BATTLE SOUNDS defaults to COLOSSEUM and can be set to ORIGINAL independently of
the battle music selection. Existing SFX volume/mute is respected. The new layer
does not remap overworld item/TM jingles, Pokémon cries, or move-attack effects.

## Real Colosseum source verification

The following checks used the previously supplied USA GC6E01 CISO, not downloaded
replacement sound files or a guessed generic menu sound:

- common_rel GameSound table: 1,236 records beginning at offset 0x141654.
  GameSound 1232 resolves to general SFX group 6, source SFX 975; that SFX resolves
  to SoundMacro 390 and sample 9.
- The actual executable's EXP-award routine calls the EXP-gauge update at
  0x80011bc4. The sound start is the GameSound-1232 load at 0x80011c54 followed by
  the sound-start call. The gauge completion path loads the same sound ID at
  0x80012b2c and calls the stop routine. The award routine also references the
  source English EXP-gained text ID 30002. These are observations from this
  supplied executable, not unverified symbol-map labels.
- Macro 390 sets note 68, starts sample 9, waits 48 ms, and loops to step 1. The
  builder checks the source mapping and command bytes. It retains 1,536 stereo
  frames at 32 kHz for the repeating cycle instead of looping the renderer's
  longer release tail.
- The level and victory sequences and instrument banks were extracted and
  rendered from bgm_archive.fsys, common.fsys, and snd_music.samp through the
  existing portable MusyX renderer.

Generated cue outputs in the private test cache:

| Cue | Sample rate | Stereo PCM frames | WAV bytes | Renderer peak | Clipped samples |
| --- | ---: | ---: | ---: | ---: | ---: |
| EXP cycle | 32,000 Hz | 1,536 | 6,188 | 0.70514* | 0 |
| Level/learn fanfare | 48,000 Hz | 96,256 | 385,068 | 0.69771 | 0 |
| Victory fanfare | 48,000 Hz | 250,880 | 1,003,564 | 0.89507 | 0 |

*The EXP peak is the renderer's measurement before trimming its output to the
source cycle. The three WAV files total 1,394,820 bytes. These generated files
are NOT included in the delivered mod archive.

## Preparation and cache behavior

The additional builder uses its own battle_audio_v1 per-cue completion markers;
it does not advance or delete the existing 24-asset soundtrack's v9 markers.
Each completed cue is read back and verified with strict PCM/WAV structure,
length, and a byte checksum. Missing/truncated/same-sized-corrupt cues are repaired
individually. Interrupted or failed writes cannot mark that cue complete.
Unavailable cues remain native at runtime instead of yielding silence or an
unfinishable wait. The retained source is used automatically at startup; a full
team/PC/model cache rebuild is not required by this feature.

One controlled desktop texlua run built all three real-source cues in
10.195731 CPU seconds, including the new cue builder's source reads and renders.
An immediate all-cached pass took 0.080596 CPU seconds, reused all three, and
opened the source zero times. These are local CPU-time observations, not cold
mobile wall-clock benchmarks or promises about device loading times. Runtime
static-Source creation is separate from that builder measurement.

The SFX POOL parser previously treated zero keymap/layer offsets as positions in
the file, parsing unrelated bytes as layers with enormous counts. Both actual
snd_se and snd_se_battle banks have these absent sections. The corrected parser
retains their real macro/envelope sections and bounds any layer count before
iteration. Actual bank preparation measured 0.002245 and 0.003036 CPU seconds,
respectively. The old general-bank preparation was stopped by an instruction
watchdog rather than allowed to run indefinitely.

The old and corrected renderer produced byte-identical level_up_song and
me_win_song outputs against the actual music bank. This comparison covers those
two complete sequences, not a fresh render of every historical soundtrack.
No existing valid soundtrack or move-effect waveform is forcibly regenerated.

## Automated checks performed

- 85 top-level headless suites passed, zero failures or timeouts, using texlua
  with the packaged test-only Lua 5.1 compatibility wrapper.
- The three added suites passed 161 assertions: cache/parser 43, runtime 71,
  native-engine reward/audio integration 47.
- Native integration uses actual Gen I and Gen II battle kernels, text/reward
  queues, Sound, Music, and Hooks. Only audio devices/Sources and the clock are
  instrumented. Checks include unchanged Gen I EXP totals and queue length,
  native Gold per-pixel start/stop, two-level catch-up with two fanfares, successful
  free-slot/full-slot learning, declined learning, correct native wait budgets,
  queued victory/level playback, BGM identity/resumption, and map restoration.
- Controlled runtime fixtures also cover Gen II's unflagged battle screen,
  overlays, bench/doubles-partner feedback, top-level battle identity, maximum
  level, setting/mute changes, fallback with unavailable cues, cleanup, and no
  cache reads or Source allocations across playback triggers and updates.
- The retained SingleBattleSwitchUITests suite passed its 349 assertions.
- The separate existing native Gen I/II doubles regression run, with abilities
  installed, passed 1,953 assertions. It validates the retained doubles kernels,
  reward handoffs, and ability paths; it is not a live sound-playback test of an
  entire doubles encounter with this new audio layer.
- All 191 packaged Lua source files parsed successfully.

The historical DoublesDisplayCompatTests suite was not run because its original
cbe1/cbe2/cbe3 producer fixture directories are unavailable. No replacement
fixtures were invented for that suite.

## Merge and packaging

All 937 files from the exact delivered v1.0.4 archive are retained. Six existing
files are modified: main.lua, manifest.json, README.md, lib/BattleSettings.lua,
extract/PortableMusyX.lua, and tests/run_headless.py. The other 931 original files
remain byte-identical. New files implement and test the audio layer and document
this release. MERGE_AUDIT_1.0.5.json records the baseline hash and per-file SHA-256
inventory. The ZIP has main.lua and manifest.json at its root, retains mod ID
COLOSSEUM_OVERHAUL, and contains no newly added retail sound/disc assets.

The embedded 2.5.4 UI source is unchanged; no separate UI update is required.
Do not install a standalone UI or duplicate CBE alongside the combined archive.

## Limits

There was no live LÖVE/game session, physical Android/Windows device benchmark,
or hardware listen-through. Source-backed synthesis through the existing MusyX
renderer is not a certification of bit-perfect console DSP playback. Exact
in-game perceived loudness, transitions under every third-party mod combination,
and device-specific audio-reset behavior still need live confirmation. No
mobile FPS improvement or elimination of every loading stall is claimed.
