# Validation — Colosseum Inspired UI Overhaul 2.2.3

## Scope
- Baseline: 2.2.2.
- Fix: Gen I current Gen1Recomp/launcher 2.52 Pokédex CONTENTS state bypassing Colosseum UI.

## Root cause
Current Gen I uses `src.ui.PokedexMenu` for the Pokédex CONTENTS screen. The 2.2.2 integration still marked only the older generic `ListMenu` titled `POKéDEX`, so `DexUI.active` was never assigned for the current Gen I state and the native `PokedexMenu:draw()` rendered unchanged.

## Fix
- Wrap `src.ui.PokedexMenu.new` and mark the returned state as `__gen3uiPokedex`.
- Preserve its native update/input/scroll/A/B and side-action behavior.
- Suppress only `PokedexMenu:draw()` while revamped Pokédex UI is enabled and route foreground ownership to `DexUI.hud`/Strategy Memo.
- Preserve Gen I SELECT location-page browsing.
- Existing `DexEntryMenu` adapter continues to own DATA-page presentation.
- Gen II integration is unchanged.
- Pokémon preview resolver remains 2.2.2's shared priority: Colosseum models > current custom sprite provider/Battle Art > native ROM.

## Static validation
- `main.lua` parses successfully with `texluac -p`.
- Archive integrity checked with `unzip -t`.
