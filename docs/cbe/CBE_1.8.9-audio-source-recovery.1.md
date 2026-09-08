# CBE 1.8.9-audio-source-recovery.1

Audio regression recovery layered on the current MoveFX v3 / extractor 22 / Waza 6 branch.

- Restores the 1.8.7 production architecture: Windows bundled Amuse first; Android/non-Windows portable MusyX v6.
- `extract/PortableMusyX.lua` is byte-identical to 1.8.7-audio-source-parity.1.
- `extract/AudioProbe.lua`, `lib/CacheManager.lua`, and `lib/Music.lua` are restored from 1.8.7.
- A new one-time source-recovery migration refuses every pre-recovery audio marker, deletes all 24 shared soundtrack WAV names plus v1-v8 audio markers, and then regenerates from GC6E01 before audio can be considered ready. This prevents any v8/interim PCM from being re-certified as v6/native output even if an old marker survived.
- Gen1Recomp 0.2.55 is supported; its 0.2.54->0.2.55 public diff contains importer/storage/UI changes but no direct audio/mixer implementation changes.
- Current MoveFX fixes are retained; no arena/Pokemon/trainer/capture cache schema is rolled back.
