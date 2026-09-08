# Validation — CBE 1.9.2-pokemon-motion-handoff.1

- Confirmed the installed GC6E01 cache reports Bite (`kamituku`) with complete
  attack and damage Waza roles; the visible failure was downstream of caching.
- Confirmed the installed Larvitar source cache contains a 4.333-second PKX
  Physical-A bank, which the 1.9.1 runtime selected and then deliberately
  discarded.
- Added a regression that starts Bite with `sourceWaza=true` and verifies the
  selected Physical-A GPU bank remains active and sampled.
- Added selector/schema checks for Physical A, Special A/B and Special C.
- The packaged Lua corpus loads under embedded Lua 5.4 and the MoveFX source
  chain regression suite passes.
- Protected BGM/MusyX/Amuse production files remain byte-identical to the
  1.8.9-audio-source-recovery.1 baseline.
