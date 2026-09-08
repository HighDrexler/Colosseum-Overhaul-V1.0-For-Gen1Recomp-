CBE 1.10.0-presentation-test.1
Baseline: ColosseumBattleEnvironments-1.10.0-doubles-test.2.zip

Install
Use this ZIP in place of the previous CBE ZIP; retain the existing Colosseum ISO import and other mod settings. Let the trainer cache migration finish. Trainer identity 16 replaces the baseline's B1 cache with A1 models and full animation tracks. Do not clear all generated assets: valid audio, arenas, MoveFX and capture assets can be reused. Initial trainer extraction takes time; this build does not promise a faster first rebuild.

Trainer changes
- Ports the earlier trainer overhaul onto the new doubles baseline: A1 battle banks for all ten trainers, source IK/foot-chain corrections, full adjacent-frame position/normal playback, source hand anchors, latched ball release, live sendout framing, reaction queuing and independent real-time trainer clocks.
- Preserves source displacement and jump height. Sparse extraction no longer subtracts movement measured at the feet. Native throw/sendout/recall playback retains the complete authored follow-through instead of fading its last section toward the stationary idle body.
- Hit, concern, faint-response, recall, victory and defeat roles remain distinct. Queued damage does not cut off a throw; delayed faint reactions cannot replace a terminal result. Extra fast-forward logic ticks cannot repeatedly advance the trainer clock. Catch-up after stalls is capped at 50 ms per update.

MoveFX and cameras
- Newly emitted source particles follow the live animated Waza attachment. Particles already emitted and child generators keep their own positions. Explicit joint-follow particles retain their own attachment ownership, avoiding a double offset. This is shared runtime behavior, not a replacement Flamethrower texture.
- Projectile launch shots hold the attacker/stream composition and cut to the target's damage chapter. They no longer pan across the arena throughout the attack or blend that phase boundary through the middle of the arena. Manual camera controls and venue visibility guards remain.
- The supplied 13-second recording was inspected. Its mouth-origin flame stream, attacker launch framing and separate Venusaur damage shot informed these changes. Exact effect shapes, retail camera curves, source timing and every move/species combination have NOT been verified 1:1.

Performance
- Animation-role aliases share their loaded frame data. Reusing a resident track avoids rereading those binary files.
- Adjacent-frame playback rotates the previous B GPU buffer into A and uploads only the new frame. Fully weighted native playback skips the invisible idle-reference upload. Subframe interpolation does not upload unchanged frames.
- Shared particle textures avoid repeated identical filter-state calls.
- Trainer-only upgrades skip rebuilding already-valid arena sidecars and capture banks; audio remains reusable.
- These remove specific duplicate work without reducing source samples or disabling features. No live FPS, total loading-time or low-memory-device improvement is claimed. Full trainer tracks use more memory than the old sparse-only baseline.

Validation
21 focused Lua suites pass, covering trainer clocks/reactions/ball release/native interpolation/streaming, HSD scale, MoveFX source programs/emission/attack handoff, Pokemon reactions, cache/storage/menu performance boundaries, and Relic/Pyrite camera safety. Lua files parse. All ten A1 trainers rebuilt successfully from the user-provided ISO using this merged extractor and rendered through native GPU playback. The isolated GPU preview covers 96 frames, Red/Wes/Dakim, four action roles. The preview omits the ball prop, battle scene and live event timing.

Remaining work
- The baseline's experimental doubles presenter is preserved. It bypasses shared MoveFX and has its own camera/event routing, so the new shared attack FX/camera changes apply to singles. Four-slot MoveFX and trainer event integration remains separate work. Doubles source files are byte-for-byte unchanged; the engine-dependent doubles integration suite was not rerun.
- Trainer role mapping and per-trainer release timing still need retail gameplay calibration. Release currently uses the established 0.31 action phase. Intro shots approximate source staging rather than decoded retail camera tracks.
- Full 1:1 parity for all moves, exact source particle/controller semantics and live host battle validation remain unfinished. This is a substantive test build, not a claim of completed parity.

The ZIP excludes your ISO and extracted model/texture caches. The active working baseline is work/cbe-1.10.0; the older work/cbe folder is historical.
