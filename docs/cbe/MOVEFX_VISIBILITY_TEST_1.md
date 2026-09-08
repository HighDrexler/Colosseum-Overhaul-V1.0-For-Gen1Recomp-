CBE 1.10.0-movefx-visibility-test.1

Replace the previous CBE ZIP with this ZIP; do not run both versions. Keep your existing Colosseum import, generated cache and doubles UI. This lookup fix does not change cache format or require a full rebuild of an already current cache.

Fix
Native battle events use string constants such as ICE_BEAM and HYDRO_PUMP. Their move definitions include the canonical numeric index, but the source-effect resolver ignored it and recognized only a small subset of English names. Consequently the renderer could work with numeric test IDs while real battle events failed to find their imported effects. The resolver now reads the native definition's index before looking up source stems and the generated cache index. This applies to all 251 supported move indices, including localized names, and works after a fresh application start without accessing the ISO during a move.

Second fix
Doubles move playback used its already-remapped source/target arena to compute the next frame's four-slot positions. This compounded lane offsets on every update/draw and could swap physical sides for enemy attacks, sending source models and particles off-screen. Effect anchors now always come from the original battle context before binding temporary source/target aliases. A regression test reproduced the drift before this fix and verifies stable position and facing throughout the chapter after it.

Scope
Production changes are limited to source-effect identity resolution and the doubles effect anchor calculation. Camera, trainer, ball release, Pokemon reaction and move renderer files are byte-identical to Doubles MoveFX Test 1. Exact source-stem lookups used by ball releases remain supported. Existing missing-cache fallback behavior remains.

Verification
- New regression reproduced Native identifier failed: ICE_BEAM before the fix.
- All 251 native move indices resolve through a cold cache after the fix; explicit ICE_BEAM and HYDRO_PUMP cases pass. Exact-stem release lookup and unknown-move behavior pass.
- All Lua parses and 29 focused suites pass.
- Real Colosseum extraction and off-screen LOVE rendering exercised Tackle, Flamethrower, Water Gun, Hydro Pump, Surf, Ice Beam, Thunderbolt and Swords Dance using native string identifiers plus definition indices. Extraction memory and source rows were cleared before battle playback, and runtime ISO access was disabled. All eight produced nonzero framebuffer pixels. Both sides and attack/damage chapters completed: 4,242 frames, 958 active model frames, 46 source sound starts, zero native audio fallbacks, zero Waza handler faults.
- Off-screen test uses attachment fixtures, not the user's complete live game/mod stack. ICE_BEAM-render-check.png and HYDRO_PUMP-render-check.png show isolated source attack effects from that test; they are not in-game screenshots or proof of exact retail parity.

In-game check
Repeat Ice Beam and Hydro Pump from the recording after replacing the ZIP and restarting the game. This specifically repairs effect lookup; it does not claim every move's existing particle interpretation matches retail perfectly.
