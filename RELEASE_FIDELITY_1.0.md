# Colosseum Overhaul 1.0 — fidelity release

This build includes the earlier runtime cache and camera fixes, followed by a source-data and rendering audit of all eleven arenas, all ten trainer model members, shared Pokémon presentation, and move effects. The installation ID and release version remain `COLOSSEUM_OVERHAUL` / `1.0`.

## Install and cache behavior

Close the game and replace the previous combined package through the launcher. The ZIP contains `main.lua` and `manifest.json` at its root. Keep the existing source import and generated cache; do not delete them.

The first startup refreshes the ten retail arenas to apply corrected joint transforms, texture coordinates, and material metadata. The authored Wildlands arena and valid Pokémon, shiny, trainer, animation, MoveFX, and audio caches are retained. Interrupted arena work remains retryable. This is a startup migration, not a recurring battle loading screen.

If upgrading from the testable fidelity checkpoint supplied during this work, only Water and Deep require the final instance refresh when the venue cache is complete. The final build explicitly recognizes that checkpoint; it will not silently reuse its misplaced audience geometry.

The existing Reuse Cache, Quick Start / 30 New, and Full Catalog choices remain. Once gameplay has started, encounters and switches prepare missing exact models without opening the cache/model screen. A first-use buffering pause remains possible; a real model failure uses the existing compact retry/exit notice. No full catalog rebuild or audio rerender is required solely for this update.

## Presentation changes

### Relic Chamber and Relic Cave

Relic Chamber's main defect was geometric. Arena extraction omitted the native HSD joint scale compensation already used by trainer and Pokémon extraction. Nonuniform parent scales sheared branches, foliage, and terrain into enormous sheets. The previous workaround then removed 9,654 of 13,158 source vertices, including the forest backdrop, foliage, and background geometry.

The corrected build applies native scale compensation and retains all 67 source groups and 13,158 vertices. The source forest floor is visible again. The renderer no longer substitutes flat procedural ground, clones tree sectors, or discards this complete scene using whole-material bounding boxes. The same verified transform correction restores five branch groups in Relic Cave without changing its topology.

Relic's source vertex colors and material colors now follow the unlit source contract. Ambient color and successive procedural grades no longer darken or recolor prelit surfaces. Camera safety limits and the existing single/double battle positions are retained.

Orre's automatic camera stays inside the verified clear radius of its source rock perimeter. Its previous orbit could enter a rock and obscure the battlefield. The revised distance and radius limit preserve the source scenery; framing tests cover all four doubles actors, including large model heights.

### Arenas and spectators

- Native scene instances now use their referenced subtree and cancel the template's staging transform. This corrects floating/missing Water audience banks and two affected Deep instances. Water now submits all 197 authored spectator cards on their actual balconies, without guessed position offsets or hidden banks. The other eight retail scenes contain no such instances and retain their existing geometry.
- Spectator vertices stay at their authored positions. The old UV-driven sway moved the feet because retail audience cards do not use the assumed full-height UV interval. Source crowd geometry is no longer displaced by that synthetic animation.
- Desktop and mobile shader paths preserve source vertex RGB or constant material RGB, as selected by the material. They use consistent cutout coverage and avoid invented crowd brightness pulses.
- Texture caching separates images that need different clamp, repeat, or mirrored-repeat settings. Seventeen source images had conflicting sampler uses across four venues.
- Static source UV transforms are baked during arena extraction, including audience atlas offsets. Ordinary UV mapping is handled independently from reflection/projected mapping.
- Texture modulation and source blend/replace color operations retain their source metadata. Prelit retail scenery bypasses the additional procedural lighting/color grades. Authored Wildlands rendering keeps its existing treatment.
- Verified low ground-shadow geometry in Outskirts and Orre is retained, grounding props and columns. The exception is limited to those source venues and groups entirely within the audited ground-height band; raised compositing/helper surfaces retain their existing exclusions.

### Trainers, Pokémon, and move effects

- Red uses a neutral native idle pose for victory, replacing the unwanted raised-arm pose. Victory remains a terminal battle event; other trainer actions and other trainers' celebrations are retained. The fix works with existing trainer caches.
- Trainer shadow/helper passes explicitly reset material state, preventing the previous model's last material from contaminating their color or opacity.
- Trainer opaque/translucent submission uses a separate stable draw order. Source animation group indices and native frame bindings remain intact.
- Source unlit trainer materials and source texture wrapping are respected, including the verified old-cache Nascour texture case.
- Repeated idle requests preserve a Pokémon's current native idle phase. Damage-to-faint and damage-to-recall transitions retain the opening terminal-animation frame.
- Invalid loop-seam samples fall back safely to the base sample instead of introducing corrupt interpolation.
- Move-effect gradients can transition from a transparent primary color to a visible environment color. Textured Type 2 effect meshes retain decoded RGB animation keys.
- Trail ribbons reuse a bounded mesh buffer, clear stale draw ranges, and release replaced buffers.

These changes concern presentation and resource handling. Existing damage, targeting, switching, abilities, rewards, audio, settings, source model resolution, shiny selection, and save paths are not redesigned. The prior camera continuity and runtime cache fixes remain included.

## Validation and practical limits

Final checks: **118 top-level suites passed, zero failures** (including five native-engine suites with 2,437 checks). One historical three-producer compatibility fixture is unavailable. The arena shaders passed **14,270 real GPU checks**; all **40 source-cache/packed-cache image pairs are byte-identical**. Water's 197 spectator cards passed an independent source-transform comparison with 11,231 assertions and a separate support-surface check. Red's neutral-victory test covers 2,776 assertions, including native frame binding and held victory on both trainer sides.

Detailed automated results and a file-integrity audit are included under `validation/release_fidelity/`. Source geometry/material inspection used the supplied USA disc read-only. Arena screenshots were rendered by the actual LÖVE arena renderer in a controlled harness; they are not screenshots of a completed retail playthrough. Native-engine integration fixtures exercise the local engine checkout with isolated in-memory test state.

The visual comparison report supplied alongside the ZIP shows the previous cache/camera build and this build at matching azimuths. Orre also uses its corrected camera distance; other venues use matching poses. The scene captures intentionally omit battlers so that arena geometry and background detail can be inspected.

This build improves verified defects; it is not a claim of pixel-exact GameCube emulation. Full multi-texture TEV/light behavior, reflection/projection texture controllers, animated arena controllers, all source camera rails, and some Pokémon animated-normal behavior remain approximated. Android shaders were compiled and exercised on the installed desktop GPU, not on physical Android hardware. Exhaustive live single/double playtesting of every move, species, trainer, arena, and save state has not been performed.

Before publishing, perform a normal live play session covering a partial-cache encounter, switches, faint/recall, shiny models, spread and single-target moves, trainer send-outs, and Relic in both battle modes. This complements the automated and source-render checks; it does not require deleting the cache.

## Source basis

Source geometry, textures, material flags, and joint hierarchies were inspected directly from the user's disc. No disc image or newly extracted retail model, texture, or audio cache is included in the mod ZIP.

Native transform and material interpretation were cross-checked against the primary SysDolphin implementation: [`HSD_JObjMakeMatrix`](https://github.com/doldecomp/melee/blob/master/src/sysdolphin/baselib/jobj.c), [`HSD_MtxSRT`](https://github.com/doldecomp/melee/blob/master/src/sysdolphin/baselib/mtx.c), [`MObjMakeTExp`](https://github.com/doldecomp/melee/blob/master/src/sysdolphin/baselib/mobj.c), and texture matrix/color operations in [`tobj.c`](https://github.com/doldecomp/melee/blob/master/src/sysdolphin/baselib/tobj.c). These establish the shared HSD conventions used by the correction; they do not prove reproduction of every Colosseum-specific renderer behavior.
