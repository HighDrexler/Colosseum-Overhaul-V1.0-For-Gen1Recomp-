# Validation — Colosseum Inspired UI Overhaul 2.2.6

## Baseline
- Built directly from packaged Colosseum Inspired UI Overhaul 2.2.5.
- UI-only package; CBE is not bundled or modified.

## Reported regressions addressed
- PASS — Gen I battle ChoiceBox no longer routes through the fixed overworld YES/NO placement while a BattleState is active.
- PASS — battle switch-choice question is redrawn with the shared Colosseum dialogue renderer instead of the legacy white `drawDialogue` path when the shared renderer is available.
- PASS — Gen I and Gen II Mart root labels use measured/fitted text inside fixed selection rows.
- PASS — dedicated elevator renderer consumes `flow.floors`, `flow.floorNames`, `flow.origin`, `flow.index`, and `flow.scroll`; the generic `READY` fallback is bypassed for elevator flows.
- PASS — Gen I Mart TM/HM rows resolve `def.machine.move`; Gen II Mart rows resolve `def.teaches`; both retain the native item/price entries and only change presentation.
- PASS — Gen I Party left-column move area uses four dedicated measured rows with an independent PP lane.
- PASS — standard Gen I and Gen II Party selected portraits call the existing provider-aware `drawStatsInformationPortrait` path.
- PASS — evolution and hatchling-reveal rendering call the same provider-aware information portrait path; the unrevealed egg remains an egg shell.

## CBE/provider contract audit
- Verified against the saved CBE 1.8.9 source-recovery package used as the current integration reference.
- Its `informationModels` v3 `resolve` delegates to the selected-presentation provider; CBE's explicit Pokémon-model toggle wins when enabled, while a 2D selection returns no actor and therefore allows this UI to use its existing sprite fallback.
- UI changes do not call CBE battle/world/camera APIs and do not package any CBE or ROM-derived assets.

## Regression / package checks
- `main.lua` parses successfully with `texluac -p`.
- `manifest.json` parses successfully and reports version 2.2.6.
- `git diff --no-index --check` reports no whitespace errors for the 2.2.5 -> 2.2.6 code delta.
- All files inherited from 2.2.5 other than `main.lua` / `manifest.json` are byte-identical before adding 2.2.6 release/validation metadata.
- 2.2.5's 536 packaged runtime assets remain untouched.
- PASS — final ZIP contains `main.lua` and `manifest.json` directly at archive root.
- PASS — final ZIP contains 554 archive entries and passes `unzip -t` with no corrupt members.

## Live checks requested
1. Gen I trainer battle: trigger the opponent switch question; confirm the question is the dark Colosseum dialogue card and YES/NO sits above it without overlap.
2. Open a Poké Mart root menu under NORMAL/LARGE/X-LARGE text profiles; BUY/SELL/EXIT must stay inside the selection pill.
3. Open a Gen II elevator with several floors; verify the current floor and all scrollable destinations appear and selecting a floor still rides to the native destination.
4. Open a Mart selling TMs/HMs in either generation; verify each machine row shows its move and price without lane collision.
5. Open the standard Pokémon menu with four moves; verify no move-name/PP overprint in the left detail panel.
6. With CBE Colosseum Pokémon models ON, open Party, evolve a Pokémon, and hatch an Egg; the selected/revealed Pokémon should use CBE 3D. Repeat with CBE models OFF and verify exact active 2D sprite fallback.
