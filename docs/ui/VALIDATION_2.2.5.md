# Validation — Colosseum Inspired UI Overhaul 2.2.5

## Baseline
- Source: Colosseum Inspired UI Overhaul 2.2.4.
- Scope: battle HUD type-indicator layout only.

## Type-indicator parity
- Shared `drawStatusCard` continues to cover both Gen I and Gen II.
- Type resolution remains live battler types -> live mon types -> species definition types -> legacy type1/type2 fields.
- Type indicators now render on both enemy and player cards.
- Single- and dual-type chip widths are measured before drawing so the complete chip group can be centered as a unit.
- When a battler has a visible status condition, a bounded left-side reservation is created first and the type group is centered in the remaining detail lane.
- Numerical HP remains fixed to the lower-right detail readout.

## Regression scope
- Gen II `MenuFade` suppression from 2.2.4 is unchanged.
- Gen I Summary/Pokédex model caches and adaptive preview cadence from 2.2.4 are unchanged.
- Gen I Pokédex routing from 2.2.3 is unchanged.
- Colosseum model -> selected custom sprite provider -> native sprite precedence from 2.2.2 remains unchanged.

## Static validation
- `main.lua` parsed successfully with `texluac -p`.
- `manifest.json` validated with Python JSON parser.
- Patch whitespace checked with `git diff --no-index --check`.
- Final archive verified with `unzip -t`.
