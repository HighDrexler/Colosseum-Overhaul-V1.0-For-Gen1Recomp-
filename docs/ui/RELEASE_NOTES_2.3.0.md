# Colosseum Inspired UI Overhaul 2.3.0

## Performance / cleanup
- Conservative dead-code and hot-path cleanup only; no feature removals and no compatibility-path rewrite.
- Removed an unreferenced footer helper.
- Reuses the information-model actor-cache limit map instead of recreating it on every cache access.
- Reuses strict-state renderer descriptors instead of rebuilding the table every HUD frame.
- Reuses the already-resolved top state in the final menu HUD pass, avoiding redundant stack queries.

## Strict Native UI Block
- `STRICT NATIVE UI BLOCK` is now a true master ownership override for screen-level UI.
- When enabled, individual screen toggles can no longer accidentally allow cartridge/native UI to reappear.
- Battle mode/style choices remain independent; this change affects ownership/suppression, not gameplay or external sprite/model selection.
- Strict fallback wrappers no longer redundantly depend on per-screen toggles once strict mode owns the screen.

## Gen I battle fixes
- Restored the caught indicator for already-owned wild/Safari Pokémon.
  - Current Gen1Recomp identifies these battles with `BattleState.kind` (`wild` / `safari`), while older builds used a `wild` boolean.
  - The UI now accepts both contracts and checks both Pokédex `owned` and compatibility `caught` sets.
- Fixed the literal `PROMPT` / `{PROMPT}` word appearing at the end of battle dialogue.
  - Battle source text now passes through the engine's `TextBox.strip()` control-marker path before custom rendering.
  - `{DONE}` is handled by the same path.

## Compatibility
- Presentation-only: no battle logic, catch odds, save data, menu callbacks, storage logic, TM/HM logic, or encounter behavior changed.
- Gen I + Gen II retained.
- External presentation providers and existing CBE/Stadium/Battle Arts/Shape compatibility paths retained.
