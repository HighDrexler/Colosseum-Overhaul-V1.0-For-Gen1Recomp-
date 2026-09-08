# Colosseum Inspired UI Overhaul 2.2.7

## PC selection cleanup

- Replaces the oversized/neon PC selection treatment introduced in 2.2.6 with a restrained inset teal focus treatment.
- Selected PC rows keep the same measured footprint as unselected rows; the indicator no longer expands into the outer gutter.
- The orange focus cue is now contained inside the row/card rather than protruding outside it.
- PC access, PC action, item confirmation, box/function lists, and Pokémon PC submenus use the same contained selection language.

## PC left-column reflow

- Gives all four move names their own dedicated vertical rows and keeps PP in a separate right-side lane.
- Moves the STATS section below the completed fourth move row instead of sharing the fourth move baseline.
- Keeps the existing selected Pokémon header, HP, portrait/model pod, and stat data while preventing `STATS` from colliding with long fourth moves such as FLAME WHEEL.

## CBE 3D model integration corrected

- Fixes the actual 2.2.6 integration gap: the Pokémon PC inspector was still calling the strict 2D portrait helper, and the information-model bridge rejected any model slot other than Summary/Pokédex.
- Adds dedicated `pc`, `evolution`, and `hatch` 3D information slots.
- These three surfaces explicitly request CBE's `informationModels.resolveColosseum()` path. CBE's own Pokémon-model toggle remains authoritative.
- With CBE Colosseum Pokémon models ON, the large selected Pokémon in the PC uses the real CBE 3D actor.
- With CBE models OFF, CBE unavailable, or the model unavailable, the same surfaces fall back to the exact active Battle Arts/custom/default 2D resolver.
- These CBE-specific surfaces do not silently substitute Stadium or another 3D provider when CBE models are off.

## Evolution and Egg hatch

- Evolution now owns a dedicated CBE model slot rather than borrowing the Summary slot.
- Old/new evolution species are cached as a two-actor working set so the transformation flash does not repeatedly destroy and reacquire the same actors.
- Egg hatch keeps the egg shell before reveal, then switches the revealed hatchling to the dedicated CBE 3D slot when CBE models are enabled.
- PC/evolution/hatch model actors are released when their UI ownership ends.

## Preserved fixes

- 2.2.6 battle switch-prompt dialogue/YES-NO correction remains intact.
- Elevator floor list, Mart TM/HM move-name display, Mart selection fitting, and prior Gen I/Gen II compositor fixes remain intact.
- CBE is optional and no CBE/ROM assets are bundled in this UI package.
