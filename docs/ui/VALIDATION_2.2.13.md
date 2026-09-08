# Validation — Colosseum Inspired UI Overhaul 2.2.13

## Reported runtime regression addressed

The Gen II/Gold PC 3D model could render but remained completely static and could not preserve orbit/zoom. The previous ownership fix only recognized the Gen I PC state markers (`__gen3uiPC*`). Gold's PC/Box classes instead identify their replacement surfaces through `__gen3uiGoldOverlayKind` (`pc-root`, `pc-box`, `pc-item`). As a result, the shared Pokédex 3D actor was still released at the start of every Gold PC HUD frame and reacquired later in the same frame.

## 2.2.13 changes

- `isPCOwnedState()` now recognizes both Gen I `__gen3uiPC*` markers and Gen II Gold overlay PC markers.
- `clearStaleOverworldOwnership()` already delegates shared Pokédex-slot ownership to `isPCOwnedState()`, so the Gold `pc-box` state now preserves one actor across frames instead of recreating it.
- `drawPcInformationPortrait()` performs CBE-model-toggle preflight and then calls `drawPokedexInformationPortrait()` directly. The PC no longer passes a PC-specific service kind into the lower-level 3D renderer.
- 2.2.12 battle move-header font-metric centering is retained.

## Executable/static checks

- PASS: `main.lua` parses with `texluac -p`.
- PASS: `manifest.json` parses and reports version `2.2.13`.
- PASS: Gen II `BoxMenu` still sets `__gen3uiGoldOverlayKind="pc-box"`.
- PASS: `isPCOwnedState()` explicitly admits `pc-root`, `pc-box`, `pc-item`, and `centerpc`.
- PASS: stale Pokédex actor cleanup calls `isPCOwnedState(state)` when deciding whether to release the shared slot.
- PASS: PC 3D draw path directly returns `drawPokedexInformationPortrait(game,mon,x,y,w,h)` after CBE preflight.
- PASS: all 536 runtime assets are byte-identical to 2.2.12.
- PASS: the only existing package files changed from 2.2.12 are `main.lua` and `manifest.json`; 2.2.13 release/validation notes are added.

## Runtime boundary

This environment can validate the code/package path but cannot execute the user's live Gen1Recomp/LÖVE Gold PC screen. The decisive test is to leave a CBE model selected in the Gen II PC for several seconds, then drag/zoom it. The actor must visibly continue its idle morph and retain orbit/zoom across frames.
