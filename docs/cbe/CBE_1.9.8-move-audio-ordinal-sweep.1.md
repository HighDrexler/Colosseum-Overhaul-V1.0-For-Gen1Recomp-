# Colosseum Battle Environments 1.9.8-move-audio-ordinal-sweep.1

## Retail move audio mapping

GC6E01 Waza type-5 rows carry local GameSound ordinals. The retail
`snd_se_battle` SFXGroup stores those same authored rows in a contiguous global
define-ID range beginning at 0x00C9. The portable MusyX parser now derives that
range only when it is provably contiguous, preserves each source ID, and
exposes local aliases for the Waza audio builder.

The SFX cache marker advances to v2, so a prior cache with zero generated WAVs
cannot be treated as complete. The source WAVs are generated before CBE claims
native move-audio ownership; if any required source row is absent, native audio
continues as the explicit fail-open path.

