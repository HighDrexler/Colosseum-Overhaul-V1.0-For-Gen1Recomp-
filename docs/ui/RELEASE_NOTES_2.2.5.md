# Colosseum Inspired UI Overhaul 2.2.5

## Battle type-indicator polish

- Centers the active Pokémon type badge group inside the lower detail lane of the Colosseum battle HP card instead of anchoring it to the left edge.
- Mirrors the same type indicator onto the player's HP card for full player/enemy presentation parity.
- Single-type badges center as one unit; dual-type badges are measured first and centered together as a pair.
- Status conditions retain a reserved left-side lane when present so type badges and status text do not collide.
- Live/transformed battler typing remains authoritative, with species typing only as the fallback.
- Applies through the shared HUD renderer on both Gen I and Gen II.
- No changes to battle logic, damage/type calculations, CBE rendering, menu behavior, model caching, or sprite-provider precedence.
- Preserves all 2.2.4 Gen II transition-flash suppression and Gen I model-viewer performance work, plus the 2.2.3 Pokédex and 2.2.2 sprite-provider fixes.
