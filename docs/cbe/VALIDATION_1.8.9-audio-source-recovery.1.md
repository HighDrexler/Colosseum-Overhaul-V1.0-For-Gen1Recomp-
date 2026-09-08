# Validation — CBE 1.8.9-audio-source-recovery.1

## Confirmed regression boundary

- 1.8.7 production audio architecture: Windows bundled Amuse first; Android/non-Windows portable MusyX v6 at 48 kHz.
- 1.8.8 changed the production contract so the portable/canonical v8 renderer owned Windows as well and native Amuse became reference-only.
- The bundled `third_party/amuse/amuserender.exe` is unchanged between 1.8.7 and this recovery build.
- Gen1Recomp 0.2.54 -> 0.2.55 public changes do not include a direct audio/mixer implementation file; 2.55 remains a compatibility target but is not the identified renderer regression.

## Device-capture signal check

The prior 1.8.7 Android reference capture `1000041387.mp4` and the current failure capture `9448f909-14bb-4b45-9fb3-aec40fd12902.mp4` were decoded to 48 kHz PCM for signal-level comparison.

- 1.8.7 reference RMS: ~0.1502 per channel; peak ~0.8743; crest factor ~15.30 dB.
- Current failure RMS: ~0.5083 per channel; peak ~0.7960; crest factor ~3.90 dB.
- Current sustained level is ~3.38x / +10.59 dB versus the prior reference while not hard-clipping.
- That shape is consistent with the renderer producing excessively sustained/dense voice energy rather than a simple host-volume or clipping issue.

## Recovery identity

The following are byte-identical to `ColosseumBattleEnvironments-1.8.7-audio-source-parity.1.zip`:

- `extract/PortableMusyX.lua` — `6ba4b2609d9e1391e0830fd44c61c45af9759c810d29b46ed4316710df96745c`
- `extract/AudioProbe.lua` — `8f052ce4705c4b76babb94eb2e3cbde31c60388e5692fadff4f571102d442fcf`
- `extract/AudioWorker.lua` — `8a6351df5aa8110a740dac06d495c0331b8f27e9cc0cd24ff6fc98bb8472fe5b`
- `lib/CacheManager.lua` — `b3e3fc55bdd38be5dffe667b7f8c9ee30758878a1d4be9fc4c4dfe9ebe5fa7e9`
- `lib/Music.lua` — `f402e18179340ba762316c1b46b33c98c1ec67b48c5a275a5f03c74287e05b49`
- `third_party/amuse/amuserender.exe` — `65840d001001ec83b9b62fb6d545aa216b08e7ed385c0857b98bbeb7de1dc884`

`BuildPipeline.lua` is the 1.8.7 audio pipeline with only two intentional categories of change: current MoveFX v3/extractor-22/Waza-6 state, and an audio-only recovery gate. Until `.cbe-audio-source-recovery-v1.migrated` exists, no old native/portable/exhausted state is trusted: all 24 soundtrack WAV names and every known v1-v8 audio marker/journal are deleted once, then the marker is written and the proven 1.8.7 renderer contract regenerates from GC6E01.

## Static checks

- All 57 Lua files parse through `luahbtex --luaonly` + `loadfile`.
- Audio platform split smoke test passes: Windows -> native Amuse eligible; Android -> native Amuse rejected / portable v6 eligible.
- Current MoveFX runtime files remain byte-identical to the immediately preceding 1.8.9 MoveFX/video-fix branch.
- `manifest.json` and `main.lua` identify `1.8.9-audio-source-recovery.1`.
