# Validation — Colosseum Inspired UI Overhaul 2.2.4

## Baseline
- Source: Colosseum Inspired UI Overhaul 2.2.3.
- Target: current Gen1Recomp 2.52 behavior, Gen I + Gen II.

## Gen II white-flash root cause
Current Gen1Recomp routes START submenu opens/closes through `src.ui.gen2.MenuFade`. Pokémon, Pack, PokéGear, Trainer Card, Pokédex, and Options receive explicit white reload-frame counts; the fade state draws a full-screen white sheet. This is correct cartridge emulation for native Gold UI, but redundant for this mod's final-HUD replacement screens and creates the reported full-window flash under Android touch controls.

### Fix
- Wrap `MenuFade.openWhite` / `MenuFade.closeWhite`.
- Return native values unchanged unless the target route is currently owned by the corresponding Colosseum UI feature.
- Return nil for UI-owned routes so Game2 pushes/pops the replacement screen directly without inserting `Gen2MenuFade`.
- Add class-based first-frame ownership recovery in `screen.render_visible` and `renderHudMenuLayer` for Start/Party/Summary/Pokédex.
- Keep the live StartMenu reference while a child submenu remains on the state stack so returning from a submenu can render START in the same frame.

## Enemy type indicator
- Shared `drawStatusCard` path covers both generations.
- Type resolution order: live battler types -> live mon types -> species definition types -> legacy type1/type2 fields.
- Enemy-only compact type chips share the lower detail band with status and numerical HP, preserving the player card layout.

## Gen I information-model performance
- Summary actor cache extended to bounded LRU limit 6; Pokédex remains limit 12.
- Cached entries retain actor + already-rendered private canvas, so returning to a party species does not reacquire/recreate its viewer.
- Gen I desktop preview target: 72..288 px per axis at 0.72 physical-pod scale.
- Gen I Android preview target: 72..192 px per axis at 0.52 physical-pod scale.
- Gen I idle cadence: 24 Hz desktop / 18 Hz Android.
- Interactive cadence: 45 Hz desktop / 30 Hz Android; interaction still invalidates immediately.
- Gen II remains at the existing full-resolution / 60 Hz viewer behavior.
- CBE battle actors, battle arenas, and in-battle render quality are not modified by this UI package.

## Static validation
- `main.lua` parsed successfully with `texluac -p`.
- `manifest.json` validated with Python JSON parser.
- Diff whitespace checked with `git diff --no-index --check`.
- Final archive verified with `unzip -t`.
