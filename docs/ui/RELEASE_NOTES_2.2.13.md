# Colosseum Inspired UI Overhaul 2.2.13

- **Gen II PC 3D actor ownership fixed at the real state marker.** Gold/Gen II BoxMenu and PcMenu identify replacement PC screens through `__gen3uiGoldOverlayKind` (`pc-root`, `pc-box`, `pc-item`), not the Gen I `__gen3uiPC*` flags. 2.2.12 therefore released the shared Pokédex actor at the start of every Gen II PC HUD frame, resetting its idle clock and interactive orbit/zoom state continuously. `isPCOwnedState()` now recognizes both state vocabularies.
- **PC now invokes the Pokédex viewer literally.** After confirming CBE Colosseum models are enabled, `drawPcInformationPortrait()` calls `drawPokedexInformationPortrait()` directly. There is no PC-specific lower-level model-render call left in this path.
- Keeps the 2.2.12 battle move-header font-metric centering and every prior cross-generation UI fix.
- UI-only update. No CBE, MoveFX, audio, arena, cache-format, or battle-logic changes.
