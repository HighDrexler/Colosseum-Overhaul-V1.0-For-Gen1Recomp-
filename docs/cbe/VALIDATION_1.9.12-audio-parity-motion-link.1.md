# Validation — 1.9.12-audio-parity-motion-link.1

Baseline: `ColosseumBattleEnvironments-1.9.11-source-presentation.1`.

## What this candidate changes

### 1. Cross-platform soundtrack ownership

The previous baseline could produce different soundtrack caches depending on OS:
Windows could use bundled Amuse while Android/non-Windows used the Lua Portable
MusyX renderer. That means identical GC6E01 source data did not imply identical
PCM output. 1.9.12 removes that production branch split. `BuildPipeline` invokes
only `AudioProbe.runPortableFull`, and the v9 marker identifies one 48 kHz
canonical source-render contract on every supported platform. The bundled Amuse
helper remains reference-only and is not a production cache owner.

CBE runtime readiness now requires both the visual cache and the canonical audio
cache. The old persistent `audio exhausted` marker is never written as a success
condition. Audio failure returns `AUDIO REQUIRED / RETRY`, preserves completed
visual/MoveFX work, removes the runtime-ready marker, and retries the audio stage
on the next build attempt.

### 2. Transaction and restart integrity

Canonical audio v9 uses redundant pending/migration journals plus
`build/audio_portable_v9_assets.lua`. The ledger records the exact committed byte
size of every one of the 24 generated WAVs. `portableFullReady` requires all 24
cache entries to match their ledger values before accepting or self-healing a
completion marker. A restart after a partial cache write therefore resumes or
rerenders that asset rather than accepting a file merely because it is at least a
WAV-header long. Reset/source-recovery paths delete the ledger with the v9 cache.

Runtime theme discovery was intentionally kept lightweight: it performs cache
existence checks only. The build gate/ledger owns full-cache integrity, while the
selected theme still receives RIFF/WAVE validation when materialized into LÖVE.
This avoids rereading all large theme WAV bodies from Android storage just to open
a menu or evaluate music selection.

### 3. Source loop authority

Production theme splitting no longer passes the historical `theme.loopFrame`
constants into Portable MusyX. `parseSong` reads the SNG loop-start metadata from
the source header and the existing TrackRegion `-2` sentinel supplies loop end;
source tempo integration converts those ticks to the v9 48 kHz output boundary.
The old frame values remain only for the non-production Amuse reference helper.

This matches the architecture exposed by AxioDL Amuse's SongState implementation:
MusyX song state initializes loop-start ticks from the song header and performs
track looping at the source loop region. Amuse is an alternate MusyX-compatible
runtime/reference, not embedded or redistributed by this patch.

### 4. Pokemon attack -> Waza/MoveFX handoff

The baseline move event acquired the attack actor only when the 3D Pokemon was
reported visible on that exact frame. A transient visibility/send-out boundary
could therefore allow semantic MoveFX timing to proceed without ever invoking the
Pokemon's native attack bank.

1.9.12 resolves the resident battler independently of draw visibility.
`Actor:attack` selects the source PKX Physical/Special slot first and invokes an
`onStarted` handoff only after that native action is live. BattleDirector/Waza
timing, presentation-frame count, animation identity, source effects and audio are
bound from that callback. If the actor is still in Damage, the complete attack
request (including the callback) is queued; Waza does not begin until Damage ends
and the actual PKX attack starts. A stadium-mode Waza attack timeline is withheld
when no native action bank initialized, rather than showing source effects around
an idle body.

### 5. Waza GameSound cache completeness

`WazaSfxBuilder.ready` now requires `missing == 0`, `ready == requested`, the full
ready-ID list, and valid referenced WAVs. Incomplete runs delete completion
markers but retain verified individual outputs for resume. This prevents a partial
GameSound set from masquerading as source-audio-complete.

## Regression checks executed here

All Lua files compile under the available LuaTeX/Lua runtime. These tests pass:

- `AudioParityContractTests.lua`
- `BattleExitBoundaryTests.lua`
- `HSDScaleTests.lua`
- `MoveFXAttackHandoffTests.lua`
- `MoveFXSourceChainTests.lua`
- `PokemonReactionQueueTests.lua`
- `WazaSfxMappingTests.lua`

The new audio test also constructs a synthetic canonical cache and confirms that a
completion marker plus all filenames is rejected when one asset's committed size
no longer matches the v9 ledger. The attack-handoff test covers both immediate
native PKX start and an attack queued behind Damage.

## What is *not* certified by this environment

This is a parity-enforcing architecture, not a claim that the generated PCM is
already bit-identical to a GameCube capture. Pokemon Colosseum music is sequenced
MusyX source data (project/pool/sample directory/sample bank + SNG sequencing), so
extracting the correct files is only the first half of the problem: mixer, macro,
controller, envelope, pitch, reverb, voice and loop semantics determine the final
waveform. The portable renderer is specifically targeted at the commands observed
in Colosseum and is not a complete general MusyX implementation.

The supplied 1.9.11 source audit remains: 251/251 moves found, 232/251 executable
visual chains, and 403/403 referenced source GameSound IDs resolved/rendered
non-silent. Nineteen visual chains remain incomplete. Those counts establish source
coverage, not visible or audible 1:1 behavior.

### Required live certification for the audio priority

1. Delete/allow migration of pre-v9 soundtrack output and confirm a 24/24 canonical
   cache on Windows and Android from the same GC6E01 source.
2. Capture the same battle themes on both targets and null/align the resulting PCM
   to verify the generated cache is byte/waveform-equivalent across platforms.
3. Compare those aligned captures against direct Pokemon Colosseum reference audio
   for instrument identity, note/pitch automation, envelopes, pan, reverb, loop
   boundary, sustained-energy behavior and clipping.
4. Exercise interrupted cache writes/relaunch on Windows and Android and verify the
   v9 ledger forces only missing/damaged audio to resume without rebuilding visual
   caches.
5. In battle, test moves that previously showed effects with an idle Pokemon, plus
   move-after-damage and lethal reaction ordering, and confirm PKX motion begins
   before/with its Waza timeline.

Until those device/source comparisons pass, describe this build as the new audio
parity baseline rather than the final 1:1 certification.
