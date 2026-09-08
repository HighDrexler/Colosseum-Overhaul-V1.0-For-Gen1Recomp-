# Audio fidelity handoff review — Colosseum Overhaul 1.0.6

## Decision

Accept the core interpolation proposal as a reasonable, limited improvement,
with corrections and an explicit cache-upgrade workflow. Do not apply the code
verbatim or present its reported spectral improvement as independently reproduced.
This release is built directly on the complete v1.0.5 combined package.

## Handoff sections 1–3: scope, evidence and applicability

The v1.0.5 `extract/PortableMusyX.lua` does contain the two-point linear `pcmAt`
function described in the handoff. Its decoded sample objects supply `looped`,
`loopStart` and `loopEnd`. The renderer is used to generate WAV caches, not to
synthesize the battle soundtrack in real time. The proposed insertion point is
therefore appropriate.

The handoff reports a 26–46% reduction in normalized 4–8 kHz spectral deviation
on two tracks compared with Amuse. It also reports tests excluding ADPCM decode,
reverb, pitch controls and DLS envelopes for that test material. These remain
**handoff-reported results**, not measurements reproduced during this port. The
original Amuse executable could not be run in this environment. No original
console recording was used as a reference here.

A fixed-width windowed-sinc interpolator is a legitimate improvement over
linear interpolation for fractional sample reconstruction. It does not by
itself establish the sole cause of every audio inconsistency. The test result
for 8 versus 16 taps is not treated as a universal equivalence. This fixed
Lanczos kernel is not a complete rate-dependent anti-aliasing filter either.

## Handoff section 4: changes accepted and corrections made

The implementation uses eight-tap Lanczos-4 and 256 precomputed fractional
phases. Trigonometric weights are calculated once, not for each output sample.
`renderSong`, `renderAll` and `renderSfx` all accept the quality option. The
original linear arithmetic is retained as explicit `quality="fast"`.

The submitted loop helper needs correction. Its `idx < loopStart` branch wraps
all samples before a sustain loop, including the instrument's initial attack.
The corrected helper preserves the attack and the first traversal's left-hand
history. Left-hand taps wrap only after that particular voice has actually
crossed `loopEnd`; right-hand lookahead wraps at the upcoming seam. In the user's
actual music bank, 146 of 148 looped samples have a nonzero attack prefix, so
this is relevant to real data, not only to a contrived boundary case.

The helper also uses modulo wrapping, not a single addition/subtraction, so
short loops cannot generate an out-of-range FFI array access. The actual music
bank's smallest loop is 82 samples; one-to-seven-sample loops are deliberately
covered as robustness fixtures, not reported as observed retail samples.

The handoff's `k+A+1` expression writes keys 2–9 despite its comment saying 1–8.
The matching reads prevent a direct mathematical mismatch, but the port uses
actual dense 1–8 tap keys and 1–256 phase keys. Coefficients are normalized per
phase for unity DC gain. This is an explicit adaptation, not a claim that the
literal handoff and the port emit identical samples. The string-PCM path also
avoids allocating a nested `byteAt` closure for each sample.

No ADPCM decode arithmetic, MIDI event schedule, tempo map, sample gain,
instrument envelopes, velocity handling or reverb coefficients are changed.
Bounds checks reject malformed loop metadata before unsafe array access.

## Handoff section 5: device policy and cache deployment

The default AUTO policy applies to newly generated files only: Android/iOS use
FAST; other hosts use HIGH. HIGH remains explicitly available on mobile. Valid
v1.0.5 soundtrack and reward caches are not automatically invalidated.

START > BATTLE > AUDIO FIDELITY exposes AUTO/HIGH/FAST plus a two-step
APPLY / RESUME ON NEXT LAUNCH confirmation. The request freezes the selected
effective quality. Changing a preference alone never replaces playing audio.
A queued request can be canceled before restart. Completing a job consumes the
request; an interrupted/incomplete request can reuse previously completed units.

The requested upgrade covers 16 source units / 27 WAV files: the 11 battle
intro/loop pairs, capture jingle, boss introduction, and the three v1.0.5 battle
reward cues. Level-up and learned-move success still share the same fanfare.
The raw battle-transition decoder and the separate attack/MoveFX sound bank
are unchanged. Attack-bank rendering is explicitly FAST; it does not inherit
an accidental whole-library HIGH rebuild from the changed API default.

Each upgraded unit has quality provenance and a checksum. The existing v9
soundtrack size ledger and native boss/reward markers are updated with the
corresponding audio. Intro/loop pairs and their metadata are backed up and
journaled as one unit. Recovery runs before the normal startup audio gate.
Failure during a live-target write restores the previous complete unit when
its verified backups remain available. Failed recovery is not advertised as
runtime-ready. No model, arena, trainer, shiny, or full hard-cache epoch changes.

Journal tests simulate interruption at persisted write boundaries. The mod's
cache API does not offer an operating-system fsync/atomic-rename transaction;
this is not an unconditional power-loss or storage-hardware guarantee. Corrupt
rollback backups cause a visible recovery failure rather than fabricated success.

## Handoff section 6: performance

Lookup tables and positive array indices are preserved. No speculative tap
unrolling was introduced. The higher-cost work occurs only when generating a
WAV, not on a battle sound trigger. First-time builds still cost CPU time, and
HIGH is not a free mobile upgrade. No fixed 8–9x multiplier is assumed: this
port was measured with actual source tracks and the supplied LuaJIT runtime.
See the accompanying validation document for measured conditions and limitations.

The source units resume between tracks/cues, not from a sample inside an
unfinished render. An interrupted unit may be rendered again. During the
startup update the existing build-progress view is used; closing the game is
not a promise that the current uncommitted unit is saved.

## Handoff sections 7–8: validation and boundaries

Validation includes the actual source bank, all eleven themes, all four music
one-shots and EXP, both PCM storage implementations, original FAST byte
comparisons, interpolation error fixtures, original event/frame/loop metadata,
cache recovery, both generation settings menus, and existing battle regressions.

This does **not** establish original-console or Amuse spectral parity. It does
not repair the handoff's separately reported envelope/timing discrepancy, or
claim that 16–24 kHz is fixed. Unchanged event/frame/loop metadata is not the
same as an RMS-envelope correlation test against the original engine.

The prior mixer already clips occasional output samples. HIGH changes the
waveform and slightly raises clipping counts in some tested tracks. This is
reported, not hidden by introducing a new limiter or normalization pass that
would change the authored mix. A listening/reference comparison remains needed
to judge the full audible effect.

### References used for the review

- User-supplied `AUDIO_FIDELITY_FIX_HANDOFF.md`, sections 1–8.
- Original v1.0.5 package and the user's verified GC6E01 source.
- Julius O. Smith, *Physical Audio Signal Processing*, “Windowed Sinc
  Interpolation”: https://dsprelated.com/freebooks/pasp/Windowed_Sinc_Interpolation.html
- Amuse primary implementation, `lib/Voice.cpp`:
  https://raw.githubusercontent.com/AxioDL/amuse/master/lib/Voice.cpp

The external references support the interpolation and sample-playback review;
they are not substituted for an executed reference render of this build.
