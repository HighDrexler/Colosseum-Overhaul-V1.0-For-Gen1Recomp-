# Validation — CBE 1.9.6-pc-idle-audio-exit-latch.1

## Package/static
- All packaged Lua sources parse successfully through `texluac -p`.
- `manifest.json` parses and matches `main.lua` version `1.9.6-pc-idle-audio-exit-latch.1`.
- Existing `tests/MoveFXSourceChainTests.lua` completes successfully.

## PC source-idle regression
A synthetic dense two-page source-idle bank was exercised through the actual `PokemonActors.Actor:playbackBank()` implementation. At `clipClock=1.25s` with a 1.0s authored duration, playback wraps into page 1 at local phase 0.5 rather than pinning page 2 at phase 1.0.

## Real GC6E01 audio probes
The user's validated Pokémon Colosseum USA source was reconstructed through its real CISO sparse block map and read through CBE's actual `GameCubeDisc`/`FSYS`/`PortableMusyX` path.

Miror B. (`mirrorbo_song`, setup 65):
- 1,951 source voices in the complete sequence.
- 21,504 continuous pitch events.
- v6 broken packed decode: `-1.0 .. -1.0` for the affected stream.
- v7 corrected packed decode: `-0.7500915639 .. +0.0363813942`, matching the previously audited retail/Amuse semantics.
- first 10 s at 48 kHz: v6 RMS ~0.144239 combined-channel sample stream; v7 RMS ~0.144607 (ratio ~1.0025).
- v7 first-10-s peak ~0.99004; clipped samples: 0.

The near-identical sustained level is intentional: this patch corrects authored pitch/timing on top of the stable v6 mixer rather than restoring the failed canonical-v8 production path that produced excessive sustained voice energy.

Additional affected sequences were decoded with the same real source. Continuous pitch ranges no longer collapse to the v6 broken values for Mirakle B., Cipher Peon, First Battle and Semi-Final.

## Battle-exit latch
Synthetic Gen 1 and Gen 2 screen-boundary harnesses exercised the actual `BattleRuntime.lua` implementation.
- Gen 1: `battle.ended` arms the latch but does not tear down CBE; the inner engine step observes CBE still active while the battle state is replaced, then cleanup occurs at `gen1.stack-exited`.
- Gen 2: `battle.ended` remains pending until wrapped `finishBattle`, then cleanup occurs exactly once at `gen2.screen.finished`.

## Runtime boundary
Full GPU/audio-device confirmation still requires the user's Gen1Recomp smoke test. The test priorities are PC idle/orbit, Miror B. and another pitch-heavy theme on Windows + Android, and the final few frames of a won battle.
