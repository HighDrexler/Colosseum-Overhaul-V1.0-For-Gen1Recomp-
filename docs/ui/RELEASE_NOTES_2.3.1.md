# Colosseum Inspired UI Overhaul 2.3.1

## Gen I parity hotfix
- Rebuilt the Gen I START -> SAVE presentation so it now uses the same Colosseum save terminal UI as Gen II.
  - The native Gen I anonymous save panel still owns its 30-frame hold, confirmation flow, writeSave callback, save SFX, auto-delay, and close behavior.
  - Only the native panel/TextBox/ChoiceBox pixels are replaced while the Save Screen UI option is enabled.
  - Toggle-off behavior still falls back to the native Gen I save presentation.
- Applied the Gen II compact dialogue cleanup to Gen I overworld TextBox presentation.
  - Font-aware sizing, wrapping, and content-sized hanging geometry are now shared cross-generation.
  - Battle dialogue keeps its existing wider battle rail.
- Replaced the Gen I Pokédex AREA/Town Map result with a proper LOCATION habitat list matching the Gen II presentation.
  - Shows location + encounter method in a scrollable list.
  - A/B returns to Pokédex data.
  - The native AREA callback is retained as the toggle-off fallback.

## Preservation
- 2.3.0 Strict Native UI Block behavior is unchanged.
- No battle logic, encounter tables, save mutation, storage behavior, TM/HM logic, external sprite/model arbitration, or Gen II menu behavior was changed.
