# Validation: 1.9.10-reaction-queue.1

## Reproduced and fixed

A synthetic 0.10-second source Damage clip exposes a queue bug: admit a hit,
queue a lethal hit, and update by 0.11 seconds. Before this patch, draining the
queue called Actor:hit again. Its 0.20-second duplicate filter discarded the
already admitted hit. hitAge was cleared, leaving pendingFaint without another
active reaction to advance it.

Actor:beginHit now starts admitted reactions. Actor:hit still handles terminal
guards, duplicate filtering, and queue admission. Queue draining calls beginHit
directly. This preserves the existing complete-reaction ordering policy; it
does not establish whether that policy matches every original multi-hit move.

## Tests

- Regression fails on the original actor implementation at the queued-hit assertion.
- Regression passes after the fix: queued lethal hit reaches Damage then Faint.
- External duplicates of active and queued hits remain suppressed.
- Nonlethal queued hits finish and return to Idle.
- Fainting actors reject late damage.
- Existing MoveFXSourceChainTests pass, now including the reaction regression.

Tests ran using the installed LOVE LuaJIT library through a headless runner.
The source scan used production import normalization, FST, FSYS, Waza, HSD,
texture, and MoveFX extraction with an isolated file-backed cache. Native
float32 packing was supplied by LuaJIT FFI for the headless scan.

## Source audit

- CISO MD5: a2d58d82c6b76b42653dcd25c8966de7 (manifest match).
- Logical disc verification: GC6E01; 1,872 FST files.
- Source moves found: 251/251; executable chains: 185/251; incomplete: 66.
- The extractor reported three unique source sound IDs. Sound mapping and
  audible parity were not independently verified.
- Leading unsupported-entry reasons: 59 type-2 model failures, 17 particle
  generator failures, six invalid/truncated particle-data warnings, and five
  unsupported type-1 controllers. Counts overlap across moves; they are not
  counts of distinct failing moves. Additional timeline parsing failures remain.
- Model errors include 34 invalid source ranges and HSD geometry failures.
  These require source-format investigation, not relaxed readiness checks.

## Limits

The LOVE executable failed during filesystem initialization in this execution
environment. No interactive battle, GPU rendering, audio playback, Crystal save,
or frame-by-frame original-game comparison was validated. The companion UI and
Battle Art mods were not modified. No ownership gates were relaxed and no source
assets were changed. This release fixes one verified scheduling regression; it
does not claim 1:1 presentation parity.
