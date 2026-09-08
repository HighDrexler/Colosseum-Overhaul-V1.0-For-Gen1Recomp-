# Validation — Colosseum Inspired UI Overhaul 2.2.12

## Result

UI-only follow-up built from the shipped 2.2.11 tree. CBE/MoveFX/audio code is not part of this package.

## PC 3D viewer root cause

- 2.2.12 keeps the PC on the proven Pokédex information-model actor/render/input slot instead of a PC-specific 3D lifecycle.
- The stale-ownership sweep now treats every owned PC/storage state as ownership of that shared Pokédex actor slot.
- This closes the frame-order bug where `renderHudUnderlays()` ran `clearStaleOverworldOwnership()` before the PC portrait draw, released the shared actor, and forced the PC to reacquire a fresh actor later in the same frame.
- Because the actor is no longer reset every HUD frame, its source idle clock, orbit yaw/pitch, zoom, cached canvas, and pointer state can persist exactly as they do in the working Pokédex/Summary viewer.
- CBE-off/unavailable behavior remains a resolved 2D fallback.

## Battle move header geometry

- The selected Pokémon name in the 2x2 battle move console is no longer placed from a fixed `tabTop + 2u` baseline.
- The renderer measures the active font, fits long/large-profile names to the available tab width/height, then vertically centers the measured glyph line inside the authored header tab.

## Static/package checks

- `texluac -p main.lua`: PASS.
- `manifest.json`: valid JSON, version `2.2.12`, root entry `main.lua`.
- Targeted source assertions for shared PC ownership, shared Pokédex viewer call, and measured move-tab centering: PASS.
- Hook surface preserved from 2.2.11: 12 hook wraps -> 12.
- Event surface preserved from 2.2.11: 6 event registrations -> 6.
- Direct `src.*` require count preserved: 69 -> 69.
- Runtime asset inventory: 536/536 assets byte-identical to 2.2.11.
- Existing files intentionally changed from 2.2.11: `main.lua`, `manifest.json`; 2.2.12 release/validation notes are added/updated.

## Runtime boundary

This environment can validate Lua/package structure and the exact ownership/control-flow regression in source, but final visible animation, mouse/touch interaction, and font placement still require the normal Gen1Recomp/LÖVE runtime test.
