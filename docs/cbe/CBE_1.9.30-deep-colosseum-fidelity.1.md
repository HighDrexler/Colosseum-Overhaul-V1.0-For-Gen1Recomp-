# CBE 1.9.30-deep-colosseum-fidelity.1

## Scope

Targeted **Deep Colosseum** fidelity/presentation pass built directly on 1.9.29. No Pokemon animation, Relic, Outskirts, Pyrite, trainer, MoveFX, capture, audio or gameplay behavior is intentionally changed.

## Source-scene fidelity

- Deep remains bound to the retail `M4_bottom_colo.fsys` / `M4_bottom_colo.dat` battle scene.
- Canonical Deep extraction now enables the HSD render-pass contract (`honorRenderPass=true`) and skips shadow-only materials. This prevents dormant/helper carrier surfaces from becoming visible outer-chamber slabs.
- HSD traversal budgets increase to 460k vertices / 2.6m display operations / 64 scene roots so the complete source shell has substantially more room to survive extraction.
- Runtime retention grows from `8500 / 22000 / 8200` to `12000 / 32000 / 11500` (scene radius / max group span / vertex radius), preserving more rotor, pipe, wall, stand and masonry depth.

## Lighting / clarity

- Removes the old procedural `metalBreak` modulation and the stacked green/dark exposure pass.
- Source atlas color is now kept essentially neutral with only restrained source-compatible directional light and small contrast recovery.
- Deep distance fog begins at 620 world units instead of 360 and reaches full range at 1400 instead of 760; applied fog strength drops to 0.018.
- Fog/background color is near-neutral black, matching the source chamber's deep cavities rather than washing the outskirts green-grey.
- Screen-space fallback is reduced to a near-black enclosed chamber with only faint warm floor bounce. Visible perimeter detail is expected to come from the real HSD geometry.

## Composition

- Figure scale: `0.315 -> 0.300`.
- Trainer scale: player `0.385 -> 0.365`, enemy `0.188 -> 0.180`.
- Base camera height: `14.0 -> 12.2`; look height `5.8 -> 4.8`.
- High-angle motion is compressed further (`shotHeightScale 0.68 -> 0.60`, max pitch `17 -> 14`) so battle shots remain low and architectural like the source game.

## Migration

Arena identity marker changes only in the Deep contract. On a modern installation with all ten canonical arena caches present, the repair path rebuilds **Deep Colosseum only**, then refreshes/reuses existing format-6 runtime sidecars as appropriate. Global extractor revision remains 15, Pokemon extractor remains revision 36, and audio/trainer/MoveFX identities are untouched.
