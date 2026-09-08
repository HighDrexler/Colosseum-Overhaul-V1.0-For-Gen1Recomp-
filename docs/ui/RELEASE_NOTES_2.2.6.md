# Colosseum Inspired UI Overhaul 2.2.6

## Battle dialogue / choice ownership

- Fixes Gen I trainer switch prompts such as `Will BLUE change POKéMON?` falling back to the older Gen 3-inspired white battle dialogue card.
- Battle `ChoiceBox` prompts now redraw the completed question through the same Colosseum dialogue renderer used by the rest of the themed dialogue system.
- Gen I battle YES/NO choices no longer use the fixed overworld popup coordinates; they use the responsive battle-choice placement above the dialogue lane so the selector and question do not collide.
- Native battle message state, YES/NO input, callbacks, switch logic, and battle timing remain authoritative.

## Selection / text containment

- Tightens Gen I and Gen II Poké Mart root-menu typography so BUY / SELL / EXIT stays inside its selection pill across supported text profiles.
- Uses measured/fitted text instead of assuming one fixed glyph height.

## Elevator

- Adds a dedicated Colosseum elevator renderer instead of sending `ElevatorMenu` through the generic empty-flow fallback that only displayed `READY`.
- Shows the current floor plus the authoritative extracted floor list, selected floor, and current-floor marker while preserving native up/down/A/B behavior and destination data.

## Poké Mart TM/HM clarity

- BUY lists now show the move taught by TM/HM items in both generations, using the same item/move metadata already used by the Bag.
- Gen I reads `item.machine.move`; Gen II reads the extractor's `item.teaches` field.
- Item label, taught move, and price have separate fitted lanes to prevent overlap.

## Pokémon menu move layout

- Rebuilds the left detail column's four-move area as four dedicated measured lanes.
- Move names and PP now have reserved regions and font-height fitting, eliminating the vertical overprint seen with larger/alternate text profiles.

## CBE 3D presentation priority

- The large selected Pokémon portrait in the standard Gen I and Gen II Pokémon menus now opts into the existing provider-owned information-model path.
- When CBE's Colosseum Pokémon models are equipped, the UI borrows CBE's read-only 3D actor/cache; when CBE models are disabled/unavailable, it falls through to the exact active Battle Arts/custom/default 2D resolver.
- Evolution stages use the same provider-aware model path, including the old/new species swaps.
- Egg hatch keeps the egg shell during the hatch animation, then uses the provider-aware 3D hatchling presentation once the Pokémon is revealed; 2D remains the fallback when no selected 3D provider exists.
- No CBE assets are bundled and no battle sprite/model ownership rules are changed.

## Preserved behavior

- 2.2.5 player/enemy type-indicator layout remains intact.
- Gen II flash suppression, Gen I information-model performance caching, Pokédex routing, shiny handling, and sprite-provider precedence from the 2.2.x baseline remain intact.
