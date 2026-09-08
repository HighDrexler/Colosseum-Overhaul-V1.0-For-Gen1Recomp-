# Colosseum Inspired UI Overhaul 2.2.4

## Gen II transition flash / battle type HUD / Gen I model-viewer performance

- Removes the bright white transition flash introduced by current Gen1Recomp 2.52 menu timing when entering or leaving a Colosseum-replaced Gen II START submenu.
- The fix is scoped: Gen2 `MenuFade` stays fully native when the corresponding UI replacement is OFF. White reload/fade sheets are skipped only for Colosseum-owned Pokémon, Pack, PokéGear, Trainer Card, Pokédex, and Options routes.
- Adds a compact type indicator to the enemy Pokémon HP/status plate in the shared Colosseum battle HUD. Dual-type Pokémon show both types when space permits; live/transformed battler typing is preferred over species defaults.
- Improves Gen I Colosseum information-model performance without changing CBE battle rendering:
  - Summary now has a bounded six-entry actor/canvas LRU instead of releasing and reacquiring the model every time the player changes party members.
  - Pokédex retains its existing bounded cache.
  - Gen I UI model canvases are rendered below full physical pod resolution and scaled back into the UI.
  - Idle Gen I model previews render at a lower cadence, while touch/mouse rotation and zoom invalidate immediately and receive a higher interactive cadence.
  - Android uses the most conservative Gen I preview target/cadence; Gen II model preview quality/cadence remains unchanged.
- Adds a Gen II first-frame ownership recovery guard for Start/Party/Summary/Pokédex so current 2.52 visible-base selection cannot expose a one-frame opaque native surface before the custom renderer marks the state.
- Preserves 2.2.3 Gen I Pokédex routing and 2.2.2 model/custom-sprite priority behavior.
