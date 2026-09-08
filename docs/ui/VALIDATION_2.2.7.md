# Validation — Colosseum Inspired UI Overhaul 2.2.7

## Baseline

- Built directly from packaged Colosseum Inspired UI Overhaul 2.2.6.
- UI-only package; CBE is not bundled or modified.

## Root causes confirmed from 2.2.6

- PASS — the Pokémon PC large inspector still called `drawCleanResolvedPortrait(..., "pc")`, which is intentionally a strict 2D-only helper.
- PASS — `cbeInformationModelService()` and `drawStadiumUiModel()` accepted only `summary` / `pokedex`, so a dedicated PC/evolution/hatch model slot could not work.
- PASS — the selected Pokémon PC row used the bright selected `drawPCGlassPanel()` outline while PC access/action rows still used the runoff selection wedge; this produced two inconsistent, oversized focus treatments.
- PASS — the PC inspector's STATS header began at `ly+81.5` while the fourth move row began at `ly+79`, causing direct fourth-move/STATS overlap at the shipped font metrics.

## CBE contract audit

- Verified against saved CBE 1.8.9 `audio-source-recovery.1` integration reference.
- CBE exports `informationModels.version = 3` and `resolveColosseum()`.
- `resolveColosseum()` calls CBE's information context, which checks `BattleSettings.pokemonModelsEnabled(game)` before returning `PokemonActors.service`.
- Therefore PC/evolution/hatch can explicitly request CBE 3D when the user's CBE Pokémon-model toggle is ON and fail open to UI 2D fallback when it is OFF.
- No CBE battle/world/camera APIs are called from these UI paths.

## 2.2.7 static assertions

- PASS — `pc`, `evolution`, and `hatch` are accepted information-model kinds.
- PASS — those three kinds use `bridge.resolveColosseum` instead of the generic selected-provider fallback.
- PASS — when the CBE information bridge is absent, these three kinds return to the UI's exact 2D resolver rather than selecting another installed 3D provider.
- PASS — Gen I PC list inspector, shared PC badge inspector, and Gen II Box inspector all call the provider-aware information portrait with model kind `pc`.
- PASS — evolution and revealed hatchling use dedicated model kinds `evolution` / `hatch`.
- PASS — PC actor LRU limit is 8, evolution working set is 2, hatch is 1; stale ownership releases each surface.
- PASS — PC selection geometry is contained inside fixed row/card bounds and no longer uses the 2.2.6 neon-green selected border or external arrow.
- PASS — four PC move rows use dedicated name/PP lanes and STATS begins below the fourth row.

## Regression / package checks

- `main.lua` parses successfully with `texluac -p`.
- `manifest.json` parses and reports version 2.2.7.
- Hook registrations remain 12 -> 12 relative to 2.2.6.
- Event registrations remain 6 -> 6 relative to 2.2.6.
- Direct `src.*` require-call count remains 69 -> 69 relative to 2.2.6.
- Before adding 2.2.7 release metadata, only `main.lua` and `manifest.json` differed from packaged 2.2.6.
- All 536 files under `assets/` are byte-identical to 2.2.6.
- `git diff --no-index --check` reports no whitespace errors in the 2.2.6 -> 2.2.7 `main.lua` delta.

## Highest-value live checks

1. Open PC ACCESS: selected BILL/CARL/OAK/TURN OFF row should use the contained focus rail, not an oversized runoff arrow/bar.
2. Deposit/withdraw Pokémon: selected row should remain the same size as neighboring rows and no neon-green outline should dominate the list.
3. Select a Pokémon with four moves: fourth move and PP must remain fully above STATS with no overlap.
4. CBE Pokémon models ON: large PC inspector must show the CBE 3D Colosseum model.
5. CBE Pokémon models OFF: same inspector must immediately fall back to the active Battle Arts/custom/default 2D sprite.
6. Evolve a Pokémon with CBE models ON: both old/new species presentation should be CBE 3D and swap without repeated cold model rebuilds.
7. Hatch an Egg with CBE models ON: shell remains an egg until reveal, then the hatchling is CBE 3D; repeat with models OFF for 2D fallback.
8. Recheck the trainer switch prompt fixed in 2.2.6 to ensure its Colosseum dialogue/YES-NO placement is unchanged.
