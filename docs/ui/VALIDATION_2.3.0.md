# Validation — Colosseum Inspired UI Overhaul 2.3.0

## Static/package checks performed
- PASS: `main.lua` compiles with LuaTeX's Lua parser (`loadfile`) without syntax errors.
- PASS: `manifest.json` parses successfully and reports version `2.3.0`.
- PASS: all 536 runtime assets are byte-identical to the supplied 2.2.13 baseline.
- PASS: all 562 pre-existing non-code/package files checked in the comparison are byte-identical to 2.2.13.
- PASS: no baseline files are missing and no unintended replacement files were introduced.
- PASS: package keeps `main.lua` and `manifest.json` at ZIP root.

## 2.3.0 regression targets
1. Gen I wild battle against a species already in `save.pokedex.owned`: caught Poké Ball marker appears on the enemy status card.
2. Gen I first-seen/unowned wild battle: no caught marker.
3. Gen I battle message whose extracted text ends in `{PROMPT}`: marker never renders as dialogue; normal wait/advance still works.
4. Gen I SHIFT battle choice and caught-mon nickname YES/NO: prompt text remains visible and no native box leaks through.
5. Strict Native UI Block ON with individual Save/Options/Mods/Trainer/Bag/Party/PC/Pokédex/dialogue/service toggles OFF: no native UI presentation reappears.
6. Strict Native UI Block OFF: individual toggles keep their existing independent behavior.
7. Gen II Party/PC/Pokédex and information-model viewers: persistent actors/cache reuse remains functional.
8. CBE/Battle Arts/Stadium/Shape providers: selected sprite/model source remains authoritative.

## Scope guard
No battle logic, catch odds, save mutation, storage behavior, TM/HM behavior, menu callbacks, encounter logic, or external presentation-provider arbitration was intentionally changed.
