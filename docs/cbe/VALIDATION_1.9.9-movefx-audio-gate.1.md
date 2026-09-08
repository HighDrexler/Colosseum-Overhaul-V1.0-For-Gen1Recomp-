# Validation — 1.9.9 MoveFX/audio gate correction

- Changed-file Lua compilation: pass for `BuildPipeline.lua`,
  `PortableMusyX.lua`, `WazaSfxBuilder.lua`, and the source-chain tests.
- Source-chain tests: pass (`tests/MoveFXSourceChainTests.lua`).
- Build behavior: a partial 185/251 visual scan now proceeds to move audio;
  `.cbe-movefx-full-v3.complete` is withheld until 251/251.
- Existing live cache diagnosis: `build/state.txt` was stuck at
  `current_stage=movefx_failed`, `audio_ready=0`; this is the failure mode fixed
  by this release.

